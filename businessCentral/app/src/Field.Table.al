// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
#pragma warning disable LC0015
table 82562 "ADLSE Field"
#pragma warning restore
{
    Access = Internal;
    Caption = 'ADLSE Field';
    DataClassification = CustomerContent;
    DataPerCompany = false;
    Permissions = tabledata "ADLSE Table" = r;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            AllowInCustomizations = Always;
            Editable = false;
            Caption = 'Table ID';
            TableRelation = "ADLSE Table"."Table ID";

            trigger OnValidate()
            var
                ADLSETable: Record "ADLSE Table";
            begin
                if not ADLSETable.Get(Rec."Table ID") then
                    Error(TableDoesNotExistErr, Rec."Table ID")
            end;
        }
        field(2; "Field ID"; Integer)
        {
            Editable = false;
            Caption = 'Field ID';
            ToolTip = 'Specifies the ID of the field to be exported.';
        }
        field(3; Enabled; Boolean)
        {
            Caption = 'Enabled';
            ToolTip = 'Specifies if the field will be exported.';

            trigger OnValidate()
            var
                ADLSEExternalEvents: Codeunit "ADLSE External Events";
            begin
                if Rec.Enabled then
                    Rec.CheckFieldToBeEnabled();

                ADLSEExternalEvents.OnEnableFieldChanged(Rec);
            end;
        }
        field(100; "FieldCaption"; Text[80])
        {
            Caption = 'Field';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup(Field."Field Caption" where("No." = field("Field ID"), TableNo = field("Table ID")));
            ToolTip = 'Specifies the name of the field to be exported.';
        }
    }

    keys
    {
        key(Key1; "Table ID", "Field ID")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        ADLSESetup.SchemaExported();
    end;

    trigger OnModify()
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSETable: Record "ADLSE Table";
    begin
        ADLSESetup.SchemaExported();

        ADLSETable.Get(Rec."Table ID");
        ADLSETable.CheckNotExporting();
    end;

    trigger OnDelete()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        ADLSESetup.SchemaExported();
    end;

    var
        TableDoesNotExistErr: Label 'Table with ID %1 has not been set to be exported.', Comment = '%1 is the table ID';

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Field", 'ri')]
    procedure InsertForTable(ADLSETable: Record "ADLSE Table")
    var
        Field: Record Field;
        ADLSEField: Record "ADLSE Field";
    begin
        Field.SetRange(TableNo, ADLSETable."Table ID");
        Field.SetFilter("No.", '<%1', 2000000000); // no system fields

        if Field.FindSet() then
            repeat
                if not ADLSEField.Get(ADLSETable."Table ID", Field."No.") then begin
                    Rec."Table ID" := Field.TableNo;
                    Rec."Field ID" := Field."No.";
                    Rec.Enabled := false;
                    Rec.Insert(true);
                end;
            until Field.Next() = 0;
    end;

    procedure CheckFieldToBeEnabled()
    var
        Field: Record Field;
        ADLSESetup: Codeunit "ADLSE Setup";
        ADLSEUtil: Codeunit "ADLSE Util";
    begin
        Field.Get(Rec."Table ID", Rec."Field ID");
        ADLSEUtil.CheckFieldTypeForExport(Field);
        ADLSESetup.CheckFieldCanBeExported(Field);
    end;

    [TryFunction]
    procedure CanFieldBeEnabled()
    begin
        CheckFieldToBeEnabled();
    end;
}