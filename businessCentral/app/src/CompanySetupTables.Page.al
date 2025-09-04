page 82565 "ADLSE Company Setup Tables"
{
    Caption = 'Company Tables';
    LinksAllowed = false;
    UsageCategory = Administration;
    PageType = ListPart;
    SourceTable = "ADLSE Companies Table";


    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Sync Company"; Rec."Sync Company")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the company this table is synced for.';
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                }
                field("Table Caption"; Rec."Table Caption")
                {
                    ApplicationArea = All;
                }

                field(FieldsChosen; NumberFieldsChosenValue)
                {
                    ApplicationArea = All;
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
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the No. of Records for the table.';
                }
                field(Status; Rec."Last Run State")
                {
                    ApplicationArea = All;
                    Caption = 'Last exported state';
                    Editable = false;
                    ToolTip = 'Specifies the status of the last export from this table in this company.';
                }
                field("Last Started"; Rec."Last Started")
                {
                    ApplicationArea = All;
                    Caption = 'Last started at';
                    Editable = false;
                    ToolTip = 'Specifies the time of the last export from this table in this company.';
                }
                field("Last Error"; Rec."Last Error")
                {
                    ApplicationArea = All;
                    Caption = 'Last error';
                    Editable = false;
                    ToolTip = 'Specifies the error message from the last export of this table in this company.';
                }
                field("Updated Last Timestamp"; Rec."Updated Last Timestamp")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the timestamp of the record in this table that was exported last.';
                    Caption = 'Last timestamp';
                    Visible = false;
                }
                field("Last Timestamp Deleted"; Rec."Last Timestamp Deleted")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the timestamp of the deleted records in this table that was exported last.';
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
                ApplicationArea = All;
                Caption = 'Refresh';
                ToolTip = 'Refresh all Last Run State';

                trigger OnAction()
                var
                    CurrADLSECompanySetupTable: record "ADLSE Companies Table";
                begin
                    if CurrADLSECompanySetupTable.FindSet() then
                        repeat
                            RefreshStatus(CurrADLSECompanySetupTable);
                        until CurrADLSECompanySetupTable.Next() < 1;
                    CurrPage.Update(true);
                end;
            }
            action(AddTable)
            {
                ApplicationArea = All;
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
                ApplicationArea = All;
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
                ApplicationArea = All;
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
                ApplicationArea = All;
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
                ApplicationArea = All;
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
                ApplicationArea = All;
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
                ApplicationArea = All;
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
                ApplicationArea = All;
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
            until SelectedADLSECompaniesTable.Next() < 1;
    end;

    var
        NoExportInProgress: Boolean;

        NumberFieldsChosenValue: Integer;

}
