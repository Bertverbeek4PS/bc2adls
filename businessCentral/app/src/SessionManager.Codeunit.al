// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
codeunit 82570 "ADLSE Session Manager"
{
    Access = Internal;

    var
        PendingTablesKeyTxt: Label 'Pending', Locked = true;
        ConcatendatedStringLbl: Label '%1,%2', Locked = true;

    procedure Init()
    begin
        SavePendingTables('');
    end;

    procedure StartExport(TableID: Integer; EmitTelemetry: Boolean): Boolean
    begin
        // if the last run failed, ensure that you run again, even though there may be no data differences.
        exit(StartExport(TableID, false, LastRunFailed(TableID, EmitTelemetry), EmitTelemetry));
    end;

    local procedure StartExportFromPending(TableID: Integer; EmitTelemetry: Boolean): Boolean
    begin
        StartExport(TableID, true, false, EmitTelemetry);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Table", 'r')]
    local procedure StartExport(TableID: Integer; ExportWasPending: Boolean; ForceExport: Boolean; EmitTelemetry: Boolean) Started: Boolean
    var
        ADLSETable: Record "ADLSE Table";
        ADLSESetup: Record "ADLSE Setup";
        ADLSEExecution: Codeunit "ADLSE Execution";
        ADLSEUtil: Codeunit "ADLSE Util";
        CustomDimensions: Dictionary of [Text, Text];
        NewSessionID: Integer;
    begin
        if ForceExport or DataChangesExist(TableID) then begin
            ADLSETable.Get(TableID);

            ADLSESetup.GetSingleton();
            if ADLSESetup."Export Company Database Tables" <> '' then
                if (not ADLSEUtil.IsTablePerCompany(TableID)) then
                    if (ADLSESetup."Export Company Database Tables" <> CompanyName()) then
                        exit;

#if not CLEAN27
            Sleep(500);  // to prevent throttling
#endif
            Started := Session.StartSession(NewSessionID, Codeunit::"ADLSE Wrapper Execute", CompanyName(), ADLSETable);
            CustomDimensions.Add('Entity', ADLSEUtil.GetTableCaption(TableID));
            CustomDimensions.Add('ExportWasPending', Format(ExportWasPending));
            if Started then begin
                CustomDimensions.Add('SessionId', Format(NewSessionID));
                if EmitTelemetry then
                    ADLSEExecution.Log('ADLSE-002', 'Export session created', Verbosity::Normal, CustomDimensions);

                if ExportWasPending then
                    RemoveFromPendingTables(TableID); // remove because the export session was started
            end else begin
                if EmitTelemetry then
                    ADLSEExecution.Log('ADLSE-025', 'Session.StartSession() failed', Verbosity::Warning, CustomDimensions);

                if not ExportWasPending then
                    PushToPendingTables(TableID);
            end;
        end else begin
            if ExportWasPending then
                RemoveFromPendingTables(TableID); // remove because a previous export may have successful

            if EmitTelemetry then begin
                CustomDimensions.Add('Entity', ADLSEUtil.GetTableCaption(TableID));
                ADLSEExecution.Log('ADLSE-024', 'No changes to be exported.', Verbosity::Normal, CustomDimensions);
            end;
        end;
    end;

    local procedure DataChangesExist(TableID: Integer): Boolean
    var
        ADLSETableLastTimestamp: Record "ADLSE Table Last Timestamp";
        ADLSEExecute: Codeunit "ADLSE Execute";
        UpdatedLastTimestamp: BigInteger;
        DeletedLastEntryNo: BigInteger;
    begin
        UpdatedLastTimestamp := ADLSETableLastTimestamp.GetUpdatedLastTimestamp(TableID);
        DeletedLastEntryNo := ADLSETableLastTimestamp.GetDeletedLastEntryNo(TableID);

        if ADLSEExecute.UpdatedRecordsExist(TableID, UpdatedLastTimestamp) then
            exit(true);
        if ADLSEExecute.DeletedRecordsExist(TableID, DeletedLastEntryNo) then
            exit(true);
    end;

    local procedure LastRunFailed(TableID: Integer; EmitTelemetry: Boolean) Result: Boolean
    var
        ADLSERun: Record "ADLSE Run";
        ADLSEUtil: Codeunit "ADLSE Util";
        ADLSEExecution: Codeunit "ADLSE Execution";
        CustomDimensions: Dictionary of [Text, Text];
        Status: Enum "ADLSE Run State";
        StartedAt: DateTime;
        Error: Text[2048];
    begin
        ADLSERun.GetLastRunDetails(TableID, Status, StartedAt, Error);
        Result := Status = "ADLSE Run State"::Failed;
        if Result and EmitTelemetry then begin
            CustomDimensions.Add('Entity', ADLSEUtil.GetTableCaption(TableID));
            ADLSEExecution.Log('ADLSE-027', 'Last run failed.', Verbosity::Normal, CustomDimensions);
        end;
    end;

    procedure StartExportFromPendingTables()
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSEExecution: Codeunit "ADLSE Execution";
        CustomDimensions: Dictionary of [Text, Text];
        TableID: Integer;
    begin
        ADLSESetup.GetSingleton();

        if ADLSESetup."Emit telemetry" then begin
            CustomDimensions.Add('PendingTables', Concatenate(GetPendingTablesList()));
            ADLSEExecution.Log('ADLSE-026', 'Export from pending tables starting', Verbosity::Normal, CustomDimensions);
        end;

        // One session freed up. create session from queue
        if GetFromPendingTables(TableID) then
            StartExportFromPending(TableID, ADLSESetup."Emit telemetry");
    end;

    local procedure GetFromPendingTables(var TableID: Integer): Boolean
    var
        Tables: List of [Integer];
    begin
        Tables := GetPendingTablesList();
        exit(Tables.Get(1, TableID));
    end;

    local procedure PushToPendingTables(TableID: Integer)
    var
        Tables: List of [Integer];
    begin
        Tables := GetPendingTablesList();
        if not Tables.Contains(TableID) then begin
            Tables.Add(TableID);
            SavePendingTables(Concatenate(Tables));
        end;
    end;

    local procedure RemoveFromPendingTables(TableID: Integer): Boolean
    var
        Tables: List of [Integer];
    begin
        Tables := GetPendingTablesList();
        if Tables.Remove(TableID) then
            SavePendingTables(Concatenate(Tables));
    end;

    local procedure GetPendingTablesList(): List of [Integer]
    var
        Result: Text;
    begin
#pragma warning disable LC0043
        IsolatedStorage.Get(PendingTablesKeyTxt, DataScope::Company, Result);
        exit(DeConcatenate(Result));
#pragma warning restore LC0043
    end;

    local procedure Concatenate(Values: List of [Integer]) Result: Text
    var
        Value: Integer;
    begin
        foreach Value in Values do
            if Result = '' then
                Result := Format(Value, 0, 9)
            else
                Result := StrSubstNo(ConcatendatedStringLbl, Result, Value);
    end;

    local procedure DeConcatenate(CommaSeperatedText: Text) Values: List of [Integer]
    var
        TextValues: List of [Text];
        ValueText: Text;
        ValueInt: Integer;
    begin
        TextValues := CommaSeperatedText.Split(',');
        foreach ValueText in TextValues do
            if Evaluate(ValueInt, ValueText) then
                Values.Add(ValueInt);
    end;

    internal procedure SavePendingTables(Value: Text)
    begin
#pragma warning disable LC0043
        if IsolatedStorage.Set(PendingTablesKeyTxt, Value, DataScope::Company) then
            Commit(); // changing isolated storage triggers a write transaction      
#pragma warning restore LC0043      
    end;
}