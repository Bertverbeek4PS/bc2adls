// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
page 82563 "ADLSE Run"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "ADLSE Run";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Caption = 'Execution logs for exports to Azure Data Lake Storage';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                ShowCaption = false;

                field("TableCaption"; NameOfTable)
                {
                    Caption = 'Table';
                    ToolTip = 'Specifies the caption of the table whose data was exported.';
                    Visible = not DisplayLogsForGivenTable;
                }

                field(State; Rec.State) { }

                field(Started; Rec.Started) { }

                field(Ended; Rec.Ended) { }
                field("Duration"; Rec.Duration())
                {
                    Caption = 'Duration';
                    ToolTip = 'Specifies how long export has run.';
                }
                field("Error"; Rec.Error) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Clear")
            {
                ApplicationArea = All;
                Caption = 'Clear execution log';
                ToolTip = 'Removes the history of the export executions. This should be done periodically to free up storage space.';
                Image = ClearLog;
                Enabled = LogsFound;

                trigger OnAction()
                var
                    ADLSERun: Record "ADLSE Run";
                begin
                    LogsFound := false;
                    ADLSERun.DeleteOldRuns(Rec."Table ID");
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnInit()
    begin
        Rec.SetRange("Company Name", CompanyName());
        Rec.SetCurrentKey(Started);
        Rec.SetAscending(Started, false); // the last log at the top
    end;

    trigger OnAfterGetRecord()
    var
        ADLSEUtil: Codeunit "ADLSE Util";
    begin
        NameOfTable := ADLSEUtil.GetTableCaption(Rec."Table ID");
        LogsFound := true;
    end;

    var
        NameOfTable: Text;
        DisplayLogsForGivenTable: Boolean;
        LogsFound: Boolean;


    internal procedure SetDisplayForTable(TableID: Integer)
    begin
        Rec.SetRange("Table ID", TableID);
        DisplayLogsForGivenTable := true;
    end;
}