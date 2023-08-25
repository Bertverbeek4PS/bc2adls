// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
table 82566 "ADLSE Run"
{
    Access = Internal;
    DataClassification = CustomerContent;
    DataPerCompany = false;

    fields
    {
        field(1; ID; Integer)
        {
            Editable = false;
            Caption = 'ID';
            AutoIncrement = true;
        }
        field(2; "Table ID"; Integer)
        {
            Editable = false;
            Caption = 'Table ID';
        }
        field(3; "Company Name"; Text[30])
        {
            Editable = false;
            Caption = 'Company name';
        }
        field(4; State; Enum "ADLSE Run State")
        {
            Editable = false;
            Caption = 'State';
        }
        field(5; Error; Text[2048])
        {
            Editable = false;
            Caption = 'Error';
        }
        field(6; Started; DateTime)
        {
            Editable = false;
            Caption = 'Started';
        }
        field(7; Ended; DateTime)
        {
            Editable = false;
            Caption = 'Ended';
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
        key(Key2; "Table ID", "Company Name")
        {
        }
        key(Key3; Started)
        { // sorting key
        }
    }

    var
        ExportRunNotFoundErr: Label 'No export process running for table.';
        ExportStoppedDueToCancelledSessionTxt: Label 'Export stopped as session was cancelled. Please check state of the export on the data lake before enabling this.';
        CouldNotUpdateExportRunStatusErr: Label 'Could not update the status of the export run for table to %1.', Comment = '%1: New status';

    procedure GetLastRunDetails(TableID: Integer; var Status: enum "ADLSE Run State"; var StartedTime: DateTime; var ErrorIfAny: Text[2048])
    begin
        if FindLastRun(TableID) then begin
            Status := Rec.State;
            StartedTime := Rec.Started;
            ErrorIfAny := Rec.Error;
            exit;
        end;
        Status := "ADLSE Run State"::None;
        StartedTime := 0DT;
        ErrorIfAny := '';
    end;

    procedure RegisterStarted(TableID: Integer)
    begin
        Rec.Init();
        Rec."Table ID" := TableID;
        Rec."Company Name" := CopyStr(CompanyName(), 1, 30);
        Rec.State := "ADLSE Run State"::InProcess;
        Rec.Started := CurrentDateTime();
        Rec.Insert();
    end;

    procedure RegisterEnded(TableID: Integer; EmitTelemetry: Boolean; TableCaption: Text)
    var
        ADLSEExecution: Codeunit "ADLSE Execution";
        ADLSEExternalEvents: Codeunit "ADLSE External Events";
        CustomDimensions: Dictionary of [Text, Text];
        LastErrorMessage: Text;
    begin
        CustomDimensions.Add('Entity', TableCaption);
        if not FindLastRunInProcess(TableID, CustomDimensions) then
            exit;

        LastErrorMessage := GetLastErrorText();
        if LastErrorMessage <> '' then
            if Rec.Error = '' then // do not overwrite a previous error message
                FillErrorDetails(LastErrorMessage, EmitTelemetry, CustomDimensions);

        if Rec.Error = '' then
            Rec.State := "ADLSE Run State"::Success
        else
            Rec.State := "ADLSE Run State"::Failed;

        ADLSEExternalEvents.OnTableExportRunEnded(Rec.ID, Rec."Table ID", Rec.State);

        Rec.Ended := CurrentDateTime();
        if not Rec.Modify() then
            ADLSEExecution.Log('ADLSE-035', StrSubstNo(CouldNotUpdateExportRunStatusErr, Rec.State), Verbosity::Error, CustomDimensions)
        else
            ADLSEExecution.Log('ADLSE-038', 'The export run was registered as ended.', Verbosity::Normal, CustomDimensions);
    end;

    procedure RegisterErrorInProcess(TableID: Integer; EmitTelemetry: Boolean; TableCaption: Text)
    var
        CustomDimensions: Dictionary of [Text, Text];
        LastErrorMessage: Text;
    begin
        CustomDimensions.Add('Entity', TableCaption);
        if not FindLastRunInProcess(TableID, CustomDimensions) then
            exit;

        LastErrorMessage := GetLastErrorText();
        if LastErrorMessage <> '' then
            FillErrorDetails(LastErrorMessage, EmitTelemetry, CustomDimensions);
    end;

    local procedure FillErrorDetails(LastErrorMessage: Text; EmitTelemetry: Boolean; CustomDimensions: Dictionary of [Text, Text])
    var
        ADLSEExecution: Codeunit "ADLSE Execution";
        LastErrorStack: Text;
    begin
        LastErrorStack := GetLastErrorCallStack();
        Rec.Error := CopyStr(LastErrorMessage + LastErrorStack, 1, 2048); // 2048 is the max size of the field 
        Rec.Modify();

        if EmitTelemetry then begin
            CustomDimensions.Add('Error text', LastErrorMessage);
            CustomDimensions.Add('Error stack', LastErrorStack);
            ADLSEExecution.Log('ADLSE-008', 'Error occured during execution', Verbosity::Error, CustomDimensions);
        end;
        ClearLastError();
    end;

    procedure CancelAllRuns()
    begin
        Rec.SetRange(State, "ADLSE Run State"::InProcess);
        Rec.ModifyAll(Ended, CurrentDateTime);
        Rec.ModifyAll(State, "ADLSE Run State"::Failed);
        Rec.ModifyAll(Error, ExportStoppedDueToCancelledSessionTxt);
    end;

    procedure OldRunsExist(): Boolean;
    begin
        CommmonFilterOnOldRuns();
        exit(not Rec.IsEmpty());
    end;

    procedure DeleteOldRuns()
    begin
        CommmonFilterOnOldRuns();
        Rec.DeleteAll();
    end;

    procedure DeleteOldRuns(TableID: Integer)
    begin
        Rec.SetRange("Table ID", TableID);
        DeleteOldRuns();
    end;

    local procedure FindLastRun(TableID: Integer) Found: Boolean
    begin
        Rec.SetCurrentKey(ID);
        Rec.Ascending(false); // order results in a way that the last one shows up first
        Rec.SetRange("Table ID", TableID);
        Rec.SetRange("Company Name", CompanyName());
        Found := Rec.FindFirst();
    end;

    local procedure FindLastRunInProcess(TableID: Integer; CustomDimensions: Dictionary of [Text, Text]): Boolean
    var
        ADLSEExecution: Codeunit "ADLSE Execution";
    begin
        if not FindLastRun(TableID) then begin
            ADLSEExecution.Log('ADLSE-034', ExportRunNotFoundErr, Verbosity::Error, CustomDimensions);
            exit(false);
        end;
        exit(Rec.State = "ADLSE Run State"::InProcess);
    end;

    local procedure CommmonFilterOnOldRuns()
    begin
        Rec.SetFilter(State, '<>%1', "ADLSE Run State"::InProcess);
        Rec.SetRange("Company Name", CompanyName());
    end;
}