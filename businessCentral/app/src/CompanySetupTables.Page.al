namespace bc2adls;

using System.Reflection;
page 82565 "ADLSE Company Setup Tables"
{
    ApplicationArea = All;
    Caption = 'Company Tables';
    LinksAllowed = false;
    UsageCategory = Administration;
    PageType = ListPart;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    SourceTable = "ADLSE Companies Table";

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Sync Company"; Rec."Sync Company")
                {
                }
                field("Table ID"; Rec."Table ID")
                {
                }
                field("Table Caption"; Rec."Table Caption")
                {
                }

                field(FieldsChosen; NumberFieldsChosenValue)
                {
                    Editable = false;
                    Caption = '# Fields selected';
                    ToolTip = 'Specifies if any field has been chosen to be exported. Click on Choose Fields action to add fields to export.';
                    trigger OnDrillDown()
                    var
                        ADLSETable: Record "ADLSE Table";
                    begin
                        ADLSETable.Get(Rec."Table ID");
                        ADLSETable.DoChooseFields();
                        CurrPage.Update();
                    end;
                }
                field("No. of Records"; Rec.GetNoOfDatabaseRecordsText())
                {
                    Caption = 'No. of Records';
                    Editable = false;
                    ToolTip = 'Specifies the No. of Records for the table.';
                }
                field(Status; Rec."Last Run State")
                {
                    Caption = 'Last exported state';
                    Editable = false;
                }
                field("Last Started"; Rec."Last Started")
                {
                    Caption = 'Last started at';
                    Editable = false;
                }
                field("Last Error"; Rec."Last Error")
                {
                    Caption = 'Last error';
                    Editable = false;
                }
                field("Updated Last Timestamp"; Rec."Updated Last Timestamp")
                {
                    Caption = 'Last timestamp';
                    Visible = false;
                }
                field("Last Timestamp Deleted"; Rec."Last Timestamp Deleted")
                {
                    Caption = 'Last timestamp deleted';
                    Visible = false;
                }
            }
        }

    }

    actions
    {
        area(Processing)
        {

            action(Refresh)
            {
                Image = Refresh;
                Caption = 'Refresh';
                ToolTip = 'Refresh all Last Run State.';

                trigger OnAction()
                var
                    CurrADLSECompanySetupTable: record "ADLSE Companies Table";
                begin
                    if CurrADLSECompanySetupTable.FindSet() then
                        repeat
                            RefreshStatus(CurrADLSECompanySetupTable);
                        until CurrADLSECompanySetupTable.Next() = 0;
                    CurrPage.Update(true);
                end;
            }
            action(AddTable)
            {
                Caption = 'Add';
                ToolTip = 'Add a table to be exported.';
                Image = New;
                Enabled = NoExportInProgress;

                trigger OnAction()
                var
                    ADLSESetup: Codeunit "ADLSE Setup";
                begin
                    ADLSESetup.AddTableToExport();
                    CurrPage.Update();
                end;
            }

            action(DeleteTable)
            {
                Caption = 'Delete';
                ToolTip = 'Removes a table that had been added to the list meant for export.';
                Image = Delete;
                Enabled = NoExportInProgress;

                trigger OnAction()
                var
                    ADLSETable: Record "ADLSE Table";
                begin
                    ADLSETable.Get(Rec."Table ID");
                    ADLSETable.Delete(true);
                    CurrPage.Update();
                end;
            }

            action(ChooseFields)
            {
                Caption = 'Choose fields';
                ToolTip = 'Select the fields of this table to be exported.';
                Image = SelectEntries;
                Enabled = NoExportInProgress;

                trigger OnAction()
                var

                    ADLSETable: Record "ADLSE Table";
                begin
                    ADLSETable.Get(Rec."Table ID");
                    ADLSETable.DoChooseFields();
                end;
            }

            action("Reset")
            {
                Caption = 'Reset';
                ToolTip = 'Set the selected tables to export all of its data again.';
                Image = ResetStatus;
                Enabled = NoExportInProgress;

                trigger OnAction()
                var
                    SelectedADLSECompaniesTable: Record "ADLSE Companies Table";
                    SelectedADLSETable: Record "ADLSE Table";
                    ADLSESetup: Record "ADLSE Setup";
                    Options: Text[50];
                    OptionStringLbl: Label 'Current Company,All Companies';
                    ResetTablesForAllCompaniesQst: Label 'Do you want to reset the selected tables for all companies?';
                    ResetTablesQst: Label 'Do you want to reset the selected tables for the current company or all companies?';
                    ChosenOption: Integer;
                begin
                    Options := OptionStringLbl;
                    ADLSESetup.GetSingleton();
                    if ADLSESetup."Storage Type" = ADLSESetup."Storage Type"::"Open Mirroring" then begin
                        if Confirm(ResetTablesForAllCompaniesQst, true) then
                            ChosenOption := 2
                        else
                            exit;
                    end else
                        ChosenOption := Dialog.StrMenu(Options, 1, ResetTablesQst);
                    CurrPage.SetSelectionFilter(SelectedADLSECompaniesTable);
                    SelectedADLSETable.SetFilter("Table ID", GetTableIDFilter(SelectedADLSECompaniesTable));
                    case ChosenOption of
                        0:
                            exit;
                        1:
                            SelectedADLSETable.ResetSelected(false);
                        2:
                            SelectedADLSETable.ResetSelected(true);
                        else
                            Error('Chosen option is not valid');
                    end;
                    CurrPage.Update();
                end;
            }

            action(Logs)
            {
                Caption = 'Execution logs';
                ToolTip = 'View the execution logs for this table in the currently opened company.';
                Image = Log;

                trigger OnAction()
                var
                    ADLSERun: Page "ADLSE Run";
                begin
                    ADLSERun.SetDisplayForTable(Rec."Table ID");
                    ADLSERun.SetCompanyName(Rec."Sync Company");
                    ADLSERun.Run();
                end;

            }
            action(ImportBC2ADLS)
            {
                Caption = 'Import';
                Image = Import;
                ToolTip = 'Import a file with BC2ADLS tables and fields.';

                trigger OnAction()
                var
                    ADLSETable: Record "ADLSE Table";
                begin
                    XmlPort.Run(XmlPort::"BC2ADLS Import", false, true, ADLSETable);
                    CurrPage.Update(false);
                end;
            }
            action(ExportBC2ADLS)
            {
                Caption = 'Export';
                Image = Export;
                ToolTip = 'Exports a file with BC2ADLS tables and fields.';

                trigger OnAction()
                var
                    ADLSETable: Record "ADLSE Table";
                begin
                    ADLSETable.Reset();
                    XmlPort.Run(XmlPort::"BC2ADLS Export", false, false, ADLSETable);
                    CurrPage.Update(false);
                end;
            }
            action(AssignExportCategory)
            {
                Caption = 'Assign Export Category';
                Image = Apply;
                ToolTip = 'Assign an Export Category to the Table.';

                trigger OnAction()
                var
                    ADLSETable: Record "ADLSE Table";
                    AssignExportCategory: Page "ADLSE Assign Export Category";
                begin
                    CurrPage.SetSelectionFilter(ADLSETable);
                    AssignExportCategory.LookupMode(true);
                    if AssignExportCategory.RunModal() = Action::LookupOK then
                        ADLSETable.ModifyAll(ExportCategory, AssignExportCategory.GetExportCategoryCode());
                    CurrPage.Update();
                end;
            }
        }
    }
    trigger OnAfterGetRecord()
    var
        TableMetadata: Record "Table Metadata";
        ADLSETable: Record "ADLSE Table";
        ADLSECurrentSession: Record "ADLSE Current Session";
    begin
        if ADLSETable.Get(Rec."Table ID") then
            if TableMetadata.Get(Rec."Table ID") then
                NumberFieldsChosenValue := ADLSETable.FieldsChosen()
            else
                NumberFieldsChosenValue := 0;
        if ADLSETable.Get(Rec."Table ID") then
            ADLSETable.IssueNotificationIfInvalidFieldsConfiguredToBeExported();
        if ADLSECurrentSession.ChangeCompany(Rec."Sync Company") then
            NoExportInProgress := not ADLSECurrentSession.AreAnySessionsActive();
    end;

    trigger OnOpenPage()
    var
        CurrADLSECompanySetupTable: record "ADLSE Companies Table";
    begin
        if CurrADLSECompanySetupTable.FindSet() then
            repeat
                RefreshStatus(CurrADLSECompanySetupTable);
            until CurrADLSECompanySetupTable.Next() < 1;
    end;

    local procedure RefreshStatus(var CurrRec: Record "ADLSE Companies Table")
    var
        NewSessionId: Integer;
    begin
        Session.StartSession(NewSessionId, Codeunit::"ADLSE Company Run", CurrRec."Sync Company", CurrRec);
    end;

    local procedure GetTableIDFilter(var SelectedADLSECompaniesTable: Record "ADLSE Companies Table") TableIDFilter: Text
    begin
        if SelectedADLSECompaniesTable.FindSet(false) then
            repeat
                if TableIDFilter = '' then
                    TableIDFilter := Format(SelectedADLSECompaniesTable."Table ID")
                else
                    TableIDFilter := TableIDFilter + '|' + Format(SelectedADLSECompaniesTable."Table ID");
            until SelectedADLSECompaniesTable.Next() = 0;
    end;

    var
        NoExportInProgress: Boolean;

        NumberFieldsChosenValue: Integer;

}