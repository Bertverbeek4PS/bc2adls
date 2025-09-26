// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
codeunit 82562 "ADLSE Communication"
{
    Access = Internal;

    var
        ADLSECredentials: Codeunit "ADLSE Credentials";
        TableID: Integer;
        FieldIdList: List of [Integer];
        DataBlobPath: Text;
        DataBlobBlockIDs: List of [Text];
        BlobContentLength: Integer;
        LastRecordOnPayloadTimeStamp: BigInteger;
        Payload: TextBuilder;
        LastFlushedTimeStamp: BigInteger;
        NumberOfFlushes: Integer;
        EntityName: Text;
        EntityJson: JsonObject;
        DefaultContainerName: Text;
        MaxSizeOfPayloadMiB: Integer;
        EmitTelemetry: Boolean;
        DeltaCdmManifestNameTxt: Label 'deltas.manifest.cdm.json', Locked = true;
        DataCdmManifestNameTxt: Label 'data.manifest.cdm.json', Locked = true;
        EntityManifestNameTemplateTxt: Label '%1.cdm.json', Locked = true, Comment = '%1 = Entity name';
        ContainerUrlTxt: Label 'https://%1.blob.core.windows.net/%2', Locked = true, Comment = '%1: Account name, %2: Container Name';
        CorpusJsonPathTxt: Label '/%1', Comment = '%1 = name of the blob', Locked = true;
        CannotAddedMoreBlocksErr: Label 'The number of blocks that can be added to the blob has reached its maximum limit.';
        SingleRecordTooLargeErr: Label 'A single record payload exceeded the max payload size. Please adjust the payload size or reduce the fields to be exported for the record.';
        DeltasFileCsvTok: Label '/deltas/%1/%2.csv', Comment = '%1: Entity, %2: File identifier guid', Locked = true;
        FileCsvTok: Label '/%1/%2.csv', Comment = '%1: Entity, %2: File identifier guid', Locked = true;
        ExportOfSchemaNotPerformendTxt: Label 'Please export the schema first before trying to export the data.';
        EntitySchemaChangedErr: Label 'The schema of the table %1 has changed. %2', Comment = '%1 = Entity name, %2 = NotAllowedOnSimultaneousExportTxt';
        CdmSchemaChangedErr: Label 'There may have been a change in the tables to export. %1', Comment = '%1 = NotAllowedOnSimultaneousExportTxt';
        MSFabricUrlTxt: Label 'https://onelake.dfs.fabric.microsoft.com/%1/%2.Lakehouse/Files', Locked = true, Comment = '%1: Workspace name, %2: Lakehouse Name';
        MSFabricUrlGuidTxt: Label 'https://onelake.dfs.fabric.microsoft.com/%1/%2/Files', Locked = true, Comment = '%1: Workspace name, %2: Lakehouse Name';
        ResetTableExportTxt: Label '/reset/%1.txt', Locked = true, Comment = '%1 = Table name';

    procedure SetupBlobStorage()
    var
        ADLSEGen2Util: Codeunit "ADLSE Gen 2 Util";
    begin
        ADLSECredentials.Init();

        if not ADLSEGen2Util.ContainerExists(GetBaseUrl(), ADLSECredentials) then
            ADLSEGen2Util.CreateContainer(GetBaseUrl(), ADLSECredentials);
    end;

    local procedure GetBaseUrl(): Text
    var
        ADLSESetup: Record "ADLSE Setup";
        ValidGuid: Guid;
    begin
        ADLSESetup.GetSingleton();
        case ADLSESetup.GetStorageType() of
            ADLSESetup."Storage Type"::"Azure Data Lake":
                begin
                    if DefaultContainerName = '' then
                        DefaultContainerName := ADLSESetup.Container;

                    exit(StrSubstNo(ContainerUrlTxt, ADLSESetup."Account Name", DefaultContainerName));
                end;
            ADLSESetup."Storage Type"::"Microsoft Fabric":
                if not Evaluate(ValidGuid, ADLSESetup.Lakehouse) then
                    exit(StrSubstNo(MSFabricUrlTxt, ADLSESetup.Workspace, ADLSESetup.Lakehouse))
                else
                    exit(StrSubstNo(MSFabricUrlGuidTxt, ADLSESetup.Workspace, ADLSESetup.Lakehouse));
            ADLSESetup."Storage Type"::"Open Mirroring":
                exit(ADLSESetup.LandingZone);
        end;
    end;

    procedure Init(TableIDValue: Integer; FieldIdListValue: List of [Integer]; LastFlushedTimeStampValue: BigInteger; EmitTelemetryValue: Boolean)
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSEUtil: Codeunit "ADLSE Util";
        ADLSEExecution: Codeunit "ADLSE Execution";
        CustomDimensions: Dictionary of [Text, Text];
    begin
        TableID := TableIDValue;
        FieldIdList := FieldIdListValue;

        ADLSECredentials.Init();
        EntityName := ADLSEUtil.GetDataLakeCompliantTableName(TableID);

        LastFlushedTimeStamp := LastFlushedTimeStampValue;
        ADLSESetup.GetSingleton();
        MaxSizeOfPayloadMiB := ADLSESetup.MaxPayloadSizeMiB;
        EmitTelemetry := EmitTelemetryValue;
        if EmitTelemetry then begin
            CustomDimensions.Add('Entity', EntityName);
            CustomDimensions.Add('Last flushed time stamp', Format(LastFlushedTimeStampValue));
            ADLSEExecution.Log('ADLSE-041', 'Initialized ADLSE Communication to write to the lake.', Verbosity::Verbose);
        end;
    end;

    procedure CheckEntity(CdmDataFormat: Enum "ADLSE CDM Format"; var EntityJsonNeedsUpdate: Boolean; var ManifestJsonsNeedsUpdate: Boolean; SchemaUpdate: Boolean)
    var
        ADLSECdmUtil: Codeunit "ADLSE CDM Util";
        ADLSEGen2Util: Codeunit "ADLSE Gen 2 Util";
        ADLSEExecution: Codeunit "ADLSE Execution";
        OldJson: JsonObject;
        NewJson: JsonObject;
        BlobExists: Boolean;
        BlobEntityPath: Text;
    begin
        // check entity
        EntityJson := ADLSECdmUtil.CreateEntityContent(TableID, FieldIdList);
        BlobEntityPath := StrSubstNo(CorpusJsonPathTxt, StrSubstNo(EntityManifestNameTemplateTxt, EntityName));
        OldJson := ADLSEGen2Util.GetBlobContent(GetBaseUrl() + BlobEntityPath, ADLSECredentials, BlobExists);
        if BlobExists and not SchemaUpdate then
            ADLSECdmUtil.CheckChangeInEntities(OldJson, EntityJson, EntityName);
        if not ADLSECdmUtil.CompareEntityJsons(OldJson, EntityJson) then begin
            if EmitTelemetry then
                ADLSEExecution.Log('ADLSE-028', GetLastErrorText() + GetLastErrorCallStack(), Verbosity::Warning);
            ClearLastError();

            EntityJsonNeedsUpdate := true;
            JsonsDifferent(OldJson, EntityJson); // to log the difference
        end;

        // check manifest. Assume that if the data manifest needs change, the delta manifest will also need be updated
        OldJson := ADLSEGen2Util.GetBlobContent(GetBaseUrl() + StrSubstNo(CorpusJsonPathTxt, DataCdmManifestNameTxt), ADLSECredentials, BlobExists);
        NewJson := ADLSECdmUtil.UpdateDefaultManifestContent(OldJson, TableID, 'data', CdmDataFormat);
        ManifestJsonsNeedsUpdate := JsonsDifferent(OldJson, NewJson);

        if not SchemaUpdate then begin
            if EntityJsonNeedsUpdate then
                Error(EntitySchemaChangedErr, EntityName, ExportOfSchemaNotPerformendTxt);
            if ManifestJsonsNeedsUpdate then
                Error(CdmSchemaChangedErr, ExportOfSchemaNotPerformendTxt);
        end;
    end;

    procedure CreateEntityContent()
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSECdmUtil: Codeunit "ADLSE CDM Util";
    begin
        ADLSESetup.GetSingleton();
        if ADLSESetup.GetStorageType() = ADLSESetup."Storage Type"::"Open Mirroring" then
            EntityJson := ADLSECdmUtil.CreateEntityContent(TableID)
        else
            EntityJson := ADLSECdmUtil.CreateEntityContent(TableID, FieldIdList);

    end;

    local procedure JsonsDifferent(Json1: JsonObject; Json2: JsonObject) Result: Boolean
    var
        ADLSEExecution: Codeunit "ADLSE Execution";
        CustomDimensions: Dictionary of [Text, Text];
        Content1: Text;
        Content2: Text;
    begin
        Json1.WriteTo(Content1);
        Json2.WriteTo(Content2);
        Result := Content1 <> Content2;
        if Result and EmitTelemetry then begin
            CustomDimensions.Add('Content1', Content1);
            CustomDimensions.Add('Content2', Content2);
            ADLSEExecution.Log('ADLSE-023', 'Jsons were found to be different.', Verbosity::Warning, CustomDimensions);
        end;
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Table", 'rm')]
    local procedure CreateDataBlob() Created: Boolean
    begin
        exit(CreateDataBlob(false));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Table", 'rm')]
    local procedure CreateDataBlob(CheckOnly: Boolean) Created: Boolean
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSETable: Record "ADLSE Table";
        ADLSEUtil: Codeunit "ADLSE Util";
        ADLSEGen2Util: Codeunit "ADLSE Gen 2 Util";
        ADLSEExecution: Codeunit "ADLSE Execution";
        CustomDimension: Dictionary of [Text, Text];
        FileIdentifer: Guid;
        FileIdentiferTxt: Text;
    begin
        if DataBlobPath <> '' then
            // Microsoft Fabric has a limit on the blob size. Create a new blob before reaching this limit
            if not ADLSEGen2Util.IsMaxBlobFileSize(DataBlobPath, BlobContentLength, Payload.Length()) then
                exit // no need to create a new blob
            else begin
                if EmitTelemetry then begin
                    Clear(CustomDimension);
                    CustomDimension.Add('Entity', EntityName);
                    CustomDimension.Add('DataBlobPath', DataBlobPath);
                    CustomDimension.Add('BlobContentLength', Format(BlobContentLength));
                    CustomDimension.Add('PayloadContentLength', Format(Payload.Length()));
                    ADLSEExecution.Log('ADLSE-030', 'Maximum blob size reached.', Verbosity::Normal, CustomDimension);
                end;
                Created := true;
                BlobContentLength := 0;
            end;

        if ADLSESetup.GetStorageType() <> ADLSESetup."Storage Type"::"Open Mirroring" then
            FileIdentifer := CreateGuid()
        else begin
            //https://learn.microsoft.com/en-us/fabric/database/mirrored-database/open-mirroring-landing-zone-format#data-file-and-format-in-the-landing-zone
            ADLSETable.Get(TableID);
            if ADLSETable.ExportFileNumber = 0 then begin
                ADLSETable.ExportFileNumber := 1;
                ADLSETable.Modify(true);
            end;
            FileIdentiferTxt := Format(ADLSETable.ExportFileNumber);
            FileIdentiferTxt := FileIdentiferTxt.PadLeft(20, '0');
        end;

        if ADLSESetup.GetStorageType() = ADLSESetup."Storage Type"::"Open Mirroring" then
            DataBlobPath := StrSubstNo(FileCsvTok, EntityName, FileIdentiferTxt)
        else
            DataBlobPath := StrSubstNo(DeltasFileCsvTok, EntityName, ADLSEUtil.ToText(FileIdentifer));

        if not CheckOnly then
            ADLSEGen2Util.CreateDataBlob(GetBaseUrl() + DataBlobPath, ADLSECredentials);
        Created := true;
        if not CheckOnly then
            if EmitTelemetry then begin
                Clear(CustomDimension);
                CustomDimension.Add('Entity', EntityName);
                CustomDimension.Add('DataBlobPath', DataBlobPath);
                ADLSEExecution.Log('ADLSE-012', 'Created new blob to hold the data to be exported', Verbosity::Normal, CustomDimension);
            end;
    end;

    [TryFunction]
    procedure TryCollectAndSendRecord(RecordRef: RecordRef; RecordTimeStamp: BigInteger; var LastTimestampExported: BigInteger; Deletes: Boolean)
    var
        ADLSESetup: Record "ADLSE Setup";
        DataBlobCreated: Boolean;
    begin
        ClearLastError();
        ADLSESetup.GetSingleton();
        DataBlobCreated := CreateDataBlob(ADLSESetup.GetStorageType() = ADLSESetup."Storage Type"::"Open Mirroring");
        LastTimestampExported := CollectAndSendRecord(RecordRef, RecordTimeStamp, DataBlobCreated, Deletes);
    end;

    local procedure CollectAndSendRecord(RecordRef: RecordRef; RecordTimeStamp: BigInteger; DataBlobCreated: Boolean; Deletes: Boolean) LastTimestampExported: BigInteger
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSEUtil: Codeunit "ADLSE Util";
        RecordPayLoad: Text;
    begin
        ADLSESetup.GetSingleton();
        if NumberOfFlushes = 50000 then // https://docs.microsoft.com/en-us/rest/api/storageservices/put-block#remarks
            Error(CannotAddedMoreBlocksErr);

        // Add headers into the existing Payload
        if (DataBlobCreated) and (Payload.Length() <> 0) then
            Payload.Insert(1, ADLSEUtil.CreateCsvHeader(RecordRef, FieldIdList));

        RecordPayLoad := ADLSEUtil.CreateCsvPayload(RecordRef, FieldIdList, Payload.Length() = 0, Deletes);
        // check if payload exceeds the limit
        if Payload.Length() + StrLen(RecordPayLoad) + 2 > MaxPayloadSize() then begin // the 2 is to account for new line characters
            if Payload.Length() = 0 then
                // the record alone exceeds the max payload size
                Error(SingleRecordTooLargeErr);
            FlushPayload();
            if ADLSESetup."Storage Type" = ADLSESetup."Storage Type"::"Open Mirroring" then
                UpdateInProgressTimeStampOnTable(RecordRef.Number, RecordTimeStamp, Deletes);
        end;
        LastTimestampExported := LastFlushedTimeStamp;

        Payload.Append(RecordPayLoad);
        LastRecordOnPayloadTimeStamp := RecordTimeStamp;
    end;

    [TryFunction]
    procedure TryFinish(var LastTimestampExported: BigInteger)
    begin
        ClearLastError();
        LastTimestampExported := Finish();
    end;

    local procedure Finish() LastTimestampExported: BigInteger
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        if ADLSESetup.GetStorageType() = ADLSESetup."Storage Type"::"Open Mirroring" then
            if DataBlobPath = '' then
                CreateDataBlob();
        FlushPayload();

        LastTimestampExported := LastFlushedTimeStamp;
    end;

    local procedure MaxPayloadSize(): Integer
    var
        MaxLimitForPutBlockCalls: Integer;
        MaxCapacityOfTextBuilder: Integer;
    begin
        MaxLimitForPutBlockCalls := MaxSizeOfPayloadMiB * 1024 * 1024;
        MaxCapacityOfTextBuilder := Payload.MaxCapacity();
        if MaxLimitForPutBlockCalls < MaxCapacityOfTextBuilder then
            exit(MaxLimitForPutBlockCalls);
        exit(MaxCapacityOfTextBuilder);
    end;

    local procedure FlushPayload()
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSETable: Record "ADLSE Table";
        ADLSEGen2Util: Codeunit "ADLSE Gen 2 Util";
        ADLSEExecution: Codeunit "ADLSE Execution";
        ADLSE: Codeunit ADLSE;
        CustomDimensions: Dictionary of [Text, Text];
        BlockID: Text;
    begin
        if Payload.Length() = 0 then
            exit;

        if EmitTelemetry then begin
            CustomDimensions.Add('Length of payload', Format(Payload.Length()));
            ADLSEExecution.Log('ADLSE-013', 'Flushing the payload', Verbosity::Normal, CustomDimensions);
        end;

        case ADLSESetup.GetStorageType() of
            ADLSESetup."Storage Type"::"Azure Data Lake":
                begin
                    BlockID := ADLSEGen2Util.AddBlockToDataBlob(GetBaseUrl() + DataBlobPath, Payload.ToText(), ADLSECredentials);
                    if EmitTelemetry then begin
                        Clear(CustomDimensions);
                        CustomDimensions.Add('Block ID', BlockID);
                        ADLSEExecution.Log('ADLSE-014', 'Block added to blob', Verbosity::Normal, CustomDimensions);
                    end;
                    DataBlobBlockIDs.Add(BlockID);
                    ADLSEGen2Util.CommitAllBlocksOnDataBlob(GetBaseUrl() + DataBlobPath, ADLSECredentials, DataBlobBlockIDs);

                    if EmitTelemetry then
                        ADLSEExecution.Log('ADLSE-015', 'Block committed', Verbosity::Normal);
                end;
            ADLSESetup."Storage Type"::"Microsoft Fabric", ADLSESetup."Storage Type"::"Open Mirroring":
                begin
                    if ADLSESetup.GetStorageType() = ADLSESetup."Storage Type"::"Open Mirroring" then begin
                        DataBlobPath := '';
                        CreateDataBlob();
                    end;
                    ADLSEGen2Util.AddBlockToDataBlob(GetBaseUrl() + DataBlobPath, Payload.ToText(), BlobContentLength, ADLSECredentials);
                    BlobContentLength := ADLSEGen2Util.GetBlobContentLength(GetBaseUrl() + DataBlobPath, ADLSECredentials);
                end;
        end;

        LastFlushedTimeStamp := LastRecordOnPayloadTimeStamp;
        Payload.Clear();
        LastRecordOnPayloadTimeStamp := 0;
        NumberOfFlushes += 1;

        // increase export file number of the table when open mirroring is used
        if (ADLSESetup.GetStorageType() = ADLSESetup."Storage Type"::"Open Mirroring") then
            IncreaseExportFileNumber(TableID);

        ADLSE.OnTableExported(TableID, LastFlushedTimeStamp);
        if EmitTelemetry then begin
            Clear(CustomDimensions);
            CustomDimensions.Add('Flushed count', Format(NumberOfFlushes));
            ADLSEExecution.Log('ADLSE-016', 'Flushed the payload', Verbosity::Normal, CustomDimensions);
        end;
    end;

    procedure UpdateCdmJsons(EntityJsonNeedsUpdate: Boolean; ManifestJsonsNeedsUpdate: Boolean)
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSEGen2Util: Codeunit "ADLSE Gen 2 Util";
        LeaseID: Text;
        BlobPath: Text;
        BlobExists: Boolean;
    begin
        ADLSESetup.ReadIsolation := IsolationLevel::UpdLock;
        ADLSESetup.GetSingleton();

        //TODO create open morroring specific code for this
        // update entity json
        if EntityJsonNeedsUpdate then begin
            if ADLSESetup."Storage Type" = ADLSESetup."Storage Type"::"Open Mirroring" then
                BlobPath := ADLSESetup.LandingZone + StrSubstNo(CorpusJsonPathTxt, EntityName) + StrSubstNo(CorpusJsonPathTxt, '_metadata.json')
            else
                BlobPath := GetBaseUrl() + StrSubstNo(CorpusJsonPathTxt, StrSubstNo(EntityManifestNameTemplateTxt, EntityName));
            if ADLSESetup.GetStorageType() = ADLSESetup."Storage Type"::"Azure Data Lake" then
                LeaseID := ADLSEGen2Util.AcquireLease(BlobPath, ADLSECredentials, BlobExists);

            ADLSEGen2Util.CreateOrUpdateJsonBlob(BlobPath, ADLSECredentials, LeaseID, EntityJson);

            if ADLSESetup.GetStorageType() = ADLSESetup."Storage Type"::"Azure Data Lake" then
                ADLSEGen2Util.ReleaseBlob(BlobPath, ADLSECredentials, LeaseID);
        end;

        // update manifest
        if ManifestJsonsNeedsUpdate then begin
            // Expected that multiple sessions that export data from different tables will be competing for writing to 
            // manifest. Semaphore applied.
            UpdateManifest(GetBaseUrl() + StrSubstNo(CorpusJsonPathTxt, DataCdmManifestNameTxt), 'data', ADLSESetup.DataFormat);

            UpdateManifest(GetBaseUrl() + StrSubstNo(CorpusJsonPathTxt, DeltaCdmManifestNameTxt), 'deltas', "ADLSE CDM Format"::Csv);
            Commit(); // to release the lock above
        end;
    end;

    local procedure UpdateManifest(BlobPath: Text; Folder: Text; ADLSECdmFormat: Enum "ADLSE CDM Format")
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSECdmUtil: Codeunit "ADLSE CDM Util";
        ADLSEGen2Util: Codeunit "ADLSE Gen 2 Util";
        ManifestJson: JsonObject;
        LeaseID: Text;
        BlobExists: Boolean;
    begin
        if ADLSESetup.GetStorageType() = ADLSESetup."Storage Type"::"Azure Data Lake" then
            LeaseID := ADLSEGen2Util.AcquireLease(BlobPath, ADLSECredentials, BlobExists);
        if BlobExists and (ADLSESetup.GetStorageType() = ADLSESetup."Storage Type"::"Azure Data Lake") then
            ManifestJson := ADLSEGen2Util.GetBlobContent(BlobPath, ADLSECredentials, BlobExists)
        else
            ManifestJson := ADLSEGen2Util.GetBlobContent(BlobPath, ADLSECredentials, BlobExists);

        ManifestJson := ADLSECdmUtil.UpdateDefaultManifestContent(ManifestJson, TableID, Folder, ADLSECdmFormat);
        ADLSEGen2Util.CreateOrUpdateJsonBlob(BlobPath, ADLSECredentials, LeaseID, ManifestJson);
        if ADLSESetup.GetStorageType() = ADLSESetup."Storage Type"::"Azure Data Lake" then
            ADLSEGen2Util.ReleaseBlob(BlobPath, ADLSECredentials, LeaseID);
    end;

    procedure ResetTableExport(ltableId: Integer)
    begin
        ResetTableExport(ltableId, false);
    end;

    procedure ResetTableExport(ltableId: Integer; AllCompanies: Boolean)
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSEUtil: Codeunit "ADLSE Util";
        ADLSEGen2Util: Codeunit "ADLSE Gen 2 Util";
        Body: JsonObject;
    begin
        ADLSESetup.GetSingleton();
        ADLSECredentials.Init();

        if not AllCompanies then
            if ADLSESetup."Export Company Database Tables" in ['', CompanyName()] then
                if not ADLSEUtil.IsTablePerCompany(ltableId) then
                    AllCompanies := true;

        case ADLSESetup."Storage Type" of
            "ADLSE Storage Type"::"Microsoft Fabric":
                ADLSEGen2Util.CreateOrUpdateJsonBlob(GetBaseUrl() + StrSubstNo(ResetTableExportTxt, ADLSEUtil.GetDataLakeCompliantTableName(ltableId)), ADLSECredentials, '', Body);
            "ADLSE Storage Type"::"Azure Data Lake":
                ADLSEGen2Util.RemoveDeltasFromDataLake(ADLSEUtil.GetDataLakeCompliantTableName(ltableId), ADLSECredentials, AllCompanies);
            "ADLSE Storage Type"::"Open Mirroring":
                ADLSEGen2Util.DropTableFromOpenMirroring(ADLSEUtil.GetDataLakeCompliantTableName(ltableId), ADLSECredentials, AllCompanies);
        end;
    end;

    local procedure UpdateInProgressTimeStampOnTable(TableIDToUpdate: Integer; Timestamp: BigInteger; Deletes: Boolean)
    var
        ADLSETable: Record "ADLSE Table";
        ADLSEExecute: Codeunit "ADLSE Execute";
    begin
        ADLSETable.Get(TableIDToUpdate);
        ADLSEExecute.UpdateInProgressTableTimestamp(ADLSETable, Timestamp, Deletes);
    end;
    local procedure IncreaseExportFileNumber(TableIdToUpdate: integer)
#if not CLEAN27
    var
        ADLSETable: Record "ADLSE Table";
    begin
        // commit in current session causes RecRef.Next() to request data rom SQL ignoring subset retrieved from FindSet() (???) - this causes drastic performance issues when dealing with big tables; file number increase is pushed to another session for that purpose.
        if not ADLSETable.CheckIfNeedToCommitExternally(TableIdToUpdate) then
            IncreaseExportFileNumber_InCurrSession(TableIdToUpdate)
        else
            IncreaseExportFileNumber_InBkgSession(TableIdToUpdate);
    end;

    procedure IncreaseExportFileNumber_InCurrSession(TableIdToUpdate: integer)
#endif
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSETable: Record "ADLSE Table";
    begin
        if (ADLSESetup.GetStorageType() = ADLSESetup."Storage Type"::"Open Mirroring") then begin
            ADLSETable.Get(TableIdToUpdate);
            ADLSETable.ExportFileNumber := ADLSETable.ExportFileNumber + 1;
            ADLSETable.Modify(true);
            Commit();
        end;
    end;

#if not CLEAN27
    local procedure IncreaseExportFileNumber_InBkgSession(TableIdToUpdate: integer)
    var
        SessionInstruction: Record "Session Instruction";
    begin
        SessionInstruction."Object Type" := SessionInstruction."Object Type"::Codeunit;
        SessionInstruction."Object ID" := Codeunit::"ADLSE Communication";
        SessionInstruction.Method := "ADLSE Session Method"::"Handle Export File Number Increase";
        SessionInstruction.Params := format(TableIdToUpdate);
        SessionInstruction.ExecuteInNewSession();
    end;
#endif
}
