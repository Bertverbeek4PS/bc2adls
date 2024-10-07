// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
codeunit 82569 "ADLSE Execution"
{
    trigger OnRun()
    begin
        StartExport();
    end;

    var
        EmitTelemetry: Boolean;
        ExportStartedTxt: Label 'Data export started for %1 out of %2 tables. Please refresh this page to see the latest export state for the tables. Only those tables that either have had changes since the last export or failed to export last time have been included. The tables for which the exports could not be started have been queued up for later.', Comment = '%1 = number of tables to start the export for. %2 = total number of tables enabled for export.';
        SuccessfulStopMsg: Label 'The export process was stopped successfully.';
        JobCategoryCodeTxt: Label 'ADLSE';
        JobCategoryDescriptionTxt: Label 'Export to Azure Data Lake';
        JobScheduledTxt: Label 'The job has been scheduled. Please go to the Job Queue Entries page to locate it and make further changes.';
        ClearSchemaExportedOnMsg: Label 'The schema export date has been cleared.';


    internal procedure StartExport()
    var
        ADLSESetupRec: Record "ADLSE Setup";
        ADLSETable: Record "ADLSE Table";
        ADLSEField: Record "ADLSE Field";
        ADLSECurrentSession: Record "ADLSE Current Session";
        ADLSESetup: Codeunit "ADLSE Setup";
        ADLSECommunication: Codeunit "ADLSE Communication";
        ADLSESessionManager: Codeunit "ADLSE Session Manager";
        ADLSEExternalEvents: Codeunit "ADLSE External Events";
        Counter: Integer;
        Started: Integer;
    begin
        ADLSESetup.CheckSetup(ADLSESetupRec);
        EmitTelemetry := ADLSESetupRec."Emit telemetry";
        ADLSECurrentSession.CleanupSessions();
        if ADLSESetupRec.GetStorageType() = ADLSESetupRec."Storage Type"::"Azure Data Lake" then //Because Fabric doesn't have do create a container
            ADLSECommunication.SetupBlobStorage();
        ADLSESessionManager.Init();

        ADLSEExternalEvents.OnExport(ADLSESetupRec);

        if EmitTelemetry then
            Log('ADLSE-022', 'Starting export for all tables', Verbosity::Normal);
        ADLSETable.SetRange(Enabled, true);
        if ADLSETable.FindSet(false) then
            repeat
                Counter += 1;
                ADLSEField.SetRange("Table ID", ADLSETable."Table ID");
                ADLSEField.SetRange(Enabled, true);
                if not ADLSEField.IsEmpty() then
                    if ADLSESessionManager.StartExport(ADLSETable."Table ID", EmitTelemetry) then
                        Started += 1;
            until ADLSETable.Next() = 0;

        Message(ExportStartedTxt, Started, Counter);
        if EmitTelemetry then
            Log('ADLSE-001', StrSubstNo(ExportStartedTxt, Started, Counter), Verbosity::Normal);

        ADLSEExternalEvents.OnAllExportIsFinished(ADLSESetupRec);
    end;

    internal procedure StopExport()
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSERun: Record "ADLSE Run";
        ADLSECurrentSession: Record "ADLSE Current Session";
    begin
        ADLSESetup.GetSingleton();
        if ADLSESetup."Emit telemetry" then
            Log('ADLSE-003', 'Stopping export sessions', Verbosity::Normal);

        ADLSECurrentSession.CancelAll();

        ADLSERun.CancelAllRuns();

        Message(SuccessfulStopMsg);
        if ADLSESetup."Emit telemetry" then
            Log('ADLSE-019', 'Stopped export sessions', Verbosity::Normal);
    end;

    internal procedure SchemaExport()
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSETable: Record "ADLSE Table";
        ADLSECurrentSession: Record "ADLSE Current Session";
        AllObjWithCaption: Record AllObjWithCaption;
        ADLSEExecute: Codeunit "ADLSE Execute";
        ADLSEExternalEvents: Codeunit "ADLSE External Events";
        ProgressWindowDialog: Dialog;
        Progress1Msg: Label 'Current Table:           #1##########\', Comment = '#1: table caption';
    begin
        // ensure that no current export sessions running
        ADLSECurrentSession.CheckForNoActiveSessions();

        ADLSETable.Reset();
        ADLSETable.SetRange(Enabled, true);
        if ADLSETable.FindSet(false) then
            if GuiAllowed then
                ProgressWindowDialog.Open(Progress1Msg);
        repeat
            if GuiAllowed then begin
                AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
                AllObjWithCaption.SetRange("Object ID", ADLSETable."Table ID");
                if AllObjWithCaption.FindFirst() then
                    if GuiAllowed then
                        ProgressWindowDialog.Update(1, AllObjWithCaption."Object Caption");
            end;

            ADLSEExecute.ExportSchema(ADLSETable."Table ID");
        until ADLSETable.Next() = 0;

        if GuiAllowed then
            ProgressWindowDialog.Close();

        ADLSESetup.GetSingleton();
        ADLSESetup."Schema Exported On" := CurrentDateTime();
        ADLSESetup.Modify();

        ADLSEExternalEvents.OnExportSchema(ADLSESetup);
    end;

    internal procedure ClearSchemaExportedOn()
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSEExternalEvents: Codeunit "ADLSE External Events";
    begin
        ADLSESetup.GetSingleton();
        ADLSESetup."Schema Exported On" := 0DT;
        ADLSESetup.Modify();
        if GuiAllowed then
            Message(ClearSchemaExportedOnMsg);

        ADLSEExternalEvents.OnClearSchemaExportedOn(ADLSESetup);
    end;

    internal procedure ScheduleExport()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ScheduleAJob: Page "Schedule a Job";
        Handled: Boolean;
    begin
        OnBeforeScheduleExport(Handled);
        if Handled then
            exit;

        CreateJobQueueEntry(JobQueueEntry);
        ScheduleAJob.SetJob(JobQueueEntry);
        Commit(); // above changes go into the DB before RunModal
        if ScheduleAJob.RunModal() = Action::OK then
            Message(JobScheduledTxt);
    end;

    local procedure CreateJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry")
    var
        JobQueueCategory: Record "Job Queue Category";
    begin
        JobQueueCategory.InsertRec(JobCategoryCodeTxt, JobCategoryDescriptionTxt);
        if JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"ADLSE Execution") then
            exit;
        JobQueueEntry.Init();
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry.Description := JobQueueCategory.Description;
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"ADLSE Execution";
        JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime(); // now
    end;

    internal procedure Log(EventId: Text; Message: Text; Verbosity: Verbosity)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        Log(EventId, Message, Verbosity, CustomDimensions);
    end;

    internal procedure Log(EventId: Text; Message: Text; Verbosity: Verbosity; CustomDimensions: Dictionary of [Text, Text])
    begin
        Session.LogMessage(EventId, Message, Verbosity, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
    end;

    [InherentPermissions(PermissionObjectType::Table, Database::"ADLSE Table Last Timestamp", 'X')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Table Last Timestamp", 'R')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterGetDatabaseTableTriggerSetup', '', true, true)]
    local procedure GetDatabaseTableTriggerSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        ADLSETableLastTimestamp: Record "ADLSE Table Last Timestamp";
    begin
        if CompanyName() = '' then
            exit;

        // track deletes only if at least one export has been made for that table
        if ADLSETableLastTimestamp.ExistsUpdatedLastTimestamp(TableId) then
            OnDatabaseDelete := true;
    end;

    [InherentPermissions(PermissionObjectType::Table, Database::"ADLSE Table Last Timestamp", 'X')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Table Last Timestamp", 'R')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Deleted Record", 'RI')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnDatabaseDelete', '', true, true)]
    local procedure OnAfterOnDatabaseDelete(RecRef: RecordRef)
    var
        ADLSETableLastTimestamp: Record "ADLSE Table Last Timestamp";
        ADLSEDeletedRecord: Record "ADLSE Deleted Record";
    begin
        // exit function for tables that you do not wish to sync deletes for
        // you should also consider not registering for deletes for the table in the function GetDatabaseTableTriggerSetup above.
        // if RecRef.Number = Database::"G/L Entry" then
        //     exit;

        // check if table is to be tracked.
        if not ADLSETableLastTimestamp.ExistsUpdatedLastTimestamp(RecRef.Number) then
            exit;

        ADLSEDeletedRecord.TrackDeletedRecord(RecRef);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeScheduleExport(var Handled: Boolean)
    begin

    end;
}