#if not CLEAN27
// Licensed under the MIT License. See LICENSE in the project root for license information.
codeunit 82580 "Session Handler"
{
    TableNo = "Session Instruction";

    trigger OnRun()
    begin
        if Rec."Session Id" = 0 then begin
            Rec.DeleteStaleSessions();
            Rec."Session Id" := SessionId();
            if not Rec.CanInsertNewSession(Rec."Session Id") then
                exit;
            Rec.Insert(true);
            Commit();
            ClearLastError();
            if not Codeunit.Run(Codeunit::"Session Handler", Rec) then begin
                Rec."Status" := Rec.Status::Failed;
                Rec."Error Message" := CopyStr(GetLastErrorText, 1, MaxStrLen(Rec."Error Message"));
            end else
                Rec.Status := Rec.Status::Finished;
            Rec.Modify();
        end else
            WrapRun(Rec);
    end;

    procedure WrapRun(var SessionInstruction: Record "Session Instruction")
    var
        SessionMethodInterface: Interface "ADLSE Session Method Interface";
    begin
        SessionMethodInterface := SessionInstruction.Method;
        SessionMethodInterface.Execute(SessionInstruction.Params);
    end;
}
#endif
