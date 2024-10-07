// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
page 82562 "ADLSE Setup Fields"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "ADLSE Field";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    Caption = 'Select the fields to be exported';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("FieldCaption"; Rec.FieldCaption) { }

                field("Field ID"; Rec."Field ID")
                {
                    Caption = 'Number';
                    Visible = false;
                }

                field(Enabled; Rec.Enabled) { }

                field(ADLSFieldName; ADLSFieldName)
                {
                    Caption = 'Attribute name';
                    ToolTip = 'Specifies the name of the field for this entity in the data lake.';
                    Editable = false;
                }

                field("Field Class"; FieldClassName)
                {
                    Caption = 'Class';
                    OptionCaption = 'Normal,FlowField,FlowFilter';
                    ToolTip = 'Specifies the field class.';
                    Editable = false;
                    Visible = false;
                }

                field("Field Type"; FieldTypeName)
                {
                    Caption = 'Type';
                    ToolTip = 'Specifies the field type.';
                    Editable = false;
                    Visible = false;
                }

                field("Obsolete State"; FieldObsoleteState)
                {
                    Caption = 'Obsolete State';
                    OptionCaption = 'No,Pending,Removed';
                    ToolTip = 'Specifies the Obsolete State of the field.';
                    Editable = false;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SelectAll)
            {
                Caption = 'Enable all valid fields';
                ApplicationArea = All;
                ToolTip = 'Enables all fields of the table that can be enabled.';
                Image = Apply;

                trigger OnAction()
                var
                    SomeFieldsCouldNotBeEnabled: Boolean;
                begin
                    Rec.SetFilter(Enabled, '<>%1', true);
                    if Rec.FindSet() then
                        repeat
                            if Rec.CanFieldBeEnabled() then begin
                                Rec.Validate(Enabled, true);
                                Rec.Modify(true);
                            end else
                                SomeFieldsCouldNotBeEnabled := true;
                        until Rec.Next() = 0;
                    Rec.SetRange(Enabled);
                    if SomeFieldsCouldNotBeEnabled then
                        Message(SomeFieldsCouldNotBeEnabledMsg);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Field: Record Field;
        ADLSEUtil: Codeunit "ADLSE Util";
    begin
        Field.Get(Rec."Table ID", Rec."Field ID");
        ADLSFieldName := ADLSEUtil.GetDataLakeCompliantFieldName(Field.FieldName, Field."No.");
        FieldClassName := Field.Class;
        FieldTypeName := Field."Type Name";
        FieldObsoleteState := Field.ObsoleteState;
    end;

    var
        ADLSFieldName: Text;
        FieldClassName: Option Normal,FlowField,FlowFilter;
        FieldTypeName: Text[30];
        SomeFieldsCouldNotBeEnabledMsg: Label 'One or more fields could not be enabled.';
        FieldObsoleteState: Option No,Pending,Removed;
}