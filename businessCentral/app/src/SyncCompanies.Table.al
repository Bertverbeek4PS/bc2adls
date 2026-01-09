namespace bc2adls;

using System.Environment;

table 82573 "ADLSE Sync Companies"
{
    Access = Internal;
    Caption = 'ADLSE Sync Companies';
    DataClassification = CustomerContent;
    DataPerCompany = false;
    LookupPageId = "ADLSE Company Setup";
    DrillDownPageId = "ADLSE Company Setup";
    Permissions = tabledata "ADLSE Field" = rd,
                  tabledata "ADLSE Table Last Timestamp" = d,
                  tabledata "ADLSE Deleted Record" = d;

    fields
    {
        field(25; "Sync Company"; Text[30])
        {
            NotBlank = true;
            Caption = 'Sync Company';
            ToolTip = 'The company that is being Exported.';
            TableRelation = Company.Name where("Evaluation Company" = const(false));
        }

    }

    keys
    {
        key(PK; "Sync Company")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Sync Company")
        {
        }
        fieldgroup(Brick; "Sync Company")
        {
        }
    }

    trigger OnInsert()
    begin
        UpsertAllTableIds(0);
    end;

    trigger OnDelete()
    begin
        UpsertAllTableIds(2);
    end;

    trigger OnModify()
    begin
        UpsertAllTableIds(1);
    end;

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

                if ADLSETable.FindSet() then
                    repeat
                        if RenameADLSECompaniesTable.Get(ADLSETable."Table ID", SyncCompany) then
                            RenameADLSECompaniesTable.Delete(true);
                    until ADLSETable.Next() = 0;
            0: // Insert: add missing rows only

                if ADLSETable.FindSet() then
                    repeat
                        ADLSECompaniesTable.Init();
                        ADLSECompaniesTable."Table ID" := ADLSETable."Table ID";
                        ADLSECompaniesTable."Sync Company" := SyncCompany;
                        ADLSECompaniesTable.Insert(false);
                    until ADLSETable.Next() = 0;

            1: // Modify: update existing rows only
                begin

                    if not ADLSECompaniesTable.Get(ADLSETable."Table ID", SyncCompany) then begin
                        ADLSECompaniesTable.Init();
                        ADLSECompaniesTable."Table ID" := ADLSETable."Table ID";
                        ADLSECompaniesTable."Sync Company" := SyncCompany;
                        ADLSECompaniesTable.Insert(true);
                    end;
                    repeat
                        if RenameADLSECompaniesTable.Get(ADLSECompaniesTable."Table ID", ADLSECompaniesTable."Sync Company") then
                            RenameADLSECompaniesTable.Rename(ADLSECompaniesTable."Table ID", SyncCompany);
                    until ADLSECompaniesTable.Next() = 0;
                end;
        end;
    end;
}