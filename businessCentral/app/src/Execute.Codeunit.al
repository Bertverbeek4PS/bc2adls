// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
codeunit 82561 "ADLSE Execute"
{
    Access = Internal;
    TableNo = "ADLSE Table";
    Permissions = tabledata "ADLSE Table" = rm;

    trigger OnRun()
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSERun: Record "ADLSE Run";
        ADLSETable: Record "ADLSE Table";
        ADLSECurrentSession: Record "ADLSE Current Session";
        ADLSETableLastTimestamp: Record "ADLSE Table Last Timestamp";
        ADLSECommunication: Codeunit "ADLSE Communication";
        ADLSEExecution: Codeunit "ADLSE Execution";
        ADLSEUtil: Codeunit "ADLSE Util";
        ADLSEExternalEvents: Codeunit "ADLSE External Events";
        CustomDimensions: Dictionary of [Text, Text];
        TableCaption: Text;
        UpdatedLastTimestamp: BigInteger;
        DeletedLastEntryNo: BigInteger;
        OldUpdatedLastTimestamp: BigInteger;
        OldDeletedLastEntryNo: BigInteger;
        EntityJsonNeedsUpdate: Boolean;
        ManifestJsonsNeedsUpdate: Boolean;
        ExportSuccess: Boolean;
    begin
        ADLSESetup.GetSingleton();
        EmitTelemetry := ADLSESetup."Emit telemetry";
        CDMDataFormat := ADLSESetup.DataFormat;

        if EmitTelemetry then begin
            TableCaption := ADLSEUtil.GetTableCaption(Rec."Table ID");
            CustomDimensions.Add('Entity', TableCaption);
            ADLSEExecution.Log('ADLSE-017', 'Starting the export for table', Verbosity::Normal, CustomDimensions);
        end;

        // Register session started
        ADLSECurrentSession.Start(Rec."Table ID");
        ADLSERun.RegisterStarted(Rec."Table ID");
        Commit(); // to release locks on the "ADLSE Current Session" record thus allowing other sessions to check for it being active when they are nearing the last step.
        if EmitTelemetry then
            ADLSEExecution.Log('ADLSE-018', 'Registered session to export table', Verbosity::Normal, CustomDimensions);

        UpdatedLastTimestamp := ADLSETableLastTimestamp.GetUpdatedLastTimestamp(Rec."Table ID");
        DeletedLastEntryNo := ADLSETableLastTimestamp.GetDeletedLastEntryNo(Rec."Table ID");

        if EmitTelemetry then begin
            CustomDimensions.Add('Old Updated Last time stamp', Format(UpdatedLastTimestamp));
            CustomDimensions.Add('Old Deleted Last entry no.', Format(DeletedLastEntryNo));
            ADLSEExecution.Log('ADLSE-004', 'Exporting with parameters', Verbosity::Normal, CustomDimensions);
        end;

        // Perform the export 
        OldUpdatedLastTimestamp := UpdatedLastTimestamp;
        OldDeletedLastEntryNo := DeletedLastEntryNo;
        ExportSuccess := TryExportTableData(Rec."Table ID", ADLSECommunication, UpdatedLastTimestamp, DeletedLastEntryNo, EntityJsonNeedsUpdate, ManifestJsonsNeedsUpdate);
        if not ExportSuccess then
            ADLSERun.RegisterErrorInProcess(Rec."Table ID", EmitTelemetry, TableCaption);

        if EmitTelemetry then begin
            Clear(CustomDimensions);
            CustomDimensions.Add('Entity', TableCaption);
            CustomDimensions.Add('Updated Last time stamp', Format(UpdatedLastTimestamp));
            CustomDimensions.Add('Deleted Last entry no.', Format(DeletedLastEntryNo));
            ADLSEExecution.Log('ADLSE-020', 'Exported to deltas CDM folder', Verbosity::Normal, CustomDimensions);
        end;

        // check if anything exported at all
        if (UpdatedLastTimestamp > OldUpdatedLastTimestamp) or (DeletedLastEntryNo > OldDeletedLastEntryNo) then begin
            // update the last timestamps of the record
            if not ADLSETableLastTimestamp.TrySaveUpdatedLastTimestamp(Rec."Table ID", UpdatedLastTimestamp, EmitTelemetry) then begin
                SetStateFinished(Rec, TableCaption);
                exit;
            end;
            if not ADLSETableLastTimestamp.TrySaveDeletedLastEntryNo(Rec."Table ID", DeletedLastEntryNo, EmitTelemetry) then begin
                SetStateFinished(Rec, TableCaption);
                exit;
            end;
            if EmitTelemetry then begin
                Clear(CustomDimensions);
                CustomDimensions.Add('Entity', TableCaption);
                ADLSEExecution.Log('ADLSE-006', 'Saved the timestamps into the database', Verbosity::Normal, CustomDimensions);
            end;
            Commit(); // to save the last time stamps into the database.
        end;

        // Finalize
        SetStateFinished(Rec, TableCaption);
        if EmitTelemetry then
            if ExportSuccess then
                ADLSEExecution.Log('ADLSE-005', 'Export completed without error', Verbosity::Normal, CustomDimensions)
            else
                ADLSEExecution.Log('ADLSE-040', 'Export completed with errors', Verbosity::Warning, CustomDimensions);
    end;

    var
        TimestampAscendingSortViewTxt: Label 'Sorting(Timestamp) Order(Ascending)', Locked = true;
        InsufficientReadPermErr: Label 'You do not have sufficient permissions to read from the table.';
        EmitTelemetry: Boolean;
        CDMDataFormat: Enum "ADLSE CDM Format";

    [TryFunction]
    local procedure TryExportTableData(TableID: Integer; var ADLSECommunication: Codeunit "ADLSE Communication";
        var UpdatedLastTimeStamp: BigInteger; var DeletedLastEntryNo: BigInteger;
        var EntityJsonNeedsUpdate: Boolean; var ManifestJsonsNeedsUpdate: Boolean)
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSECommunicationDeletions: Codeunit "ADLSE Communication";
        FieldIdList: List of [Integer];
        DidUpserts: Boolean;
    begin
        FieldIdList := CreateFieldListForTable(TableID);

        // first export the upserts
        ADLSECommunication.Init(TableID, FieldIdList, UpdatedLastTimeStamp, EmitTelemetry);

        if ADLSESetup.GetStorageType() <> ADLSESetup."Storage Type"::"Open Mirroring" then //TODO is this really needed for open mirroring?
            ADLSECommunication.CheckEntity(CDMDataFormat, EntityJsonNeedsUpdate, ManifestJsonsNeedsUpdate, false);

        ExportTableUpdates(TableID, FieldIdList, ADLSECommunication, UpdatedLastTimeStamp, DidUpserts);

        // then export the deletes
        ADLSECommunicationDeletions.Init(TableID, FieldIdList, DeletedLastEntryNo, EmitTelemetry);
        // entity has been already checked above
        ExportTableDeletes(TableID, ADLSECommunicationDeletions, DeletedLastEntryNo, DidUpserts);
    end;

    procedure UpdatedRecordsExist(TableID: Integer; UpdatedLastTimeStamp: BigInteger): Boolean
    var
        ADLSESeekData: Report "ADLSE Seek Data";
        RecordRef: RecordRef;
        TimeStampFieldRef: FieldRef;
    begin
        SetFilterForUpdates(TableID, UpdatedLastTimeStamp, false, RecordRef, TimeStampFieldRef);
        exit(ADLSESeekData.RecordsExist(RecordRef));
    end;

    local procedure SetFilterForUpdates(TableID: Integer; UpdatedLastTimeStamp: BigInteger; SkipTimestampSorting: Boolean; var RecordRef: RecordRef; var TimeStampFieldRef: FieldRef)
    var
        ADLSELastTimestamp: Record "ADLSE Table Last Timestamp";
#if not CLEAN27
        ADLSETable: Record "ADLSE Table";
#endif
    begin
        RecordRef.Open(TableID);
#if not CLEAN27
        if not ADLSETable.CheckIfNeedToIgnoreReadIsolation(TableID) then
#endif
            RecordRef.ReadIsolation := RecordRef.ReadIsolation::ReadCommitted;
        if not SkipTimestampSorting then
            RecordRef.SetView(TimestampAscendingSortViewTxt);
        TimeStampFieldRef := RecordRef.Field(0); // 0 is the TimeStamp field
        TimeStampFieldRef.SetFilter('>%1', UpdatedLastTimeStamp);
    end;

    local procedure ExportTableUpdates(TableID: Integer; FieldIdList: List of [Integer]; ADLSECommunication: Codeunit "ADLSE Communication"; var UpdatedLastTimeStamp: BigInteger; var DidUpserts: Boolean)
    var
        ADLSESetup: Record "ADLSE Setup";
#if not CLEAN27
        ADLSETable: Record "ADLSE Table";
#endif
        ADLSESeekData: Report "ADLSE Seek Data";
        ADLSEExecution: Codeunit "ADLSE Execution";
        ADLSEUtil: Codeunit "ADLSE Util";
        RecordRef: RecordRef;
        TimeStampFieldRef: FieldRef;
        FieldRef: FieldRef;
        CustomDimensions: Dictionary of [Text, Text];
        TableCaption: Text;
        EntityCount: Text;
        FlushedTimeStamp: BigInteger;
        FieldId: Integer;
        SystemCreatedAt, UtcEpochZero : DateTime;
        ErrorMessage: ErrorInfo;
        CurrentDateTime: DateTime;
        RecordModifiedAt: DateTime;
        CollectedAndSent: Boolean;
        NoMoreToCollect: Boolean;
    begin
        ADLSESetup.GetSingleton();

        // Set CutoffTimeStamp to current time minus ADLSESeetup."Delayed Export"
        CurrentDateTime := CurrentDateTime();

        SetFilterForUpdates(TableID, UpdatedLastTimeStamp, ADLSESetup."Skip Timestamp Sorting On Recs", RecordRef, TimeStampFieldRef);

        foreach FieldId in FieldIdList do
            if RecordRef.FieldExist(FieldId) then
                if RecordRef.AddLoadFields(FieldId) then; // ignore the return value

        if not RecordRef.ReadPermission() then
            Error(InsufficientReadPermErr);

#if not CLEAN27
        if not ADLSETable.CheckIfNeedToIgnoreReadIsolation(TableID) then
#endif
            RecordRef.ReadIsolation := RecordRef.ReadIsolation::ReadCommitted;
        if ADLSESeekData.FindRecords(RecordRef) then begin
            DidUpserts := true;
            if EmitTelemetry then begin
                TableCaption := RecordRef.Caption();
                EntityCount := Format(RecordRef.Count());
                CustomDimensions.Add('Entity', TableCaption);
                CustomDimensions.Add('Entity Count', EntityCount);
                ADLSEExecution.Log('ADLSE-021', 'Updated records found', Verbosity::Normal, CustomDimensions);
            end;

            // This represent (Unix) Epoch with appending the Timezone Offset, so when converting this to UTC it wil be exactly 01 Jan 1900
            UtcEpochZero := ADLSEUtil.GetUtcEpochWithTimezoneOffset();

            repeat
                // Records created before SystemCreatedAt field was introduced, have null values. Initialize with 01 Jan 1900
                FieldRef := RecordRef.Field(RecordRef.SystemCreatedAtNo());
                SystemCreatedAt := FieldRef.Value();
                if SystemCreatedAt = 0DT then
                    FieldRef.Value(UtcEpochZero);

                FieldRef := RecordRef.Field(RecordRef.SystemModifiedAtNo());
                RecordModifiedAt := FieldRef.Value();
                if RecordModifiedAt = 0DT then
                    RecordModifiedAt := UtcEpochZero;

                if ((ADLSESetup."Delayed Export" = 0) or (CurrentDateTime - RecordModifiedAt > (ADLSESetup."Delayed Export" * 1000))) then begin

                    CollectedAndSent := ADLSECommunication.TryCollectAndSendRecord(RecordRef, TimeStampFieldRef.Value(), FlushedTimeStamp, false);
                    if CollectedAndSent then begin
                        if UpdatedLastTimeStamp < FlushedTimeStamp then // sample the highest timestamp, to cater to the eventuality that the records do not appear sorted per timestamp
                            UpdatedLastTimeStamp := FlushedTimeStamp;
                    end else
                        ErrorMessage.Message := StrSubstNo('%1%2', GetLastErrorText(), GetLastErrorCallStack());
                end else
                    if EmitTelemetry then begin
                        CustomDimensions.Set('Record Time Stamp', Format(RecordModifiedAt));
                        ADLSEExecution.Log('ADLSE-023', 'Skipping record in delay window', Verbosity::Normal, CustomDimensions);
                    end;

                if CollectedAndSent then
                    NoMoreToCollect := RecordRef.Next() = 0;
            until (not CollectedAndSent or NoMoreToCollect);

            if ErrorMessage.Message <> '' then
                Error(ErrorMessage);
            if ADLSECommunication.TryFinish(FlushedTimeStamp) then begin
                if UpdatedLastTimeStamp < FlushedTimeStamp then // sample the highest timestamp, to cater to the eventuality that the records do not appear sorted per timestamp
                    UpdatedLastTimeStamp := FlushedTimeStamp
            end else
                ErrorMessage.Message := StrSubstNo('%1%2', GetLastErrorText(), GetLastErrorCallStack());
            if ErrorMessage.Message <> '' then
                Error(ErrorMessage);
        end;
        if EmitTelemetry then
            ADLSEExecution.Log('ADLSE-009', 'Updated records exported', Verbosity::Normal);
    end;

    procedure DeletedRecordsExist(TableID: Integer; DeletedLastEntryNo: BigInteger): Boolean
    var
        ADLSEDeletedRecord: Record "ADLSE Deleted Record";
        ADLSESeekData: Report "ADLSE Seek Data";
    begin
        SetFilterForDeletes(TableID, DeletedLastEntryNo, ADLSEDeletedRecord);
        exit(ADLSESeekData.RecordsExist(ADLSEDeletedRecord));
    end;

    local procedure SetFilterForDeletes(TableID: Integer; DeletedLastEntryNo: BigInteger; var ADLSEDeletedRecord: Record "ADLSE Deleted Record")
    begin
        ADLSEDeletedRecord.ReadIsolation := ADLSEDeletedRecord.ReadIsolation::ReadCommitted;
        ADLSEDeletedRecord.SetView(TimestampAscendingSortViewTxt);
        ADLSEDeletedRecord.SetRange("Table ID", TableID);
        ADLSEDeletedRecord.SetFilter("Entry No.", '>%1', DeletedLastEntryNo);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Deleted Record", 'r')]
    local procedure ExportTableDeletes(TableID: Integer; ADLSECommunication: Codeunit "ADLSE Communication"; var DeletedLastEntryNo: BigInteger; DidUpserts: Boolean)
    var
        ADLSEDeletedRecord: Record "ADLSE Deleted Record";
        ADLSESetup: Record "ADLSE Setup";
        ADLSETable: Record "ADLSE Table";
        ADLSESeekData: Report "ADLSE Seek Data";
        ADLSEUtil: Codeunit "ADLSE Util";
        ADLSEExecution: Codeunit "ADLSE Execution";
        RecordRef: RecordRef;
        CustomDimensions: Dictionary of [Text, Text];
        TableCaption: Text;
        EntityCount: Text;
        FlushedTimeStamp: BigInteger;
        ErrorMessage: ErrorInfo;
        CurrentDateTime: DateTime;
    begin
        ADLSESetup.GetSingleton();
        CurrentDateTime := CurrentDateTime();
        SetFilterForDeletes(TableID, DeletedLastEntryNo, ADLSEDeletedRecord);

        ADLSEDeletedRecord.ReadIsolation := ADLSEDeletedRecord.ReadIsolation::ReadCommitted;
        if ADLSESeekData.FindRecords(ADLSEDeletedRecord) then begin
            //Addin the number when open mirroring is used
            if DidUpserts then
                if (ADLSESetup."Storage Type" = ADLSESetup."Storage Type"::"Open Mirroring") then begin
                    ADLSETable.Get(TableID);
                    ADLSETable.ExportFileNumber := ADLSETable.ExportFileNumber + 1;
                    ADLSETable.Modify(true);
                end;
            RecordRef.Open(ADLSEDeletedRecord."Table ID");

            FixDeletedRecordThatAreInTable(ADLSEDeletedRecord);

            if EmitTelemetry then begin
                TableCaption := RecordRef.Caption();
                EntityCount := Format(ADLSEDeletedRecord.Count());
                CustomDimensions.Add('Entity', TableCaption);
                CustomDimensions.Add('Entity Count', EntityCount);
                ADLSEExecution.Log('ADLSE-010', 'Deleted records found', Verbosity::Normal, CustomDimensions);
            end;

            if ADLSEDeletedRecord.FindSet() then
                repeat
                    if ((ADLSESetup."Delayed Export" = 0) or (CurrentDateTime - ADLSEDeletedRecord.SystemCreatedAt > (ADLSESetup."Delayed Export" * 1000))) then begin
                        ADLSEUtil.CreateFakeRecordForDeletedAction(ADLSEDeletedRecord, RecordRef);
                        if ADLSECommunication.TryCollectAndSendRecord(RecordRef, ADLSEDeletedRecord."Entry No.", FlushedTimeStamp, true) then
                            DeletedLastEntryNo := FlushedTimeStamp
                        else
                            ErrorMessage.Message := StrSubstNo('%1%2', GetLastErrorText(), GetLastErrorCallStack());
                    end;
                until ADLSEDeletedRecord.Next() = 0;

            if ADLSECommunication.TryFinish(FlushedTimeStamp) then
                DeletedLastEntryNo := FlushedTimeStamp
            else
                ErrorMessage.Message := StrSubstNo('%1%2', GetLastErrorText(), GetLastErrorCallStack());
        end;
        if EmitTelemetry then
            ADLSEExecution.Log('ADLSE-011', 'Deleted records exported', Verbosity::Normal, CustomDimensions);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Deleted Record", 'rd')]
    procedure FixDeletedRecordThatAreInTable(var ADLSEDeletedRecord: Record "ADLSE Deleted Record")
    var
        RecordRef: RecordRef;
    begin
        //Because of the merge function of Contact, Vendor and customer
        if ADLSEDeletedRecord.FindSet() then
            repeat
                case ADLSEDeletedRecord."Table ID" of
                    18, 23, 5050:
                        begin
                            RecordRef.Open(ADLSEDeletedRecord."Table ID");
                            if RecordRef.GetBySystemId(ADLSEDeletedRecord."System ID") then
                                ADLSEDeletedRecord.Delete(false);
                            RecordRef.Close();
                        end;
                end;
            until ADLSEDeletedRecord.Next() = 0;
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Field", 'r')]
    procedure CreateFieldListForTable(TableID: Integer) FieldIdList: List of [Integer]
    var
        ADLSEField: Record "ADLSE Field";
        ADLSEUtil: Codeunit "ADLSE Util";
    begin
        ADLSEField.SetRange("Table ID", TableID);
        ADLSEField.SetRange(Enabled, true);
        if ADLSEField.FindSet() then
            repeat
                FieldIdList.Add(ADLSEField."Field ID");
            until ADLSEField.Next() = 0;
        ADLSEUtil.AddSystemFields(FieldIdList);
    end;

    local procedure SetStateFinished(var ADLSETable: Record "ADLSE Table"; TableCaption: Text)
    var
        ADLSERun: Record "ADLSE Run";
        ADLSECurrentSession: Record "ADLSE Current Session";
        ADLSESetupRec: Record "ADLSE Setup";
        ADLSESessionManager: Codeunit "ADLSE Session Manager";
        ADLSEExecution: Codeunit "ADLSE Execution";
        ADLSEExternalEvents: Codeunit "ADLSE External Events";
        CustomDimensions: Dictionary of [Text, Text];
    begin
        ADLSERun.RegisterEnded(ADLSETable."Table ID", EmitTelemetry, TableCaption);
        ADLSECurrentSession.Stop(ADLSETable."Table ID", EmitTelemetry, TableCaption);
        if EmitTelemetry then begin
            CustomDimensions.Add('Entity', TableCaption);
            ADLSEExecution.Log('ADLSE-037', 'Finished the export process', Verbosity::Normal, CustomDimensions);
        end;
        Commit(); //To avoid misreading

        // This export session is soon going to end. Start up a new one from 
        // the stored list of pending tables to export.
        // Note that initially as many export sessions, as is allowed per the 
        // operation limits, are spawned up. The following line continously 
        // add to the number of sessions by consuming the pending backlog, thus
        // prolonging the time to finish an export batch. If this is a concern, 
        // consider commenting out the line below so no futher sessions are 
        // spawned when the active ones end. This may result in some table 
        // exports being skipped. But they may become active in the next export 
        // batch. 
        ADLSESessionManager.StartExportFromPendingTables();



        if not ADLSECurrentSession.AreAnySessionsActive() then begin
            ADLSESetupRec.GetSingleton();
            ADLSEExternalEvents.OnExportFinished(ADLSESetupRec, ADLSETable);

            if EmitTelemetry then
                ADLSEExecution.Log('ADLSE-041', 'All exports are finished', Verbosity::Normal);
        end;
    end;

    procedure UpdateInProgressTableTimestamp(var Rec: Record "ADLSE Table"; LastTimestamp: BigInteger; Deletes: Boolean)
    var
        ADLSETableLastTimestamp: Record "ADLSE Table Last Timestamp";
#if not CLEAN27
        ADLSETable: Record "ADLSE Table";
#endif
        ADLSEExecution: Codeunit "ADLSE Execution";
        ADLSEUtil: Codeunit "ADLSE Util";
        CustomDimensions: Dictionary of [Text, Text];
        TableCaption: Text;
        TimestampUpdated: Boolean;
    begin
        if EmitTelemetry then
            TableCaption := ADLSEUtil.GetTableCaption(Rec."Table ID");

        if not Deletes then begin
            TimestampUpdated := LastTimestamp > ADLSETableLastTimestamp.GetUpdatedLastTimestamp(Rec."Table ID");
            if TimestampUpdated then
                if not ADLSETableLastTimestamp.TrySaveUpdatedLastTimestamp(Rec."Table ID", LastTimestamp, EmitTelemetry) then begin
                    SetStateFinished(Rec, TableCaption);
                    exit;
                end;
        end else begin
            TimestampUpdated := LastTimestamp > ADLSETableLastTimestamp.GetDeletedLastEntryNo(Rec."Table ID");
            if TimestampUpdated then
                if not ADLSETableLastTimestamp.TrySaveDeletedLastEntryNo(Rec."Table ID", LastTimestamp, EmitTelemetry) then begin
                    SetStateFinished(Rec, TableCaption);
                    exit;
                end;
        end;

        if TimestampUpdated then
            if EmitTelemetry then begin
                Clear(CustomDimensions);
                CustomDimensions.Add('Entity', TableCaption);
                ADLSEExecution.Log('ADLSE-006', 'Saved the timestamps into the database', Verbosity::Normal, CustomDimensions);
            end;
#if not CLEAN27
        if not ADLSETable.CheckIfNeedToCommitExternally(Rec."Table ID") then
#endif
            Commit(); // to save the last time stamps into the database.
    end;

    procedure ExportSchema(tableId: Integer)
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSETableLastTimestamp: Record "ADLSE Table Last Timestamp";
        ADLSECommunication: Codeunit "ADLSE Communication";
        ADLSEExecution: Codeunit "ADLSE Execution";
        ADLSEUtil: Codeunit "ADLSE Util";
        TableCaption: Text;
        UpdatedLastTimestamp: BigInteger;
        CustomDimensions: Dictionary of [Text, Text];
        FieldIdList: List of [Integer];
        EntityJsonNeedsUpdate: Boolean;
        ManifestJsonsNeedsUpdate: Boolean;
    begin
        ADLSESetup.GetSingleton();
        EmitTelemetry := ADLSESetup."Emit telemetry";
        CDMDataFormat := ADLSESetup.DataFormat;
        UpdatedLastTimestamp := ADLSETableLastTimestamp.GetUpdatedLastTimestamp(tableId);
        FieldIdList := CreateFieldListForTable(tableId);

        ADLSECommunication.Init(tableId, FieldIdList, UpdatedLastTimestamp, EmitTelemetry);

        if ADLSESetup."Storage Type" <> ADLSESetup."Storage Type"::"Open Mirroring" then //Always export the schema for Open Mirroring
            ADLSECommunication.CheckEntity(CDMDataFormat, EntityJsonNeedsUpdate, ManifestJsonsNeedsUpdate, true)
        else begin
            ManifestJsonsNeedsUpdate := false;
            EntityJsonNeedsUpdate := true;
        end;

        if EmitTelemetry then begin
            Clear(CustomDimensions);
            TableCaption := ADLSEUtil.GetTableCaption(tableId);
            CustomDimensions.Add('Entity', TableCaption);
            CustomDimensions.Add('Updated Last time stamp', Format(UpdatedLastTimestamp));
            CustomDimensions.Add('Entity Json needs update', Format(EntityJsonNeedsUpdate));
            CustomDimensions.Add('Manifest Json needs update', Format(ManifestJsonsNeedsUpdate));
            ADLSEExecution.Log('ADLSE-038', 'Schema exported', Verbosity::Normal, CustomDimensions);
        end;

        ADLSECommunication.CreateEntityContent();
        ADLSECommunication.UpdateCdmJsons(EntityJsonNeedsUpdate, ManifestJsonsNeedsUpdate);
    end;

}