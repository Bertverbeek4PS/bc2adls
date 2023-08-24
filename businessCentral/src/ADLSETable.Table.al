// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
table 82561 "ADLSE Table"
{
    Access = Internal;
    DataClassification = CustomerContent;
    DataPerCompany = false;

    fields
    {
        field(1; "Table ID"; Integer)
        {
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

            trigger OnValidate()
            begin
                if Rec.Enabled then
                    CheckExportingOnlyValidFields();
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
        ADLSESetup.CheckNoSimultaneousExportsAllowed();

        CheckTableOfTypeNormal(Rec."Table ID");
    end;

    trigger OnDelete()
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSETableField: Record "ADLSE Field";
        ADLSETableLastTimestamp: Record "ADLSE Table Last Timestamp";
        ADLSEDeletedRecord: Record "ADLSE Deleted Record";
    begin
        ADLSESetup.CheckNoSimultaneousExportsAllowed();

        ADLSETableField.SetRange("Table ID", Rec."Table ID");
        ADLSETableField.DeleteAll();

        ADLSEDeletedRecord.SetRange("Table ID", Rec."Table ID");
        ADLSEDeletedRecord.DeleteAll();

        ADLSETableLastTimestamp.SetRange("Table ID", Rec."Table ID");
        ADLSETableLastTimestamp.DeleteAll();
    end;

    trigger OnModify()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        ADLSESetup.CheckNoSimultaneousExportsAllowed();

        CheckNotExporting();
    end;

    var
        TableNotNormalErr: Label 'Table %1 is not a normal table.', Comment = '%1: caption of table';
        TableExportingDataErr: Label 'Data is being executed for table %1. Please wait for the export to finish before making changes.', Comment = '%1: table caption';
        TableCannotBeExportedErr: Label 'The table %1 cannot be exported because of the following error. \%2', Comment = '%1: Table ID, %2: error text';
        TablesResetTxt: Label '%1 table(s) were reset.', Comment = '%1 = number of tables that were reset';

    procedure FieldsChosen(): Integer
    var
        ADLSEField: Record "ADLSE Field";
    begin
        ADLSEField.SetRange("Table ID", Rec."Table ID");
        ADLSEField.SetRange(Enabled, true);
        exit(ADLSEField.Count());
    end;

    procedure Add(TableID: Integer)
    begin
        if not CheckTableCanBeExportedFrom(TableID) then
            Error(TableCannotBeExportedErr, TableID, GetLastErrorText());
        Rec.Init();
        Rec."Table ID" := TableID;
        Rec.Enabled := true;
        Rec.Insert(true);
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

    local procedure GetLastRunState(): enum "ADLSE Run State"
    var
        ADLSERun: Record "ADLSE Run";
        LastState: enum "ADLSE Run State";
        LastStarted: DateTime;
        LastErrorText: Text[2048];
    begin
        ADLSERun.GetLastRunDetails(Rec."Table ID", LastState, LastStarted, LastErrorText);
        exit(LastState);
    end;

    procedure ResetSelected()
    var
        ADLSEDeletedRecord: Record "ADLSE Deleted Record";
        ADLSETableLastTimestamp: Record "ADLSE Table Last Timestamp";
        Counter: Integer;
    begin
        if Rec.FindSet(true) then
            repeat
                Rec.Enabled := true;
                Rec.Modify();

                ADLSETableLastTimestamp.SaveUpdatedLastTimestamp(Rec."Table ID", 0);
                ADLSETableLastTimestamp.SaveDeletedLastEntryNo(Rec."Table ID", 0);

                ADLSEDeletedRecord.SetRange("Table ID", Rec."Table ID");
                ADLSEDeletedRecord.DeleteAll();
                Counter += 1;
            until Rec.Next() = 0;
        Message(TablesResetTxt, Counter);
    end;

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
}