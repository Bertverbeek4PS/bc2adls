// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
codeunit 82560 "ADLSE Setup"
{
    Access = Internal;

    var
        FieldClassNotSupportedErr: Label 'The field %1 of class %2 is not supported.', Comment = '%1 = field name, %2 = field class';
        SelectTableLbl: Label 'Select the tables to be exported';
        FieldObsoleteNotSupportedErr: Label 'The field %1 is obsolete', Comment = '%1 = field name';
        FieldDisabledNotSupportedErr: Label 'The field %1 is disabled', Comment = '%1 = field name';

    procedure AddTableToExport()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ADLSETable: Record "ADLSE Table";
        AllObjectsWithCaption: Page "All Objects with Caption";
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.SetFilter("Object ID", '<>%1', Database::"ADLSE Deleted Record");

        AllObjectsWithCaption.Caption(SelectTableLbl);
        AllObjectsWithCaption.SetTableView(AllObjWithCaption);
        AllObjectsWithCaption.LookupMode(true);
        if AllObjectsWithCaption.RunModal() = Action::LookupOK then begin
            AllObjectsWithCaption.SetSelectionFilter(AllObjWithCaption);
            if AllObjWithCaption.FindSet() then
                repeat
                    ADLSETable.Add(AllObjWithCaption."Object ID");
                until AllObjWithCaption.Next() = 0;
        end;
    end;

    procedure ChooseFieldsToExport(ADLSETable: Record "ADLSE Table")
    var
        ADLSEField: Record "ADLSE Field";
    begin
        ADLSEField.SetRange("Table ID", ADLSETable."Table ID");
        ADLSEField.InsertForTable(ADLSETable);
        Commit(); // changes made to the field table go into the database before RunModal is called
        Page.RunModal(Page::"ADLSE Setup Fields", ADLSEField, ADLSEField.Enabled);
    end;

    procedure CanFieldBeExported(TableID: Integer; FieldID: Integer): Boolean
    var
        Field: Record Field;
    begin
        if not Field.Get(TableID, FieldID) then
            exit(false);
        exit(CheckFieldCanBeExported(Field, false));
    end;

    procedure CheckFieldCanBeExported(Field: Record Field)
    begin
        CheckFieldCanBeExported(Field, true);
    end;

    local procedure CheckFieldCanBeExported(Field: Record Field; RaiseError: Boolean): Boolean
    begin
        if Field.Class <> Field.Class::Normal then begin
            if RaiseError then
                Error(FieldClassNotSupportedErr, Field."Field Caption", Field.Class);
            exit(false);
        end;
        if Field.ObsoleteState = Field.ObsoleteState::Removed then begin
            if RaiseError then
                Error(FieldObsoleteNotSupportedErr, Field."Field Caption");
            exit(false);
        end;
        if not Field.Enabled then begin
            if RaiseError then
                Error(FieldDisabledNotSupportedErr, Field."Field Caption");
            exit(false);
        end;
        exit(true);
    end;

    procedure CheckSetup(var ADLSESetup: Record "ADLSE Setup")
    var
        ADLSECurrentSession: Record "ADLSE Current Session";
        ADLSECredentials: Codeunit "ADLSE Credentials";
    begin
        ADLSESetup.GetSingleton();
        if ADLSESetup."Storage Type" = ADLSESetup."Storage Type"::"Azure Data Lake" then
            ADLSESetup.TestField(Container);
        if ADLSESetup."Storage Type" = ADLSESetup."Storage Type"::"Microsoft Fabric" then
            ADLSESetup.TestField(Workspace);
        if ADLSESetup."Storage Type" = ADLSESetup."Storage Type"::"Open Mirroring" then
            ADLSESetup.TestField(LandingZone);

        ADLSESetup.CheckSchemaExported();

        if ADLSECurrentSession.AreAnySessionsActive() then
            ADLSECurrentSession.CheckForNoActiveSessions();

        ADLSECredentials.Check();
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Field", 'rd')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Table", 'rd')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Setup", 'm')]
    procedure FixIncorrectData()
    var
        ADLSEField: Record "ADLSE Field";
        ADLSETable: Record "ADLSE Table";
        ADLSESetupRec: Record "ADLSE Setup";
        TableMetadata: Record "Table Metadata";
        ADLSESetup: Codeunit "ADLSE Setup";
        ConfirmManagement: Codeunit "Confirm Management";
        ShowMessage: Boolean;
        ShowMessageLbl: Label 'Incorrect data has been removed from the table. Please export the schema again and reset all tables.';
        ConfirmQuestionMsg: Label 'With this action you will remove all fields that cannot be exported and all obsolete tables (pending / removed). Do you want to continue?';
    begin
        ShowMessage := false;

        if ConfirmManagement.GetResponse(ConfirmQuestionMsg, true) then begin
            if ADLSEField.FindSet() then
                repeat
                    if not ADLSESetup.CanFieldBeExported(ADLSEField."Table ID", ADLSEField."Field ID") then begin
                        ADLSEField.Delete(false);

                        if ShowMessage = false then
                            ShowMessage := true;
                    end;
                until ADLSEField.Next() = 0;

            ADLSETable.SetRange(Enabled, true);
            if ADLSETable.FindSet() then
                repeat
                    TableMetadata.SetRange(ID, ADLSETable."Table ID");
                    if TableMetadata.FindFirst() then begin
                        if TableMetadata.ObsoleteState <> TableMetadata.ObsoleteState::No then begin
                            ADLSETable.Delete(true);

                            if ShowMessage = false then
                                ShowMessage := true;
                        end;
                    end else begin
                        ADLSETable.Delete(true);

                        if ShowMessage = false then
                            ShowMessage := true;
                    end;
                until ADLSETable.Next() = 0;

            if ShowMessage then begin
                ADLSESetupRec.GetSingleton();
                ADLSESetupRec."Schema Exported On" := 0DT;
                ADLSESetupRec.Modify(true);
                Message(StrSubstNo(ShowMessageLbl));
            end;
        end;
    end;
}