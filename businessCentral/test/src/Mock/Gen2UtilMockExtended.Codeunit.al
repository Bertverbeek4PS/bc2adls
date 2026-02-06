codeunit 85568 "ADLSE Gen 2 Util Mock Extended"
{
    EventSubscriberInstance = Manual;

    var
        _blobExists: Boolean;
        _contents: Dictionary of [Text, Text];
        _body: Text;
        _simulateFailure: Boolean;
        _failureMessage: Text;
        _containerExists: Boolean;
        _containerCreated: Boolean;
        _blobContentLength: Integer;
        _leaseId: Text;
        _renamedBlobs: Dictionary of [Text, Text];
        _createdBlobs: List of [Text];
        _committedBlocks: List of [Text];

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ADLSE Gen 2 Util", OnBeforeGetBlobContent, '', false, false)]
    local procedure OnBeforeGetBlobContentOnGen2Util(BlobPath: Text; ADLSECredentials: Codeunit "ADLSE Credentials"; var BlobExists: Boolean; var Content: JsonObject; var IsHandled: Boolean)
    var
        StringifiedJson: Text;
    begin
        if _simulateFailure then
            Error(_failureMessage);

        BlobExists := _blobExists;
        if _contents.ContainsKey(BlobPath) then begin
            _contents.Get(BlobPath, StringifiedJson);
            Content.ReadFrom(StringifiedJson);
        end;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ADLSE Gen 2 Util", OnBeforeCreateBlockBlob, '', false, false)]
    local procedure OnBeforeCreateBlockBlobOnGen2Util(BlobPath: Text; LeaseID: Text; Body: Text; IsJson: Boolean; var IsHandled: Boolean)
    begin
        if _simulateFailure then
            Error(_failureMessage);

        _createdBlobs.Add(BlobPath);
        _containerCreated := true;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ADLSE Gen 2 Util", OnBeforeGetBlobContentLength, '', false, false)]
    local procedure OnBeforeGetBlobContentLengthOnGen2Util(BlobPath: Text; var ContentLength: Integer; var IsHandled: Boolean)
    begin
        ContentLength := _blobContentLength;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ADLSE Gen 2 Util", OnBeforeAddBlockToDataBlob, '', false, false)]
    local procedure OnBeforeAddBlockToDataBlobOnGen2Util(BlobPath: Text; Body: Text; BlockIDorPosition: Text; var IsHandled: Boolean)
    begin
        if _simulateFailure then
            Error(_failureMessage);

        _body := Body;
        _blobContentLength += StrLen(Body);
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ADLSE Gen 2 Util", OnBeforeCommitAllBlocksOnDataBlob, '', false, false)]
    local procedure OnBeforeCommitAllBlocksOnDataBlobOnGen2Util(BlobPath: Text; BlockIDList: List of [Text]; var IsHandled: Boolean)
    begin
        if _simulateFailure then
            Error(_failureMessage);

        _committedBlocks.Add(BlobPath);
        IsHandled := true;
    end;

    procedure GetBlobExists(): Boolean
    begin
        exit(_blobExists);
    end;

    procedure SetBlobExists(BlobExists: Boolean)
    begin
        _blobExists := BlobExists;
    end;

    procedure AddContent(BlobPath: Text; StringifiedJson: Text)
    begin
        _contents.Add(BlobPath, StringifiedJson);
    end;

    procedure GetBody(): Text
    begin
        exit(_body);
    end;

    procedure SetSimulateFailure(Failure: Boolean; Message: Text)
    begin
        _simulateFailure := Failure;
        _failureMessage := Message;
    end;

    procedure SetContainerExists(ContainerExists: Boolean)
    begin
        _containerExists := ContainerExists;
        if ContainerExists then
            _containerCreated := false;
    end;

    procedure GetContainerExists(): Boolean
    begin
        exit(_containerExists);
    end;

    procedure GetContainerCreated(): Boolean
    begin
        exit(_containerCreated and (not _containerExists));
    end;

    procedure SetBlobContentLength(ContentLength: Integer)
    begin
        _blobContentLength := ContentLength;
    end;

    procedure GetBlobContentLength(): Integer
    begin
        exit(_blobContentLength);
    end;

    procedure SetLeaseId(LeaseId: Text)
    begin
        _leaseId := LeaseId;
    end;

    procedure GetRenamedBlobs(): Dictionary of [Text, Text]
    begin
        exit(_renamedBlobs);
    end;

    procedure GetCreatedBlobs(): List of [Text]
    begin
        exit(_createdBlobs);
    end;

    procedure GetCommittedBlocks(): List of [Text]
    begin
        exit(_committedBlocks);
    end;

    procedure Reset()
    begin
        Clear(_blobExists);
        Clear(_contents);
        Clear(_body);
        Clear(_simulateFailure);
        Clear(_failureMessage);
        Clear(_containerExists);
        Clear(_containerCreated);
        Clear(_blobContentLength);
        Clear(_leaseId);
        Clear(_renamedBlobs);
        Clear(_createdBlobs);
        Clear(_committedBlocks);
    end;
}
