report 82561 "ADLSE Schedule Task Assignment"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Schedule Execution WRP Tables';
    ProcessingOnly = true;


    dataset
    {
        dataitem(ADLSETable; "ADLSE Table")
        {
            RequestFilterFields = "Table ID", ExportCategory, Enabled;
            trigger OnPreDataItem()
            var
                ADLSEExecution: Codeunit "ADLSE Execution";
            begin
                ADLSEExecution.StartExport(ADLSETable);
            end;
        }
    }
    requestpage
    {
        SaveValues = true;
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(JobQueueDescription; Description)
                    {
                        ApplicationArea = All;
                        Caption = 'Description';
                        ToolTip = 'The description that is displayed in the job queue.';
                    }
                    field(EarliestStartDateTimeControl; EarliestStartDateTime)
                    {
                        ApplicationArea = All;
                        Caption = 'Earliest Start Dqate / Time ';
                        ToolTip = 'The date and time when the job queue must be executed for the first time.';
                    }
                    field(NoofMinutesBetweeenRuns; NoofMinutesBetweenRuns)
                    {
                        ApplicationArea = All;
                        Caption = 'No of minutes between runs';
                        ToolTip = 'Specifies the minimum number of minutes that are to elapse between runs of a job queue entry. The value cannot be less than one minute.';
                    }
                }

                group(Recurrence)
                {
                    grid(Daysgrid)
                    {
                        Caption = 'Recurrence';
                        group(Recurrence1)
                        {
                            ShowCaption = false;
                            field(RunOnMondaysControl; RunOnMondays)
                            {
                                ApplicationArea = All;
                                Caption = 'RunOnMondays';
                                ToolTip = 'Specifies that the job queue entry runs on Mondays.';
                            }
                            field(RunOnTeusdaysControl; RunOnTeusdays)
                            {
                                ApplicationArea = All;
                                Caption = 'RunOnTeusdays';
                                ToolTip = 'Specifies that the job queue entry runs on Teusdays.';
                            }
                            field(RunOnWednesdayControl; RunOnWednesday)
                            {
                                ApplicationArea = All;
                                Caption = 'RunOnWednesday';
                                ToolTip = 'Specifies that the job queue entry runs on Wednesdays.';
                            }
                            field(RunOnThursdayControl; RunOnThursday)
                            {
                                ApplicationArea = All;
                                Caption = 'RunOnThursday';
                                ToolTip = 'Specifies that the job queue entry runs on Thursdays.';
                            }
                        }
                        group(Recurrence2)
                        {
                            ShowCaption = false;
                            field(RunOnFridayControl; RunOnFriday)
                            {
                                ApplicationArea = All;
                                Caption = 'RunOnFriday';
                                ToolTip = 'Specifies that the job queue entry runs on Fridays.';
                            }
                            field(RunOnSaturdayControl; RunOnSaturday)
                            {
                                ApplicationArea = All;
                                Caption = 'RunOnSaturday';
                                ToolTip = 'Specifies that the job queue entry runs on Saturdays.';
                            }
                            field(RunOnSundaysControl; RunOnSundays)
                            {
                                ApplicationArea = All;
                                Caption = 'RunOnSundays';
                                ToolTip = 'Specifies that the job queue entry runs on Sundays.';
                            }
                        }
                    }
                }
            }
        }

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin

        end;

        trigger OnOpenPage()
        begin

        end;
    }

    var
        Description: Text[30];
        JobCategoryCodeTxt: Label 'ADLSE', Locked = true;
        EarliestStartDateTime: DateTime;
        NoofMinutesBetweenRuns: Integer;
        RunOnSundays: Boolean;
        RunOnMondays: Boolean;
        RunOnTeusdays: Boolean;
        RunOnWednesday: Boolean;
        RunOnThursday: Boolean;
        RunOnFriday: Boolean;
        RunOnSaturday: Boolean;


    trigger OnInitReport()
    begin

    end;

    trigger OnPreReport()
    begin

    end;

    trigger OnPostReport()
    begin

    end;

    procedure CreateJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry")
    var
        JobQueueCategory: Record "Job Queue Category";
    begin
        Clear(JobQueueEntry);
        JobQueueCategory.InsertRec(JobCategoryCodeTxt, Description);
        JobQueueEntry.Init();
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry.Description := Description;
        JobQueueEntry."No. of Minutes between Runs" := NoofMinutesBetweenRuns;
        JobQueueEntry."Run on Mondays" := RunOnMondays;
        JobQueueEntry."Run on Tuesdays" := RunOnTeusdays;
        JobQueueEntry."Run on Wednesdays" := RunOnWednesday;
        JobQueueEntry."Run on Thursdays" := RunOnThursday;
        JobQueueEntry."Run on Fridays" := RunOnFriday;
        JobQueueEntry."Run on Saturdays" := RunOnSaturday;
        JobQueueEntry."Run on Sundays" := RunOnSundays;
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Report;
        JobQueueEntry."Object ID to Run" := Report::"ADLSE Schedule Task Assignment";
        JobQueueEntry."Earliest Start Date/Time" := EarliestStartDateTime;
        JobQueueEntry."Report Output Type" := JobQueueEntry."Report Output Type"::"None (Processing only)";
        JobQueueEntry.Insert(true);
    end;
}

