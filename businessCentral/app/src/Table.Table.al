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
            TableRelation = "ADLSE Export Category Table";
            DataClassification = CustomerContent;
        }
        field(15; ExportFileNumber; Integer)
        {
            Caption = 'Export File Number';
        }
        field(17; "Initial Load Start Date"; Date)
        {
            Caption = 'Initial Load Start Date';
        }
#if not CLEAN27
        field(16; "Process Type"; Enum "ADLSE Process Type")
        {
            Caption = 'Process Type';
            DataClassification = CustomerContent;
        }
#endif
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
        StoppedByUserLbl: Label 'Session stopped by user.';

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
                ADLSESetup.GetSingleton();

                if not AllCompanies then begin
                    if ADLSESetup."Storage Type" = ADLSESetup."Storage Type"::"Open Mirroring" then begin
                        if ADLSETableLastTimestamp.Get(CompanyName, Rec."Table ID") then
                            ADLSETableLastTimestamp.Delete();
                    end
                    else begin
                        ADLSETableLastTimestamp.SaveUpdatedLastTimestamp(Rec."Table ID", 0);
                        ADLSETableLastTimestamp.SaveDeletedLastEntryNo(Rec."Table ID", 0);
                    end;
                end else
                    if ADLSESetup."Storage Type" = ADLSESetup."Storage Type"::"Open Mirroring" then begin
                        ADLSETableLastTimestamp.SetRange("Table ID", rec."Table ID");
                        ADLSETableLastTimestamp.DeleteAll();
                    end
                    else begin
                        ADLSETableLastTimestamp.SetRange("Table ID", rec."Table ID");
                        ADLSETableLastTimestamp.ModifyAll("Updated Last Timestamp", 0);
                        ADLSETableLastTimestamp.ModifyAll("Deleted Last Entry No.", 0);
                        ADLSETableLastTimestamp.SetRange("Table ID");
                    end;
                ADLSEDeletedRecord.SetRange("Table ID", Rec."Table ID");
                ADLSEDeletedRecord.DeleteAll(false);

                if (ADLSESetup."Delete Table") then
                    ADLSECommunication.ResetTableExport(Rec."Table ID", AllCompanies);

                Rec.ExportFileNumber := 1;
                Rec.Modify(true);

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
        RemovedFieldNameLbl: Label '#[%1]', Locked = true;
    begin
        ADLSEField.SetRange("Table ID", Rec."Table ID");
        ADLSEField.SetRange(Enabled, true);
        if ADLSEField.FindSet() then
            repeat
                if not ADLSESetup.CanFieldBeExported(ADLSEField."Table ID", ADLSEField."Field ID") then begin
                    ADLSEField.CalcFields(FieldCaption);
                    //FieldList.Add(ADLSEField.FieldCaption <> '' ? ADLSEField.FieldCaption : StrSubstNo(RemovedFieldNameLbl, ADLSEField."Field ID"));
                    if ADLSEField.FieldCaption <> '' then
                        FieldList.Add(ADLSEField.FieldCaption)
                    else
                        FieldList.Add(StrSubstNo(RemovedFieldNameLbl, ADLSEField."Field ID"));                    
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

    procedure GetLastHeartbeat(): DateTime
    var
        ADLSETableLastTimestamp: Record "ADLSE Table Last Timestamp";
    begin
        ADLSETableLastTimestamp.ReadIsolation(ReadIsolation::ReadUncommitted);
        if not ADLSETableLastTimestamp.ExistsUpdatedLastTimestamp(Rec."Table ID") then
            exit;
        exit(ADLSETableLastTimestamp.SystemModifiedAt)
    end;

    procedure GetActiveSessionId(): Integer
    var
        ExpSessionId: Integer;
    begin
        ExpSessionId := GetCurrentSessionId();
        if ExpSessionId = 0 then
            exit;
        if IsSessionActive(ExpSessionId) then
            exit(ExpSessionId);
    end;

    procedure GetCurrentSessionId(): Integer
    var
        CurrentSession: Record "ADLSE Current Session";
    begin
        CurrentSession.ReadIsolation(ReadIsolation::ReadUncommitted);
        if CurrentSession.Get(Rec."Table ID", CompanyName()) then
            exit(CurrentSession."Session ID");
        exit(0);
    end;

    procedure StopActiveSession()
    var
        CurrentSession: Record "ADLSE Current Session";
        Run: Record "ADLSE Run";
        ADLSEUtil: Codeunit "ADLSE Util";
        ExpSessionId: Integer;
    begin
        ExpSessionId := GetActiveSessionId();
        if ExpSessionId <> 0 then
            if IsSessionActive(ExpSessionId) then
                Session.StopSession(ExpSessionId, StoppedByUserLbl);
        CurrentSession.Stop(Rec."Table ID", false, ADLSEUtil.GetTableCaption(Rec."Table ID"));
        Run.CancelRun(Rec."Table ID");
    end;

#if not CLEAN27
    procedure CheckIfNeedToCommitExternally(TableIdToUpdate: integer): Boolean
    var
        ADLSETable: Record "ADLSE Table";
    begin
        ADLSETable.Get(TableIdToUpdate);
        exit(ADLSETable."Process Type" = ADLSETable."Process Type"::"Commit Externally");
    end;

    procedure CheckIfNeedToIgnoreReadIsolation(TableIdToUpdate: integer): Boolean
    var
        ADLSETable: Record "ADLSE Table";
    begin
        ADLSETable.Get(TableIdToUpdate);
        exit(ADLSETable."Process Type" = ADLSETable."Process Type"::"Ignore Read Isolation");
    end;
#endif

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