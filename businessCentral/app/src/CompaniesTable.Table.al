namespace bc2adls;

using System.Environment;
using System.Reflection;
#pragma warning disable LC0015
table 82572 "ADLSE Companies Table"
#pragma warning restore
{
    Access = Internal;
    Caption = 'ADLSE Companies Table';
    DataClassification = CustomerContent;
    DataPerCompany = false;
    Permissions = tabledata "ADLSE Field" = rd,
                  tabledata "ADLSE Table Last Timestamp" = d,
                  tabledata "ADLSE Deleted Record" = d;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            AllowInCustomizations = AsReadOnly;
            Editable = false;
            Caption = 'Table ID';
            ToolTip = 'Specifies the ID of the table to be exported.';
        }
        field(20; "Table Caption"; Text[249])
        {
            Caption = 'Table Caption';
            ToolTip = 'Specifies the caption of the table to be exported.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(table), "Object ID" = field("Table ID")));
        }
        field(25; "Sync Company"; Text[30])
        {
            Caption = 'Sync Company';
            TableRelation = Company.Name where("Evaluation Company" = const(false));
            ToolTip = 'Specifies the company this table is synced for.';
        }
        field(40; "Updated Last Timestamp"; BigInteger)
        {
            Caption = 'Last timestamp';
            ToolTip = 'Specifies the timestamp of the record in this table that was exported last.';
        }
        field(45; "Last Timestamp Deleted"; BigInteger)
        {
            Caption = 'Last timestamp deleted';
            ToolTip = 'Specifies the timestamp of the deleted records in this table that was exported last.';
        }
        field(50; "Last Run State"; Enum "ADLSE Run State")
        {
            Caption = 'Last exported state';
            ToolTip = 'Specifies the status of the last export from this table in this company.';
        }
        field(55; "Last Started"; DateTime)
        {
            Caption = 'Last started at';
            ToolTip = 'Specifies the time of the last export from this table in this company.';
        }
        field(60; "Last Error"; Text[2048])
        {
            Caption = 'Last error';
            ToolTip = 'Specifies the error message from the last export of this table in this company.';
        }
    }

    keys
    {
        key(PK; "Table ID", "Sync Company")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Table ID", "Sync Company")
        {
        }
        fieldgroup(Brick; "Table ID", "Sync Company")
        {
        }
    }

    trigger OnInsert()
    var
    begin
        UpsertAllTableIds(0);
    end;

    trigger OnDelete()
    var
    begin
        UpsertAllTableIds(2);
    end;

    trigger OnModify()
    var
    begin
        UpsertAllTableIds(1);
    end;

    procedure GetNoOfDatabaseRecordsText(): Text
    var
        RecRef: RecordRef;
    begin

        if Rec."Table ID" = 0 then
            exit;

        RecRef.Open(Rec."Table ID", false, Rec."Sync Company");
        exit(Format(RecRef.Count()));
    end;


    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Companies Table", 'rimd')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Deleted Record", 'rimd')]
    local procedure UpsertAllTableIds(Rowmarker: Integer)
    var
        ADLSETable: Record "ADLSE Table";
        ADLSECompaniesTable: Record "ADLSE Companies Table";
        RenameADLSECompaniesTable: Record "ADLSE Companies Table";
        SyncCompany: Text[30];
        xSyncCompany: Text[30];
    begin
        // Rowmarker semantics used here:
        // 0 = Insert -> add missing rows for this Sync Company across ALL table IDs (do not update existing rows)
        // 1 = Modify -> update existing rows for this Sync Company across ALL table IDs (do not insert missing rows)
        // 2 = Delete -> remove ALL rows for this Sync Company across ALL table IDs (except current row already being deleted)

        SyncCompany := Rec."Sync Company";
        xSyncCompany := xRec."Sync Company";
        if SyncCompany = '' then
            exit;

        case Rowmarker of
            2: // Delete: remove this company entry for all other tables (current one is already being deleted)
                begin
                    ADLSETable.Get(Rec."Table ID");
                    ADLSETable.Delete(true);
                end;

            0: // Insert: add missing rows only
                begin
                    ADLSETable.Init();
                    ADLSETable."Table ID" := Rec."Table ID";
                    ADLSETable.Enabled := true;
                    ADLSETable.Insert(true);
                end;
            1: // modify: 
                begin

                    if xSyncCompany = SyncCompany then
                        exit;

                    ADLSECompaniesTable.SetFilter("Table ID", '<>%1', Rec."Table ID");
                    ADLSECompaniesTable.SetRange("Sync Company", xSyncCompany);
                    if ADLSECompaniesTable.FindSet() then
                        repeat
                            if RenameADLSECompaniesTable.Get(ADLSECompaniesTable."Table ID", ADLSECompaniesTable."Sync Company") then
                                RenameADLSECompaniesTable.Rename(ADLSECompaniesTable."Table ID", SyncCompany);
                        until ADLSECompaniesTable.Next() < 1;
                end;
        end;
    end;
}