// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
codeunit 82561 "ADLSE Execute"
{
    Access = Internal;
    TableNo = "ADLSE Table";

    trigger OnRun()
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSERun: Record "ADLSE Run";
        ADLSECurrentSession: Record "ADLSE Current Session";
        ADLSETableLastTimestamp: Record "ADLSE Table Last Timestamp";
        ADLSECommunication: Codeunit "ADLSE Communication";
        ADLSEExecution: Codeunit "ADLSE Execution";
        ADLSEUtil: Codeunit "ADLSE Util";
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
            CustomDimensions.Add('Entity Json needs update', Format(EntityJsonNeedsUpdate));
            CustomDimensions.Add('Manifest Json needs update', Format(ManifestJsonsNeedsUpdate));
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

        // update Jsons
        ADLSECommunication.UpdateCdmJsons(EntityJsonNeedsUpdate, ManifestJsonsNeedsUpdate);
        if EmitTelemetry then
            ADLSEExecution.Log('ADLSE-007', 'Jsons have been updated', Verbosity::Normal, CustomDimensions);

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
        ADLSECommunicationDeletions: Codeunit "ADLSE Communication";
        FieldIdList: List of [Integer];
    begin
        FieldIdList := CreateFieldListForTable(TableID);

        // first export the upserts
        ADLSECommunication.Init(TableID, FieldIdList, UpdatedLastTimeStamp, EmitTelemetry);
        ADLSECommunication.CheckEntity(CDMDataFormat, EntityJsonNeedsUpdate, ManifestJsonsNeedsUpdate);
        ExportTableUpdates(TableID, FieldIdList, ADLSECommunication, UpdatedLastTimeStamp);

        // then export the deletes
        ADLSECommunicationDeletions.Init(TableID, FieldIdList, DeletedLastEntryNo, EmitTelemetry);
        // entity has been already checked above
        ExportTableDeletes(TableID, ADLSECommunicationDeletions, DeletedLastEntryNo);
    end;

    procedure UpdatedRecordsExist(TableID: Integer; UpdatedLastTimeStamp: BigInteger): Boolean
    var
        ADLSESeekData: Report "ADLSE Seek Data";
        Rec: RecordRef;
        TimeStampField: FieldRef;
    begin
        SetFilterForUpdates(TableID, UpdatedLastTimeStamp, false, Rec, TimeStampField);
        exit(ADLSESeekData.RecordsExist(Rec));
    end;

    local procedure SetFilterForUpdates(TableID: Integer; UpdatedLastTimeStamp: BigInteger; SkipTimestampSorting: Boolean; var Rec: RecordRef; var TimeStampField: FieldRef)
    begin
        Rec.Open(TableID);
        if not SkipTimestampSorting then
            Rec.SetView(TimestampAscendingSortViewTxt);
        TimeStampField := Rec.Field(0); // 0 is the TimeStamp field
        TimeStampField.SetFilter('>%1', UpdatedLastTimestamp);
    end;

    local procedure ExportTableUpdates(TableID: Integer; FieldIdList: List of [Integer]; ADLSECommunication: Codeunit "ADLSE Communication"; var UpdatedLastTimeStamp: BigInteger)
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSESeekData: Report "ADLSE Seek Data";
        ADLSEExecution: Codeunit "ADLSE Execution";
        Rec: RecordRef;
        TimeStampField: FieldRef;
        Field: FieldRef;
        CustomDimensions: Dictionary of [Text, Text];
        TableCaption: Text;
        EntityCount: Text;
        FlushedTimeStamp: BigInteger;
        FieldId: Integer;
        SystemCreatedAt: DateTime;
    begin
        ADLSESetup.GetSingleton();
        SetFilterForUpdates(TableID, UpdatedLastTimeStamp, ADLSESetup."Skip Timestamp Sorting On Recs", Rec, TimeStampField);

        foreach FieldId in FieldIdList do
            Rec.AddLoadFields(FieldID);

        if not Rec.ReadPermission() then
            Error(InsufficientReadPermErr);

        if ADLSESeekData.FindRecords(Rec) then begin
            if EmitTelemetry then begin
                TableCaption := Rec.Caption();
                EntityCount := Format(Rec.Count());
                CustomDimensions.Add('Entity', TableCaption);
                CustomDimensions.Add('Entity Count', EntityCount);
                ADLSEExecution.Log('ADLSE-021', 'Updated records found', Verbosity::Normal, CustomDimensions);
            end;

            repeat
                // Records created before SystemCreatedAt field was introduced, have null values. Initialize with 01 Jan 1900
                Field := Rec.Field(Rec.SystemCreatedAtNo());
                SystemCreatedAt := Field.Value();
                if SystemCreatedAt = 0DT then
                    Field.Value(CreateDateTime(DMY2Date(1, 1, 1900), 0T));

                if ADLSECommunication.TryCollectAndSendRecord(Rec, TimeStampField.Value(), FlushedTimeStamp) then begin
                    if UpdatedLastTimeStamp < FlushedTimeStamp then // sample the highest timestamp, to cater to the eventuality that the records do not appear sorted per timestamp
                        UpdatedLastTimeStamp := FlushedTimeStamp;
                end else
                    Error('%1%2', GetLastErrorText(), GetLastErrorCallStack());
            until Rec.Next() = 0;

            if ADLSECommunication.TryFinish(FlushedTimeStamp) then begin
                if UpdatedLastTimeStamp < FlushedTimeStamp then // sample the highest timestamp, to cater to the eventuality that the records do not appear sorted per timestamp
                    UpdatedLastTimeStamp := FlushedTimeStamp
            end else
                Error('%1%2', GetLastErrorText(), GetLastErrorCallStack());
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
        ADLSEDeletedRecord.SetView(TimestampAscendingSortViewTxt);
        ADLSEDeletedRecord.SetRange("Table ID", TableID);
        ADLSEDeletedRecord.SetFilter("Entry No.", '>%1', DeletedLastEntryNo);
    end;

    local procedure ExportTableDeletes(TableID: Integer; ADLSECommunication: Codeunit "ADLSE Communication"; var DeletedLastEntryNo: BigInteger)
    var
        ADLSEDeletedRecord: Record "ADLSE Deleted Record";
        ADLSESeekData: Report "ADLSE Seek Data";
        ADLSEUtil: Codeunit "ADLSE Util";
        ADLSEExecution: Codeunit "ADLSE Execution";
        Rec: RecordRef;
        CustomDimensions: Dictionary of [Text, Text];
        TableCaption: Text;
        EntityCount: Text;
        FlushedTimeStamp: BigInteger;
    begin
        SetFilterForDeletes(TableID, DeletedLastEntryNo, ADLSEDeletedRecord);

        if ADLSESeekData.FindRecords(ADLSEDeletedRecord) then begin
            Rec.Open(ADLSEDeletedRecord."Table ID");

            if EmitTelemetry then begin
                TableCaption := Rec.Caption();
                EntityCount := Format(ADLSEDeletedRecord.Count());
                CustomDimensions.Add('Entity', TableCaption);
                CustomDimensions.Add('Entity Count', EntityCount);
                ADLSEExecution.Log('ADLSE-010', 'Deleted records found', Verbosity::Normal, CustomDimensions);
            end;

            repeat
                ADLSEUtil.CreateFakeRecordForDeletedAction(ADLSEDeletedRecord, Rec);
                if ADLSECommunication.TryCollectAndSendRecord(Rec, ADLSEDeletedRecord."Entry No.", FlushedTimeStamp) then
                    DeletedLastEntryNo := FlushedTimeStamp
                else
                    Error('%1%2', GetLastErrorText(), GetLastErrorCallStack());
            until ADLSEDeletedRecord.Next() = 0;

            if ADLSECommunication.TryFinish(FlushedTimeStamp) then
                DeletedLastEntryNo := FlushedTimeStamp
            else
                Error('%1%2', GetLastErrorText(), GetLastErrorCallStack());
        end;
        if EmitTelemetry then
            ADLSEExecution.Log('ADLSE-011', 'Deleted records exported', Verbosity::Normal, CustomDimensions);
    end;

    local procedure CreateFieldListForTable(TableID: Integer) FieldIdList: List of [Integer]
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
        ADLSESessionManager: Codeunit "ADLSE Session Manager";
        ADLSEExecution: Codeunit "ADLSE Execution";
        CustomDimensions: Dictionary of [Text, Text];
    begin
        ADLSERun.RegisterEnded(ADLSETable."Table ID", EmitTelemetry, TableCaption);
        ADLSECurrentSession.Stop(ADLSETable."Table ID", EmitTelemetry, TableCaption);
        CustomDimensions.Add('Entity', TableCaption);
        ADLSEExecution.Log('ADLSE-037', 'Finished the export process', Verbosity::Normal, CustomDimensions);
        Commit();

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
    end;
}
