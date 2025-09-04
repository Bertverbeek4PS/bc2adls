codeunit 82579 "ADLSE Multi Company Export"
{
    Permissions = tabledata "ADLSE Companies Table" = RIMD;
    TableNo = "Job Queue Entry";
    trigger OnRun()
    var
        ADLSETable: Record "ADLSE Table";
        ADLSESyncCompanies: Record "ADLSE Sync Companies";
        SessionId: Integer;
    begin
        ADLSESyncCompanies.Reset();
        if Rec."Parameter String" <> '' then
            ADLSESyncCompanies.SetFilter("Sync Company", Rec."Parameter String");
        if GuiAllowed then
            Message(ExportStartedTxt, ADLSETable.Count, ADLSESyncCompanies.Count());
        if ADLSESyncCompanies.FindSet(false) then
            repeat
                Clear(SessionId);
                if session.StartSession(SessionId, Codeunit::"ADLSE Execution", ADLSESyncCompanies."Sync Company") then begin
                    repeat
                        Sleep(10000);
                    until not Session.IsSessionActive(SessionId);
                    Commit();// Commit after each company is done. To prevent rollback of everything
                end;
            until ADLSESyncCompanies.Next() = 0;
    end;


    var
        ExportStartedTxt: Label 'Data export started for %1 tables in %2 Companies. Please refresh this page to see the latest export state for the tables. Only those tables that either have had changes since the last export or failed to export last time have been included. The tables for which the exports could not be started have been queued up for later.', Comment = '%1 = Total number of tables to start the export for. %2 = Total number of companies to export for.';
}