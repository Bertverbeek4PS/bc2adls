// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
page 82560 "ADLSE Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "ADLSE Setup";
    InsertAllowed = false;
    DeleteAllowed = false;
    Caption = 'Export to Azure Data Lake Storage';

    layout
    {
        area(Content)
        {
            group(Setup)
            {
                Caption = 'Setup';
                group(Account)
                {
                    Caption = 'Account';
                    field(Container; Rec.Container)
                    {
                        ApplicationArea = All;
                        Tooltip = 'Specifies the name of the container where the data is going to be uploaded. Please refer to constraints on container names at https://docs.microsoft.com/en-us/rest/api/storageservices/naming-and-referencing-containers--blobs--and-metadata.';
                    }
                    field("Tenant ID"; StorageTenantID)
                    {
                        ApplicationArea = All;
                        Caption = 'Tenant ID';
                        Tooltip = 'Specifies the tenant ID which holds the app registration as well as the storage account. Note that they have to be on the same tenant.';

                        trigger OnValidate()
                        begin
                            ADLSECredentials.SetTenantID(StorageTenantID);
                        end;
                    }
                    field(AccountName; StorageAccount)
                    {
                        ApplicationArea = All;
                        Caption = 'Account name';
                        Tooltip = 'Specifies the name of the storage account.';

                        trigger OnValidate()
                        begin
                            ADLSECredentials.SetStorageAccount(StorageAccount);
                        end;
                    }
                }
                group(Access)
                {
                    Caption = 'App registration';
                    field("Client ID"; ClientID)
                    {
                        Caption = 'Client ID';
                        ApplicationArea = All;
                        ExtendedDatatype = Masked;
                        Tooltip = 'Specifies the application client ID for the Azure App Registration that accesses the storage account.';

                        trigger OnValidate()
                        begin
                            ADLSECredentials.SetClientID(ClientID);
                        end;
                    }
                    field("Client secret"; ClientSecret)
                    {
                        Caption = 'Client secret';
                        ApplicationArea = All;
                        ExtendedDatatype = Masked;
                        Tooltip = 'Specifies the client secret for the Azure App Registration that accesses the storage account.';

                        trigger OnValidate()
                        begin
                            ADLSECredentials.SetClientSecret(ClientSecret);
                        end;
                    }
                }
                group(Execution)
                {
                    Caption = 'Execution';
                    field(MaxPayloadSize; Rec.MaxPayloadSizeMiB)
                    {
                        ApplicationArea = All;
                        Tooltip = 'Specifies the maximum size of the upload for each block of data in MiBs. A large value will reduce the number of iterations to upload the data but may interfear with the performance of other processes running on this environment.';
                    }

                    field("CDM data format"; Rec.DataFormat)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the format in which to store the exported data in the ''data'' CDM folder. The Parquet format is recommended for storing the data with the best fidelity.';
                    }

                    field("Multi- Company Export"; Rec."Multi- Company Export")
                    {
                        ApplicationArea = All;
                        Enabled = not ExportInProgress;
                        ToolTip = 'Specifies if simultaneous exports of data from different companies in Business Central to the lake are allowed. Beware that setting this checkmark will prevent you from making any changes to the export schema. It is recommended that you set this checkmark only after the last changes to the CDM schema have been exported to the lake successfully. Enabling this field does not export data from other companies in the environment- to do that the export process needs to be started from within those companies.';
                    }

                    field("Skip Timestamp Sorting On Recs"; Rec."Skip Timestamp Sorting On Recs")
                    {
                        ApplicationArea = All;
                        Enabled = not ExportInProgress;
                        ToolTip = 'Specifies that the records are not sorted as per their row version before exporting them to the lake. Enabling this may interfear with how incremental data is pushed to the lake in subsequent export runs- please refer to the documentation.';
                    }

                    field("Emit telemetry"; Rec."Emit telemetry")
                    {
                        ApplicationArea = All;
                        Tooltip = 'Specifies if operational telemetry will be emitted to this extension publisher''s telemetry pipeline. You will have to configure a telemetry account for this extension first.';
                    }

                }
            }
            part(Tables; "ADLSE Setup Tables")
            {
                ApplicationArea = All;
                UpdatePropagation = Both;
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
                Caption = 'Export';
                Tooltip = 'Starts the export process by spawning different sessions for each table. The action is disabled in case there are export processes currently running, also in other companies.';
                Image = Start;
                Enabled = not ExportInProgress;

                trigger OnAction()
                var
                    ADLSEExecution: Codeunit "ADLSE Execution";
                begin
                    ADLSEExecution.StartExport();
                    CurrPage.Update();
                end;
            }

            action(StopExport)
            {
                ApplicationArea = All;
                Caption = 'Stop export';
                Tooltip = 'Tries to stop all sessions that are exporting data, including those that are running in other companies.';
                Image = Stop;

                trigger OnAction()
                var
                    ADLSEExecution: Codeunit "ADLSE Execution";
                begin
                    ADLSEExecution.StopExport();
                    CurrPage.Update();
                end;
            }

            action(Schedule)
            {
                ApplicationArea = All;
                Caption = 'Schedule export';
                Tooltip = 'Schedules the export process as a job queue entry.';
                Image = Timesheet;

                trigger OnAction()
                var
                    ADLSEExecution: Codeunit "ADLSE Execution";
                begin
                    ADLSEExecution.ScheduleExport();
                end;
            }

            action(ClearDeletedRecordsList)
            {
                ApplicationArea = All;
                Caption = 'Clear tracked deleted records';
                Tooltip = 'Removes the entries in the deleted record list that have already been exported. This should be done periodically to free up storage space. The codeunit ADLSE Clear Tracked Deletions may be invoked using a job queue entry for the same end.';
                Image = ClearLog;
                Enabled = TrackedDeletedRecordsExist;

                trigger OnAction()
                begin
                    Codeunit.Run(Codeunit::"ADLSE Clear Tracked Deletions");
                    CurrPage.Update();
                end;
            }

            action(DeleteOldRuns)
            {
                ApplicationArea = All;
                Caption = 'Clear execution log';
                Tooltip = 'Removes the history of the export executions. This should be done periodically to free up storage space.';
                Image = History;
                Enabled = OldLogsExist;

                trigger OnAction()
                var
                    ADLSERun: Record "ADLSE Run";
                begin
                    ADLSERun.DeleteOldRuns();
                    CurrPage.Update();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                group(Export)
                {
                    ShowAs = SplitButton;
                    actionref(ExportNow_Promoted; ExportNow) { }
                    actionref(Schedule_Promoted; Schedule) { }
                    actionref(StopExport_Promoted; StopExport) { }
                }
                actionref(ClearDeletedRecordsList_Promoted; ClearDeletedRecordsList) { }
                actionref(DeleteOldRuns_Promoted; DeleteOldRuns) { }
            }
        }
    }

    var
        ClientSecretLbl: Label 'Secret not shown';
        ClientIdLbl: Label 'ID not shown';

    trigger OnInit()
    begin
        Rec.GetOrCreate();
        ADLSECredentials.Init();
        StorageTenantID := ADLSECredentials.GetTenantID();
        StorageAccount := ADLSECredentials.GetStorageAccount();
        if ADLSECredentials.IsClientIDSet() then
            ClientID := ClientIdLbl;
        if ADLSECredentials.IsClientSecretSet() then
            ClientSecret := ClientSecretLbl;
    end;

    trigger OnAfterGetRecord()
    var
        ADLSEDeletedRecord: Record "ADLSE Deleted Record";
        ADLSECurrentSession: Record "ADLSE Current Session";
        ADLSERun: Record "ADLSE Run";
    begin
        ExportInProgress := ADLSECurrentSession.AreAnySessionsActive();
        TrackedDeletedRecordsExist := not ADLSEDeletedRecord.IsEmpty();
        OldLogsExist := ADLSERun.OldRunsExist();
        UpdateNotificationIfAnyTableExportFailed();
    end;

    var
        ADLSECredentials: Codeunit "ADLSE Credentials";
        TrackedDeletedRecordsExist: Boolean;
        ExportInProgress: Boolean;
        [NonDebuggable]
        StorageTenantID: Text;
        [NonDebuggable]
        StorageAccount: Text;
        [NonDebuggable]
        ClientID: Text;
        [NonDebuggable]
        ClientSecret: Text;
        OldLogsExist: Boolean;
        FailureNotificationID: Guid;
        ExportFailureNotificationMsg: Label 'Data from one or more tables failed to export on the last run. Please check the tables below to see the error(s).';

    local procedure UpdateNotificationIfAnyTableExportFailed()
    var
        ADLSETable: Record "ADLSE Table";
        ADLSERun: Record "ADLSE Run";
        FailureNotification: Notification;
        Status: enum "ADLSE Run State";
        LastStarted: DateTime;
        ErrorIfAny: Text[2048];
    begin
        if ADLSETable.FindSet() then
            repeat
                ADLSERun.GetLastRunDetails(ADLSETable."Table ID", Status, LastStarted, ErrorIfAny);
                if Status = "ADLSE Run State"::Failed then begin
                    FailureNotification.Message := ExportFailureNotificationMsg;
                    FailureNotification.Scope := NotificationScope::LocalScope;

                    if IsNullGuid(FailureNotificationID) then
                        FailureNotificationID := CreateGuid();
                    FailureNotification.Id := FailureNotificationID;

                    FailureNotification.Send();
                    exit;
                end;
            until ADLSETable.Next() = 0;

        // no failures- recall notification
        if not IsNullGuid(FailureNotificationID) then begin
            FailureNotification.Id := FailureNotificationID;
            FailureNotification.Recall();
            Clear(FailureNotificationID);
        end;
    end;
}