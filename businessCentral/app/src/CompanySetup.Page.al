page 82566 "ADLSE Company Setup"
{
    Caption = 'Export Companies to Azure Data Lake Storage';
    ApplicationArea = all;
    UsageCategory = Lists;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "ADLSE Sync Companies";

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;

                field("Sync Company"; Rec."Sync Company")
                {
                    ToolTip = 'The company that is being Exported.';
                    ApplicationArea = All;
                }
            }
            part("Company Tables"; "ADLSE Company Setup Tables")
            {
                UpdatePropagation = Both;
                SubPageLink = "Sync Company" = field("Sync Company");
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ExportNow)
            {
                ApplicationArea = All;
                Caption = 'Export All Companies';
                ToolTip = 'Starts the export process by spawning different sessions for each table. The action is disabled in case there are export processes currently running, also in other companies.';
                Image = Start;
                trigger OnAction()
                var
                    NewSessionID: Integer;
                begin
                    Session.StartSession(NewSessionID, Codeunit::"ADLSE Multi Company Export");
                    CurrPage.Update();
                end;
            }
            action(ExportSelectedCompanyNow)
            {
                ApplicationArea = All;
                Caption = 'Export Selected Company';
                ToolTip = 'Starts the export process for the selected company.';
                Image = Start;
                trigger OnAction()
                var
                    // ADLSECompanySetupTable: Record "ADLSE Companies Table";
                    ADLSESyncCompanies: Record "ADLSE Sync Companies";
                    TempJobQueueEntry: Record "Job Queue Entry" temporary;
                    NewSessionID: Integer;
                    FilterString: Text;
                begin
                    SetSelectionFilter(ADLSESyncCompanies);
                    if ADLSESyncCompanies.FindSet() then
                        repeat
                            if not FilterString.Contains(ADLSESyncCompanies."Sync Company") then
                                if FilterString = '' then
                                    FilterString := ADLSESyncCompanies."Sync Company"
                                else
                                    FilterString := FilterString + '|' + ADLSESyncCompanies."Sync Company";
                        until ADLSESyncCompanies.Next() < 1;
                    TempJobQueueEntry.Init();
                    TempJobQueueEntry."Parameter String" := CopyStr(FilterString, 1, MaxStrLen(TempJobQueueEntry."Parameter String"));
                    TempJobQueueEntry.Insert(true);
                    Session.StartSession(NewSessionID, Codeunit::"ADLSE Multi Company Export", '', TempJobQueueEntry);
                    CurrPage.Update();
                end;
            }

            action(StopExport)
            {
                ApplicationArea = All;
                Caption = 'Stop export';
                ToolTip = 'Tries to stop all sessions that are exporting data, including those that are running in other companies.';
                Image = Stop;

                trigger OnAction()
                var
                    ADLSEExecution: Codeunit "ADLSE Execution";
                begin
                    ADLSEExecution.StopExport();
                    CurrPage.Update();
                end;
            }
            action(SchemaExport)
            {
                ApplicationArea = All;
                Caption = 'Schema export';
                ToolTip = 'This will export the schema of the tables selected in the setup to the lake. This is a one-time operation and should be done before the first export of data.';
                Image = Start;

                trigger OnAction()
                var
                    ADLSEExecution: Codeunit "ADLSE Execution";
                begin
                    ADLSEExecution.SchemaExport();
                    CurrPage.Update();
                end;
            }
            action(ClearSchemaExported)
            {
                ApplicationArea = All;
                Caption = 'Clear schema export date';
                ToolTip = 'This will clear the schema exported on field. If this is cleared you can change the schema and export it again.';
                Image = ClearLog;

                trigger OnAction()
                var
                    ADLSEExecution: Codeunit "ADLSE Execution";
                begin
                    ADLSEExecution.ClearSchemaExportedOn();
                    CurrPage.Update();
                end;
            }

            // action(Schedule)
            // {
            //     ApplicationArea = All;
            //     Caption = 'Schedule export';
            //     ToolTip = 'Schedules the export process as a job queue entry.';
            //     Image = Timesheet;

            //     trigger OnAction()
            //     var
            //         ADLSEExecution: Codeunit "ADLSE Execution";
            //     begin
            //         ADLSEExecution.ScheduleExport();
            //     end;
            // }

            action(ClearDeletedRecordsList)
            {
                ApplicationArea = All;
                Caption = 'Clear tracked deleted records';
                ToolTip = 'Removes the entries in the deleted record list that have already been exported. The codeunit ADLSE Clear Tracked Deletions may be invoked using a job queue entry for the same end.';
                Image = ClearLog;

                trigger OnAction()
                var
                    ADLSEDeletedRecord: Record "ADLSE Deleted Record";
                    NewSessionID: Integer;
                begin
                    if Rec.FindSet() then
                        repeat
                            if ADLSEDeletedRecord.ChangeCompany(Rec."Sync Company") then
                                if not ADLSEDeletedRecord.IsEmpty() then
                                    Session.StartSession(NewSessionID, Codeunit::"ADLSE Clear Tracked Deletions", Rec."Sync Company");
                        until Rec.Next() < 1;
                    // Codeunit.Run(Codeunit::"ADLSE Clear Tracked Deletions");
                    CurrPage.Update();
                end;
            }
        }
        // area(Navigation)
        // {
        //     action("Job Queue")
        //     {
        //         Caption = 'Job Queue';
        //         ApplicationArea = All;
        //         ToolTip = 'Specifies the scheduled Job Queues for the export to Datalake.';
        //         Image = BulletList;
        //         trigger OnAction()
        //         var
        //             JobQueueEntry: Record "Job Queue Entry";
        //         begin
        //             JobQueueEntry.ChangeCompany(Rec."Sync Company");
        //             JobQueueEntry.SetFilter("Object ID to Run", '%1|%2', Codeunit::"ADLSE Execution", Report::"ADLSE Schedule Task Assignment");
        //             Page.Run(Page::"Job Queue Entries", JobQueueEntry);
        //         end;
        //     }
        //     action("Export Category")
        //     {
        //         Caption = 'Export Category';
        //         ApplicationArea = All;
        //         ToolTip = 'Specifies the Export Categories available for scheduling the export to Datalake.';
        //         Image = Export;
        //         RunObject = page "ADLSE Export Categories";
        //     }
        // }
        // area(Promoted)
        // {
        //     group(Category_Process)
        //     {
        //         Caption = 'Process';

        //         group(Export)
        //         {
        //             ShowAs = SplitButton;
        //             actionref(ExportNow_Promoted; ExportNow) { }
        //             actionref(StopExport_Promoted; StopExport) { }
        //             actionref(SchemaExport_Promoted; SchemaExport) { }
        //             // actionref(Schedule_Promoted; Schedule) { }
        //             actionref(ClearSchemaExported_Promoted; ClearSchemaExported) { }
        //         }
        //         actionref(ClearDeletedRecordsList_Promoted; ClearDeletedRecordsList) { }
        //     }
        // }
    }

}
