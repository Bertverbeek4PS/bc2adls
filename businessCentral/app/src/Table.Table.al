// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
#pragma warning disable LC0015
table 82561 "ADLSE Table"
#pragma warning restore
{
    Access = Internal;
    Caption = 'ADLSE Table';
    DataClassification = CustomerContent;
    DataPerCompany = false;
    Permissions = tabledata "ADLSE Field" = rd,
                  tabledata "ADLSE Table Last Timestamp" = d,
                  tabledata "ADLSE Deleted Record" = d;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            AllowInCustomizations = Always;
            Editable = false;
            Caption = 'Table ID';
        }
        field(2; State; Integer)
        {
            Caption = 'State';
            ObsoleteReason = 'Use ADLSE Run table instead';
            ObsoleteTag = '1.2.2.0';
            ObsoleteState = Removed;
        }
        field(3; Enabled; Boolean)
        {
            Editable = false;
            Caption = 'Enabled';
            ToolTip = 'Specifies the state of the table. Set this checkmark to export this table, otherwise not.';

            trigger OnValidate()
            var
                ADLSEExternalEvents: Codeunit "ADLSE External Events";
                ADLSETableErr: Label 'The ADLSE Table table cannot be disabled.';
            begin
                if Rec."Table ID" = Database::"ADLSE Table" then
                    if xRec.Enabled = false then
                        Error(ADLSETableErr);

                if Rec.Enabled then
                    CheckExportingOnlyValidFields();

                ADLSEExternalEvents.OnEnableTableChanged(Rec);
            end;
        }
        field(5; LastError; Text[2048])
        {
            Editable = false;
            Caption = 'Last error';
            ObsoleteReason = 'Use ADLSE Run table instead';
            ObsoleteTag = '1.2.2.0';
            ObsoleteState = Removed;
        }
        field(10; ExportCategory; Code[50])
        {
            TableRelation = "ADLSE Export Category";
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the Export Category which can be linked to tables which are part of the export to Azure Datalake. The Category can be used to schedule the export.';
        }
    }

    keys
    {
        key(Key1; "Table ID")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        ADLSESetup.SchemaExported();

        CheckTableOfTypeNormal(Rec."Table ID");
    end;

    trigger OnDelete()
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSETableField: Record "ADLSE Field";
        ADLSETableLastTimestamp: Record "ADLSE Table Last Timestamp";
        ADLSEDeletedRecord: Record "ADLSE Deleted Record";
        ADLSEExternalEvents: Codeunit "ADLSE External Events";
    begin
        ADLSESetup.SchemaExported();

        ADLSETableField.SetRange("Table ID", Rec."Table ID");
        ADLSETableField.DeleteAll(false);

        ADLSEDeletedRecord.SetRange("Table ID", Rec."Table ID");
        ADLSEDeletedRecord.DeleteAll(false);

        ADLSETableLastTimestamp.SetRange("Table ID", Rec."Table ID");
        ADLSETableLastTimestamp.DeleteAll(false);

        ADLSEExternalEvents.OnDeleteTable(Rec);
    end;

    trigger OnModify()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        if (Rec."Table ID" <> xRec."Table ID") or (Rec.Enabled <> xRec.Enabled) then begin
            ADLSESetup.SchemaExported();
            CheckNotExporting();
        end;
    end;

    var
        TableNotNormalErr: Label 'Table %1 is not a normal table.', Comment = '%1: caption of table';
        TableExportingDataErr: Label 'Data is being executed for table %1. Please wait for the export to finish before making changes.', Comment = '%1: table caption';
        TableCannotBeExportedErr: Label 'The table %1 cannot be exported because of the following error. \%2', Comment = '%1: Table ID, %2: error text';
        TablesResetTxt: Label '%1 table(s) were reset %2', Comment = '%1 = number of tables that were reset, %2 = message if tables are exported';
        TableResetExportedTxt: Label 'and are exported to the lakehouse. Please run the notebook first.';

    procedure FieldsChosen(): Integer
    var
        ADLSEField: Record "ADLSE Field";
    begin
        ADLSEField.SetRange("Table ID", Rec."Table ID");
        ADLSEField.SetRange(Enabled, true);
        exit(ADLSEField.Count());
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Table", 'i')]
    procedure Add(TableID: Integer)
    var
        ADLSEExternalEvents: Codeunit "ADLSE External Events";
    begin
        if not CheckTableCanBeExportedFrom(TableID) then
            Error(TableCannotBeExportedErr, TableID, GetLastErrorText());
        Rec.Init();
        Rec."Table ID" := TableID;
        Rec.Enabled := true;
        Rec.Insert(true);

        AddPrimaryKeyFields();
        ADLSEExternalEvents.OnAddTable(Rec);
    end;

    [TryFunction]
    local procedure CheckTableCanBeExportedFrom(TableID: Integer)
    var
        RecordRef: RecordRef;
    begin
        ClearLastError();
        RecordRef.Open(TableID); // proves the table exists and can be opened
    end;

    local procedure CheckTableOfTypeNormal(TableID: Integer)
    var
        TableMetadata: Record "Table Metadata";
        ADLSEUtil: Codeunit "ADLSE Util";
        TableCaption: Text;
    begin
        TableCaption := ADLSEUtil.GetTableCaption(TableID);

        TableMetadata.SetRange(ID, TableID);
        TableMetadata.FindFirst();

        if TableMetadata.TableType <> TableMetadata.TableType::Normal then
            Error(TableNotNormalErr, TableCaption);
    end;

    procedure CheckNotExporting()
    var
        ADLSEUtil: Codeunit "ADLSE Util";
    begin
        if GetLastRunState() = "ADLSE Run State"::InProcess then
            Error(TableExportingDataErr, ADLSEUtil.GetTableCaption(Rec."Table ID"));
    end;

    local procedure GetLastRunState(): Enum "ADLSE Run State"
    var
        ADLSERun: Record "ADLSE Run";
        LastState: Enum "ADLSE Run State";
        LastStarted: DateTime;
        LastErrorText: Text[2048];
    begin
        ADLSERun.GetLastRunDetails(Rec."Table ID", LastState, LastStarted, LastErrorText);
        exit(LastState);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Table", 'rm')]
    procedure ResetSelected()
    begin
        ResetSelected(false);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Table", 'rm')]
    procedure ResetSelected(AllCompanies: Boolean)
    var
        ADLSEDeletedRecord: Record "ADLSE Deleted Record";
        ADLSETableLastTimestamp: Record "ADLSE Table Last Timestamp";
        ADLSESetup: Record "ADLSE Setup";
        ADLSECommunication: Codeunit "ADLSE Communication";
        Counter: Integer;
    begin
        if Rec.FindSet(true) then
            repeat
                if not Rec.Enabled then begin
                    Rec.Enabled := true;
                    Rec.Modify(true);
                end;

                if not AllCompanies then begin
                    ADLSETableLastTimestamp.SaveUpdatedLastTimestamp(Rec."Table ID", 0);
                    ADLSETableLastTimestamp.SaveDeletedLastEntryNo(Rec."Table ID", 0);
                end else begin
                    ADLSETableLastTimestamp.SetRange("Table ID", rec."Table ID");
                    ADLSETableLastTimestamp.ModifyAll("Updated Last Timestamp", 0);
                    ADLSETableLastTimestamp.ModifyAll("Deleted Last Entry No.", 0);
                    ADLSETableLastTimestamp.SetRange("Table ID");
                end;
                ADLSEDeletedRecord.SetRange("Table ID", Rec."Table ID");
                ADLSEDeletedRecord.DeleteAll(false);

                ADLSESetup.GetSingleton();
                if (ADLSESetup."Delete Table") then
                    ADLSECommunication.ResetTableExport(Rec."Table ID", AllCompanies);

                OnAfterResetSelected(Rec);

                Counter += 1;
            until Rec.Next() = 0;
        if (ADLSESetup."Delete Table") and (ADLSESetup."Storage Type" = ADLSESetup."Storage Type"::"Microsoft Fabric") then
            Message(TablesResetTxt, Counter, TableResetExportedTxt)
        else
            Message(TablesResetTxt, Counter, '.');
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Field", 'r')]
    local procedure CheckExportingOnlyValidFields()
    var
        ADLSEField: Record "ADLSE Field";
        Field: Record Field;
        ADLSESetup: Codeunit "ADLSE Setup";
    begin
        ADLSEField.SetRange("Table ID", Rec."Table ID");
        ADLSEField.SetRange(Enabled, true);
        if ADLSEField.FindSet() then
            repeat
                Field.Get(ADLSEField."Table ID", ADLSEField."Field ID");
                ADLSESetup.CheckFieldCanBeExported(Field);
            until ADLSEField.Next() = 0;
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Field", 'r')]
    procedure ListInvalidFieldsBeingExported() FieldList: List of [Text]
    var
        ADLSEField: Record "ADLSE Field";
        ADLSESetup: Codeunit "ADLSE Setup";
        ADLSEUtil: Codeunit "ADLSE Util";
        ADLSEExecution: Codeunit "ADLSE Execution";
        CustomDimensions: Dictionary of [Text, Text];
    begin
        ADLSEField.SetRange("Table ID", Rec."Table ID");
        ADLSEField.SetRange(Enabled, true);
        if ADLSEField.FindSet() then
            repeat
                if not ADLSESetup.CanFieldBeExported(ADLSEField."Table ID", ADLSEField."Field ID") then begin
                    ADLSEField.CalcFields(FieldCaption);
                    FieldList.Add(ADLSEField.FieldCaption);
                end;
            until ADLSEField.Next() = 0;

        if FieldList.Count() > 0 then begin
            CustomDimensions.Add('Entity', ADLSEUtil.GetTableCaption(Rec."Table ID"));
            CustomDimensions.Add('ListOfFields', ADLSEUtil.Concatenate(FieldList));
            ADLSEExecution.Log('ADLSE-029', 'The following invalid fields are configured to be exported from the table.',
                Verbosity::Warning, CustomDimensions);
        end;
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Field", 'rm')]
    procedure AddAllFields()
    var
        ADLSEFields: Record "ADLSE Field";
    begin
        ADLSEFields.InsertForTable(Rec);
        ADLSEFields.SetRange("Table ID", Rec."Table ID");
        if ADLSEFields.FindSet(true) then
            repeat
                if (ADLSEFields.CanFieldBeEnabled()) then begin
                    ADLSEFields.Enabled := true;
                    ADLSEFields.Modify(true);
                end;
            until ADLSEFields.Next() = 0;
    end;

    local procedure AddPrimaryKeyFields()
    var
        Field: Record Field;
        ADLSEField: Record "ADLSE Field";
    begin
        Field.SetRange(TableNo, Rec."Table ID");
        Field.SetRange(IsPartOfPrimaryKey, true);
        if Field.Findset() then
            repeat
                if not ADLSEField.Get(Rec."Table ID", Field."No.") then begin
                    ADLSEField."Table ID" := Field.TableNo;
                    ADLSEField."Field ID" := Field."No.";
                    ADLSEField.Enabled := true;
                    ADLSEField.Insert();
                end;
            until Field.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetSelected(ADLSETable: Record "ADLSE Table")
    begin

    end;
}