// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
codeunit 82568 "ADLSE Gen 2 Util"
{
    Access = Internal;
    SingleInstance = true;

    var
        AcquireLeaseSuffixTxt: Label '?comp=lease', Locked = true;
        LeaseDurationSecsTxt: Label '60', Locked = true, Comment = 'This is the maximum duration for a lock on the blobs';
        AcquireLeaseTimeoutSecondsTxt: Label '180', Locked = true, Comment = 'The number of seconds to continuously try to acquire a lock on the blob. This must be more than the value specified for AcquireLeaseSleepSecondsTxt.';
        AcquireLeaseSleepSecondsTxt: Label '10', Locked = true, Comment = 'The number of seconds to sleep for before re-trying to acquire a lock on the blob. This must be less than the value specified for AcquireLeaseTimeoutSecondsTxt.';
        TimedOutWaitingForLockOnBlobErr: Label 'Timed out waiting to acquire lease on blob %1 after %2 seconds. %3', Comment = '%1: blob name, %2: total waiting time in seconds, %3: Http Response';
        CouldNotReleaseLockOnBlobErr: Label 'Could not release lock on blob %1. %2', Comment = '%1: blob name, %2: Http response.';

        CreateContainerSuffixTxt: Label '?restype=container', Locked = true;
        CoundNotCreateContainerErr: Label 'Could not create container %1. %2', Comment = '%1: container name; %2: error text';
        GetContainerMetadataSuffixTxt: Label '?restype=container&comp=metadata', Locked = true;

        PutBlockSuffixTxt: Label '?comp=block&blockid=%1', Locked = true, Comment = '%1 = the block id being added';
        PutLockListSuffixTxt: Label '?comp=blocklist', Locked = true;
        CouldNotAppendDataToBlobErr: Label 'Could not append data to %1. %2', Comment = '%1: blob path, %2: Http response.';
        CouldNotCommitBlocksToDataBlobErr: Label 'Could not commit blocks to %1. %2', Comment = '%1: Blob path, %2: Http Response';
        CouldNotCreateBlobErr: Label 'Could not create blob %1. %2', Comment = '%1: blob path, %2: error text';
        CouldNotReadDataInBlobErr: Label 'Could not read data on %1. %2', Comment = '%1: blob path, %2: Http respomse';
        CouldNotReadResponseHeaderErr: Label 'Could not read %1 from %2.', Comment = '%1: content header value , %2: blob path';
        LatestBlockTagTok: Label '<Latest>%1</Latest>', Comment = '%1: block ID', Locked = true;

    procedure ContainerExists(ContainerPath: Text; ADLSECredentials: Codeunit "ADLSE Credentials"): Boolean
    var
        ADLSEHttp: Codeunit "ADLSE Http";
        Response: Text;
    begin
        ADLSEHttp.SetMethod("ADLSE Http Method"::Get);
        ADLSEHttp.SetUrl(ContainerPath + GetContainerMetadataSuffixTxt);
        ADLSEHttp.SetAuthorizationCredentials(ADLSECredentials);
        exit(ADLSEHttp.InvokeRestApi(Response)); // no error
    end;

    procedure CreateContainer(ContainerPath: Text; ADLSECredentials: Codeunit "ADLSE Credentials")
    var
        ADLSEHttp: Codeunit "ADLSE Http";
        Response: Text;
    begin
        ADLSEHttp.SetMethod("ADLSE Http Method"::Put);
        ADLSEHttp.SetUrl(ContainerPath + CreateContainerSuffixTxt);
        ADLSEHttp.SetAuthorizationCredentials(ADLSECredentials);
        if not ADLSEHttp.InvokeRestApi(Response) then
            Error(CoundNotCreateContainerErr, ContainerPath, Response);
    end;

    procedure GetBlobContent(BlobPath: Text; ADLSECredentials: Codeunit "ADLSE Credentials"; var BlobExists: Boolean) Content: JsonObject
    var
        ADLSEHttp: Codeunit "ADLSE Http";
        ContentToken: JsonToken;
        IsHandled: Boolean;
        Response: Text;
        StatusCode: Integer;
    begin
        OnBeforeGetBlobContent(BlobPath, ADLSECredentials, BlobExists, Content, IsHandled);
        if IsHandled then
            exit(Content);

        ADLSEHttp.SetMethod("ADLSE Http Method"::Get);
        ADLSEHttp.SetUrl(BlobPath);
        ADLSEHttp.SetAuthorizationCredentials(ADLSECredentials);
        BlobExists := true;
        if ADLSEHttp.InvokeRestApi(Response, StatusCode) then begin
            if Response.Trim() <> '' then begin
                ContentToken.ReadFrom(Response);
                Content := ContentToken.AsObject();
            end;
            exit;
        end;

        BlobExists := StatusCode <> 404;

        if BlobExists then // real error
            Error(CouldNotReadDataInBlobErr, BlobPath, Response);
    end;

    procedure GetBlobContentLength(BlobPath: Text; ADLSECredentials: Codeunit "ADLSE Credentials") ContentLength: Integer
    var
        ADLSEHttp: Codeunit "ADLSE Http";
        Response: Text;
        StatusCode: Integer;
        ContentLengthList: List of [Text];
        IsHandled: Boolean;
        ContentLengthTok: Label 'Content-Length', Locked = true;
    begin
        OnBeforeGetBlobContentLength(BlobPath, ContentLength, IsHandled);
        if IsHandled then
            exit;

        ADLSEHttp.SetMethod("ADLSE Http Method"::Head);
        ADLSEHttp.SetUrl(BlobPath);
        ADLSEHttp.SetAuthorizationCredentials(ADLSECredentials);
        if not ADLSEHttp.InvokeRestApi(Response, StatusCode) then
            Error(CouldNotReadDataInBlobErr, BlobPath, Response);

        ContentLengthList := ADLSEHttp.GetResponseContentHeaderValue(ContentLengthTok);
        if ContentLengthList.Count() < 1 then
            Error(CouldNotReadResponseHeaderErr, ContentLengthTok, BlobPath);

        Evaluate(ContentLength, ContentLengthList.Get(1));
    end;

    procedure CreateOrUpdateJsonBlob(BlobPath: Text; ADLSECredentials: Codeunit "ADLSE Credentials"; LeaseID: Text; Body: JsonObject)
    var
        BodyAsText: Text;
    begin
        Body.WriteTo(BodyAsText);
        CreateBlockBlob(BlobPath, ADLSECredentials, LeaseID, BodyAsText, true);
    end;

    local procedure CreateBlockBlob(BlobPath: Text; ADLSECredentials: Codeunit "ADLSE Credentials"; LeaseID: Text; Body: Text; IsJson: Boolean)
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSEHttp: Codeunit "ADLSE Http";
        Response: Text;
        BlobPathOrg: Text;
        IsHandled: Boolean;
    begin
        OnBeforeCreateBlockBlob(BlobPath, LeaseID, Body, IsJson, IsHandled);
        if IsHandled then
            exit;

        ADLSEHttp.SetMethod("ADLSE Http Method"::Put);

        case ADLSESetup.GetStorageType() of
            ADLSESetup."Storage Type"::"Azure Data Lake":
                ADLSEHttp.SetUrl(BlobPath);
            ADLSESetup."Storage Type"::"Microsoft Fabric":
                begin
                    BlobPathOrg := BlobPath;
                    ADLSEHttp.SetUrl(BlobPath + '?resource=file');
                end;
        end;

        ADLSEHttp.SetAuthorizationCredentials(ADLSECredentials);
        ADLSEHttp.AddHeader('x-ms-blob-type', 'BlockBlob');
        if IsJson then begin
            ADLSEHttp.AddHeader('x-ms-blob-content-type', ADLSEHttp.GetContentTypeJson());
            ADLSEHttp.SetContentIsJson();
        end else
            ADLSEHttp.AddHeader('x-ms-blob-content-type', ADLSEHttp.GetContentTypeTextCsv());
        ADLSEHttp.SetBody(Body);
        if LeaseID <> '' then
            ADLSEHttp.AddHeader('x-ms-lease-id', LeaseID);
        if not ADLSEHttp.InvokeRestApi(Response) then
            Error(CouldNotCreateBlobErr, BlobPath, Response);

        //Upload Json for Microsoft Fabric
        if (ADLSESetup.GetStorageType() = ADLSESetup."Storage Type"::"Microsoft Fabric") and (IsJson) then
            AddBlockToDataBlob(BlobPathOrg, Body, 0, ADLSECredentials);
    end;

    procedure CreateDataBlob(BlobPath: Text; ADLSECredentials: Codeunit "ADLSE Credentials")
    begin
        CreateBlockBlob(BlobPath, ADLSECredentials, '', '', false);
    end;

    // Storage Type - Azure Data Lake Storage
    procedure AddBlockToDataBlob(BlobPath: Text; Body: Text; ADLSECredentials: Codeunit "ADLSE Credentials") BlockID: Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        ADLSEHttp: Codeunit "ADLSE Http";
        Response: Text;
        IsHandled: Boolean;
    begin
        OnBeforeAddBlockToDataBlob(BlobPath, Body, BlockID, IsHandled);
        if IsHandled then
            exit;

        ADLSEHttp.SetMethod("ADLSE Http Method"::Put);
        BlockID := Base64Convert.ToBase64(CreateGuid());
        ADLSEHttp.SetUrl(BlobPath + StrSubstNo(PutBlockSuffixTxt, BlockID));
        ADLSEHttp.SetAuthorizationCredentials(ADLSECredentials);
        ADLSEHttp.SetBody(Body);
        if not ADLSEHttp.InvokeRestApi(Response) then
            Error(CouldNotAppendDataToBlobErr, BlobPath, Response);
    end;

    // Storage Type - Microsoft Fabric
    procedure AddBlockToDataBlob(BlobPath: Text; Body: Text; Position: Integer; ADLSECredentials: Codeunit "ADLSE Credentials")
    var
        ADLSEHttp: Codeunit "ADLSE Http";
        Response: Text;
        IsHandled: Boolean;
    begin
        OnBeforeAddBlockToDataBlob(BlobPath, Body, Format(Position), IsHandled);
        if IsHandled then
            exit;

        ADLSEHttp.SetMethod("ADLSE Http Method"::Patch);
        ADLSEHttp.SetUrl(BlobPath + '?position=' + Format(Position) + '&action=append&flush=true');
        ADLSEHttp.SetAuthorizationCredentials(ADLSECredentials);
        ADLSEHttp.SetBody(Body);
        if not ADLSEHttp.InvokeRestApi(Response) then
            Error(CouldNotAppendDataToBlobErr, BlobPath, Response);
    end;

    procedure CommitAllBlocksOnDataBlob(BlobPath: Text; ADLSECredentials: Codeunit "ADLSE Credentials"; BlockIDList: List of [Text])
    var
        ADLSEHttp: Codeunit "ADLSE Http";
        Response: Text;
        Body: TextBuilder;
        BlockID: Text;
        IsHandled: Boolean;
    begin
        OnBeforeCommitAllBlocksOnDataBlob(BlobPath, BlockIDList, IsHandled);
        if IsHandled then
            exit;

        ADLSEHttp.SetMethod("ADLSE Http Method"::Put);
        ADLSEHttp.SetUrl(BlobPath + PutLockListSuffixTxt);
        ADLSEHttp.SetAuthorizationCredentials(ADLSECredentials);

        Body.Append('<?xml version="1.0" encoding="utf-8"?><BlockList>');
        foreach BlockID in BlockIDList do
            Body.Append(StrSubstNo(LatestBlockTagTok, BlockID));
        Body.Append('</BlockList>');

        ADLSEHttp.SetBody(Body.ToText());
        if not ADLSEHttp.InvokeRestApi(Response) then
            Error(CouldNotCommitBlocksToDataBlobErr, BlobPath, Response);
    end;

    procedure AcquireLease(BlobPath: Text; ADLSECredentials: Codeunit "ADLSE Credentials"; var BlobExists: Boolean) LeaseID: Text
    var
        ADLSEHttp: Codeunit "ADLSE Http";
        Response: Text;
        LeaseIdHeaderValues: List of [Text];
        MaxMillisecondsToWaitFor: Integer;
        SleepForMilliseconds: Integer;
        FirstAcquireRequestAt: DateTime;
        StatusCode: Integer;
    begin
        ADLSEHttp.SetMethod("ADLSE Http Method"::Put);
        ADLSEHttp.SetUrl(BlobPath + AcquireLeaseSuffixTxt);
        ADLSEHttp.SetAuthorizationCredentials(ADLSECredentials);
        ADLSEHttp.AddHeader('x-ms-lease-action', 'acquire');
        ADLSEHttp.AddHeader('x-ms-lease-duration', LeaseDurationSecsTxt);

        Evaluate(MaxMillisecondsToWaitFor, AcquireLeaseTimeoutSecondsTxt);
        MaxMillisecondsToWaitFor *= 1000;
        Evaluate(SleepForMilliseconds, AcquireLeaseSleepSecondsTxt);
        SleepForMilliseconds *= 1000;
        FirstAcquireRequestAt := CurrentDateTime();
        while CurrentDateTime() - FirstAcquireRequestAt < MaxMillisecondsToWaitFor do begin
            if ADLSEHttp.InvokeRestApi(Response, StatusCode) then begin
                LeaseIdHeaderValues := ADLSEHttp.GetResponseHeaderValue('x-ms-lease-id');
                LeaseIdHeaderValues.Get(1, LeaseID);
                BlobExists := true;
                exit;
            end else
                if StatusCode = 404 then
                    exit;
            Sleep(SleepForMilliseconds);
        end;
        Error(TimedOutWaitingForLockOnBlobErr, BlobPath, AcquireLeaseTimeoutSecondsTxt, Response);
    end;

    procedure ReleaseBlob(BlobPath: Text; ADLSECredentials: Codeunit "ADLSE Credentials"; LeaseID: Text)
    var
        ADLSEHttp: Codeunit "ADLSE Http";
        Response: Text;
    begin
        if LeaseID = '' then
            exit; // nothing has been leased
        ADLSEHttp.SetMethod("ADLSE Http Method"::Put);
        ADLSEHttp.SetUrl(BlobPath + AcquireLeaseSuffixTxt);
        ADLSEHttp.SetAuthorizationCredentials(ADLSECredentials);
        ADLSEHttp.AddHeader('x-ms-lease-action', 'release');
        ADLSEHttp.AddHeader('x-ms-lease-id', LeaseID);
        if not ADLSEHttp.InvokeRestApi(Response) then
            Error(CouldNotReleaseLockOnBlobErr, BlobPath, Response);
    end;

    procedure IsMaxBlobFileSize(DataBlobPath: Text; BlobContentLength: Integer; PayloadLength: Integer): Boolean
    var
        ADLSESetup: Record "ADLSE Setup";
        BlobTotalContentSize: BigInteger;
    begin
        if ADLSESetup.GetStorageType() <> ADLSESetup."Storage Type"::"Microsoft Fabric" then
            exit(false);

        // To prevent a overflow, use a BigInterger to calculate the total value
        BlobTotalContentSize := BlobContentLength;
        BlobTotalContentSize += PayloadLength;

        // Microsoft Fabric has a limit of 2 GB (2147483647) for a blob.
        if BlobTotalContentSize < 2147483647 then
            exit(false);

        exit(true);
    end;

    procedure RemoveDeltasFromDataLake(ADLSEntityName: Text; ADLSECredentials: Codeunit "ADLSE Credentials")
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSEHttp: Codeunit "ADLSE Http";
        Response: Text;
        Url: Text;
        ADLSEContainerUrlTxt: Label 'https://%1.dfs.core.windows.net/%2', Comment = '%1: Account name, %2: Container Name', Locked = true;
    begin
        // DELETE https://{accountName}.{dnsSuffix}/{filesystem}/{path}
        // https://learn.microsoft.com/en-us/rest/api/storageservices/datalakestoragegen2/path/delete?view=rest-storageservices-datalakestoragegen2-2019-12-12
        ADLSESetup.GetSingleton();
        Url := StrSubstNo(ADLSEContainerUrlTxt, ADLSESetup."Account Name", ADLSESetup.Container);
        Url += '/deltas/' + ADLSEntityName + '?recursive=true';

        ADLSEHttp.SetMethod("ADLSE Http Method"::Delete);
        ADLSEHttp.SetUrl(Url);
        ADLSEHttp.SetAuthorizationCredentials(ADLSECredentials);
        ADLSEHttp.InvokeRestApi(Response)
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetBlobContent(BlobPath: Text; ADLSECredentials: Codeunit "ADLSE Credentials"; var BlobExists: Boolean; var Content: JsonObject; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateBlockBlob(BlobPath: Text; LeaseID: Text; Body: Text; IsJson: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetBlobContentLength(BlobPath: Text; var ContentLength: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddBlockToDataBlob(BlobPath: Text; Body: Text; BlockIDorPosition: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCommitAllBlocksOnDataBlob(BlobPath: Text; BlockIDList: List of [Text]; var IsHandled: Boolean)
    begin
    end;
}