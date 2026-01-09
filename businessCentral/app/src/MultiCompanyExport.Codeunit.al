namespace bc2adls;

using System.Threading;
using System.Environment;
codeunit 82579 "ADLSE Multi Company Export"
{
    Permissions = tabledata "ADLSE Companies Table" = RIMD;
    TableNo = "Job Queue Entry";
    trigger OnRun()
    var
        ADLSETable: Record "ADLSE Table";
        ADLSESyncCompanies: Record "ADLSE Sync Companies";
        ADLSECurrentSession: Record "ADLSE Current Session";
        NewSessionID: Integer;
    begin
        ADLSESyncCompanies.Reset();
        if CompanyFilters <> '' then
            ADLSESyncCompanies.SetFilter("Sync Company", '%1', this.CompanyFilters);
        if GuiAllowed() then
            Message(this.ExportStartedTxt, ADLSETable.Count(), ADLSESyncCompanies.Count());
        if ADLSESyncCompanies.FindSet(false) then
            repeat
                Clear(NewSessionID);
                if session.StartSession(NewSessionID, Codeunit::"ADLSE Execution", ADLSESyncCompanies."Sync Company") then begin
                    ADLSECurrentSession.ChangeCompany(ADLSESyncCompanies."Sync Company");
                    repeat
                        Sleep(10000);
                    until (not Session.IsSessionActive(NewSessionID) and (not CheckAnyActiveSession(ADLSESyncCompanies."Sync Company")) and (not ADLSECurrentSession.AreAnySessionsActive()));
                    Commit();// Commit after each company is done. To prevent rollback of everything
                end;
            until ADLSESyncCompanies.Next() = 0;
    end;


    var
        CompanyFilters: Text;
        ExportStartedTxt: Label 'Data export started for %1 tables in %2 Companies. Please refresh this page to see the latest export state for the tables. Only those tables that either have had changes since the last export or failed to export last time have been included. The tables for which the exports could not be started have been queued up for later.', Comment = '%1 = Total number of tables to start the export for. %2 = Total number of companies to export for.';

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Current Session", 'rd')]

    local procedure CheckAnyActiveSession(CurrentCompany: Text[30]): Boolean
    var
        ActiveSession: Record "Active Session";
        ADLSECurrentSession: Record "ADLSE Current Session";
    begin
        SelectLatestVersion();
        ADLSECurrentSession.ReadIsolation := ADLSECurrentSession.ReadIsolation::ReadUncommitted;
        ADLSECurrentSession.SetRange("Company Name", CurrentCompany);
        if ADLSECurrentSession.FindSet(false) then
            repeat
                ActiveSession.Reset();
                ActiveSession.SetRange("Session ID", ADLSECurrentSession."Session ID");
                ActiveSession.SetRange("Client Type", ActiveSession."Client Type"::Background);
                if not ActiveSession.IsEmpty() then
                    exit(true);
            until ADLSECurrentSession.Next() = 0;
    end;


    procedure SetCompanyFilter(Filter: Text)
    begin
        this.CompanyFilters := Filter;
    end;
}