#if not CLEAN27
// Licensed under the MIT License. See LICENSE in the project root for license information.
table 82580 "Session Instruction"
{
    Caption = 'Session Instruction';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Session Id"; Integer)
        {
            Caption = 'Session Id';
        }
        field(2; "Object Type"; Option)
        {
            OptionMembers = ,Table,,Report,,Codeunit,,,,,,;
            OptionCaption = ',Table,,Report,,Codeunit,,,,,,';
            Caption = 'Object Type';
        }
        field(3; "Object ID"; Integer)
        {
            Caption = 'Codeunit ID';
        }
        field(4; Method; Enum "ADLSE Session Method")
        {
            Caption = 'Method';
        }
        field(5; Params; Text[250])
        {
            Caption = 'Params';
        }
        field(6; "Status"; Option)
        {
            OptionMembers = "In Progress",Finished,Failed;
            Caption = 'Status';
            DataClassification = CustomerContent;
            OptionCaption = 'In Progress,Finished,Failed';
        }
        field(7; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PK; "Session Id")
        {
            Clustered = true;
        }
    }

    var
        SessionStartFailedErr: Label 'Session %1 executing codeunit %2 method %3 failed to start %4 times. Please try again, or contact your system administrator if the issue persists.', Comment = '%1 = session id; %2 = codeunit executed; %3 = method executed; %4 = no of failed attempts';
        SessionTimeoutErr: Label 'Session %1 executing codeunit %2 method %3 failed to complete within time allocated (%4). Please try again or contact your system administrator if the issue persists.', Comment = '%1 = session id; %2 = codeunit executed; %3 = method executed; %4 = time allocated';
        ChildSessionFailedToStartErr: Label 'Session stopped by host session %1: session failed to start properly', Comment = '%1 = host (this) session id';
        ChildSessionFailedErr: Label 'Session stopped by host session %1: Session failed', Comment = '%1 = host (this) session id';
        ChildSessionStuckInProgressErr: Label 'Session stopped by host session %1: Session stuck in progress', Comment = '%1 = host (this) session id';
        AttemptNo: Integer;

    procedure ExecuteInNewSession()
    var
        NewSessionId: Integer;
        SessionStartTime: DateTime;
        OK: Boolean;
    begin
        AttemptNo += 1;
        SessionStartTime := CurrentDateTime();
        Sleep(100);  // to prevent throttling
        OK := StartSession(NewSessionId, Codeunit::"Session Handler", CompanyName(), Rec, Timeout());
        if OK then
            if not WaitForSession(NewSessionId, SessionStartTime, Timeout()) then begin
                Session.StopSession(NewSessionId, StrSubstNo(ChildSessionFailedToStartErr, SessionId()));
                OK := false;
            end;
        if not OK then
            if AttemptNo <= 10 then
                ExecuteInNewSession();
    end;

    procedure WaitForSession(NewSessionId: Integer; SessionStartTime: DateTime; SessionTimeout: Duration) SessionFound: Boolean;
    var
        SessionInstruction: Record "Session Instruction";
        StartTime: DateTime;
        Stop: Boolean;
    begin
        SessionInstruction.SetFilter(SystemCreatedAt, '>=%1', SessionStartTime);
        SessionInstruction.SetRange("Session Id", NewSessionId);
        StartTime := CurrentDateTime;
        repeat
            Sleep(100);
            SessionFound := SessionInstruction.FindFirst();
            if SessionFound then
                case SessionInstruction.Status of
                    SessionInstruction.Status::Finished:
                        Stop := true;
                    SessionInstruction.Status::Failed:
                        SessionInstruction.RemoveSessionAndError(SessionInstruction."Error Message", StrSubstNo(ChildSessionFailedErr, SessionId()));
                end;
            if not Stop then
                Stop := (CurrentDateTime - StartTime) > SessionTimeout;
        until Stop;
        if SessionFound then begin
            if SessionInstruction.Status < SessionInstruction.Status::Finished then
                SessionInstruction.RemoveSessionAndError(StrSubstNo(SessionTimeoutErr, NewSessionId, Rec."Object ID", Rec.Method, SessionTimeout), StrSubstNo(ChildSessionStuckInProgressErr, SessionId()));
        end else
            if AttemptNo >= 10 then begin
                Session.StopSession(NewSessionId, StrSubstNo(ChildSessionFailedToStartErr, SessionId()));
                Error(ErrorInfo.Create(StrSubstNo(SessionStartFailedErr, NewSessionId, Rec."Object ID", Rec.Method, AttemptNo), IsCollectingErrors));
            end;
    end;

    procedure RemoveSessionAndError(ErrorMessage: Text; Reason: Text)
    begin
        if IsSessionActive(Rec."Session Id") then
            Session.StopSession(Rec."Session Id", Reason);
        Error(ErrorMessage);
    end;

    procedure DeleteStaleSessions()
    var
        SessionInstruction: Record "Session Instruction";
    begin
        SessionInstruction.SetFilter(SystemCreatedAt, '<=%1', CurrentDateTime - Timeout());
        if not SessionInstruction.FindSet() then
            exit;
        repeat
        if not IsSessionActive(SessionInstruction."Session Id") then
            SessionInstruction.Delete();
        until SessionInstruction.Next() = 0;
    end;

    procedure CanInsertNewSession(NewSessionId: Integer): Boolean
    var
        SessionInstruction: Record "Session Instruction";
        DeleteExisting: Boolean;
    begin
        if not SessionInstruction.Get(NewSessionId) then
            exit(true);
        DeleteExisting := SessionInstruction.Status <> SessionInstruction.Status::"In Progress";
        if not DeleteExisting then
            DeleteExisting := CurrentDateTime > SessionInstruction.SystemCreatedAt + Timeout();
        if DeleteExisting then
            SessionInstruction.Delete();
        exit(DeleteExisting);
    end;

    procedure Timeout(): Duration
    begin
        exit(1000 * 60); // 1 minute
    end;
}
#endif
