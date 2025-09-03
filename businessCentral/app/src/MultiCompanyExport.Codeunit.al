codeunit 82579 "ADLSE Multi Company Export"
{
    Permissions = tabledata "ADLSE Companies Table" = RIMD;
    TableNo = "Job Queue Entry";
    trigger OnRun()
    var
        ADLSESyncCompanies: Record "ADLSE Sync Companies";
        SessionId: Integer;
    begin
        if GuiAllowed then
            Message('Export started');
        ADLSESyncCompanies.Reset();
        if Rec."Parameter String" <> '' then
            ADLSESyncCompanies.SetFilter("Sync Company", Rec."Parameter String");
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
}