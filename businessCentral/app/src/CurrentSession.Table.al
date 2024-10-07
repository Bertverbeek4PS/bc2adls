// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
#pragma warning disable LC0015
table 82565 "ADLSE Current Session"
#pragma warning restore
{
    Access = Internal;
    Caption = 'ADLSE Current Session';
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Editable = false;
            Caption = 'Table ID';
        }
        field(2; "Session ID"; Integer)
        {
            Editable = false;
            Caption = 'Session ID';
        }
        field(3; "Session Unique ID"; Guid)
        {
            Editable = false;
            Caption = 'Session unique ID';
        }
        field(10; "Company Name"; Text[30])
        {
            Editable = false;
            Caption = 'Company name';
        }
    }

    keys
    {
        key(Key1; "Table ID", "Company Name")
        {
            Clustered = true;
        }

        key(SessionID; "Session ID")
        {
        }
    }

    var
        SessionTerminatedMsg: Label 'Export to data lake session for table %1 terminated by user.', Comment = '%1 is the table name corresponding to the session';
        ExportDataInProgressErr: Label 'An export data process is already running. Please wait for it to finish.';
        InsertFailedErr: Label 'Could not start the export as there is already an active export running for the table %1. If this is not so, please stop all exports and try again.', Comment = '%1 = table caption';
        CouldNotStopSessionErr: Label 'Could not delete the export table session %1 for table on company %2.', Comment = '%1: session id, %2: company name';

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Current Session", 'i')]
    procedure Start(ADLSETableID: Integer)
    var
        ADLSEUtil: Codeunit "ADLSE Util";
    begin
        Rec.Init();
        Rec."Table ID" := ADLSETableID;
        Rec."Session ID" := SessionId();
        Rec."Session Unique ID" := GetActiveSessionIDForSession(SessionId());
        Rec."Company Name" := CopyStr(CompanyName(), 1, 30);
        if not Rec.Insert(true) then
            Error(InsertFailedErr, ADLSEUtil.GetTableCaption(ADLSETableID));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Current Session", 'rd')]
    procedure Stop(ADLSETableID: Integer; EmitTelemetry: Boolean; TableCaption: Text)
    var
        ADLSEExecution: Codeunit "ADLSE Execution";
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not Rec.Get(ADLSETableID, CompanyName()) then
            exit;
        CustomDimensions.Add('Entity', TableCaption);
        if not Rec.Delete(true) then
            ADLSEExecution.Log('ADLSE-036', StrSubstNo(CouldNotStopSessionErr, Rec."Session ID", CompanyName()), Verbosity::Error, CustomDimensions)
        else
            ADLSEExecution.Log('ADLSE-039', 'Session ended and was removed', Verbosity::Normal, CustomDimensions);
    end;

    procedure CheckForNoActiveSessions()
    begin
        if AreAnySessionsActive() then
            Error(ExportDataInProgressErr);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Current Session", 'r')]
    procedure AreAnySessionsActive() AnyActive: Boolean
    begin
        Rec.SetRange("Company Name", CopyStr(CompanyName(), 1, 30));
        if Rec.FindSet(false) then
            repeat
                if IsSessionActive() then begin
                    AnyActive := true;
                    exit;
                end;
            until Rec.Next() = 0;
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Current Session", 'd')]
    procedure CleanupSessions()
    begin
        Rec.SetRange("Company Name", CopyStr(CompanyName(), 1, 30));
        Rec.DeleteAll(false);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Current Session", 'rd')]
    procedure CancelAll()
    var
        ADLSEUtil: Codeunit "ADLSE Util";
    begin
        if Rec.FindSet(false) then
            repeat
                if IsSessionActive() then
                    Session.StopSession(Rec."Session ID", StrSubstNo(SessionTerminatedMsg, ADLSEUtil.GetTableCaption(Rec."Table ID")));
            until Rec.Next() = 0;

        Rec.DeleteAll(false);
    end;

    local procedure IsSessionActive(): Boolean
    var
        ActiveSession: Record "Active Session";
    begin
        ActiveSession.SetLoadFields("Session Unique ID");
        if ActiveSession.Get(ServiceInstanceId(), Rec."Session ID") then
            exit(ActiveSession."Session Unique ID" = Rec."Session Unique ID");
    end;

    procedure GetActiveSessionIDForSession(SessId: Integer): Guid
    var
        ActiveSession: Record "Active Session";
    begin
        ActiveSession.SetLoadFields("Session Unique ID");
        ActiveSession.Get(ServiceInstanceId(), SessId);
        exit(ActiveSession."Session Unique ID");
    end;
}