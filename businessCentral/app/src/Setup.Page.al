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
                group(General)
                {
                    Caption = 'Account';
                    field(StorageType; Rec."Storage Type")
                    {
                        trigger OnValidate()
                        begin
                            CurrPage.Update(true);
                        end;
                    }
                    field("Tenant ID"; StorageTenantID)
                    {
                        Caption = 'Tenant ID';
                        ToolTip = 'Specifies the tenant ID which holds the app registration as well as the storage account. Note that they have to be on the same tenant.';

                        trigger OnValidate()
                        begin
                            ADLSECredentials.SetTenantID(StorageTenantID);
                        end;
                    }
                }

                group(Account)
                {
                    Caption = 'Azure Data Lake';
                    Editable = AzureDataLake;
                    field(Container; Rec.Container) { }
                    field(AccountName; Rec."Account Name") { }
                }
                group(MSFabric)
                {
                    Caption = 'Microsoft Fabric';
                    Editable = not AzureDataLake;
                    field(Workspace; Rec.Workspace)
                    {
                        Editable = not FabricOpenMirroring;
                    }
                    field(Lakehouse; Rec.Lakehouse)
                    {
                        Editable = not FabricOpenMirroring;
                    }
                    field(LandingZone; Rec.LandingZone)
                    {
                        Editable = FabricOpenMirroring;
                    }
                }
                group(Access)
                {
                    Caption = 'App registration';
                    field("Client ID"; ClientID)
                    {
                        Caption = 'Client ID';
                        ExtendedDatatype = Masked;
                        ToolTip = 'Specifies the application client ID for the Azure App Registration that accesses the storage account.';

                        trigger OnValidate()
                        begin
                            ADLSECredentials.SetClientID(ClientID);
                        end;
                    }
                    field("Client secret"; ClientSecret)
                    {
                        Caption = 'Client secret';
                        ExtendedDatatype = Masked;
                        ToolTip = 'Specifies the client secret for the Azure App Registration that accesses the storage account.';

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
                        Editable = AzureDataLake or FabricOpenMirroring;
                    }

                    field("CDM data format"; Rec.DataFormat)
                    {
                        Editable = AzureDataLake;
                    }

                    field("Skip Timestamp Sorting On Recs"; Rec."Skip Timestamp Sorting On Recs")
                    {
                        Enabled = not ExportInProgress;

                    }
                    field("Delayed Export"; Rec."Delayed Export")
                    {
                        Enabled = not ExportInProgress;

                    }
                    field("Emit telemetry"; Rec."Emit telemetry") { }
                    field("Translations"; Rec.Translations)
                    {


                        trigger OnAssistEdit()
                        var
                            Language: Record Language;
                            Languages: Page "Languages";
                            RecRef: RecordRef;
                        begin
                            Languages.LookupMode(true);
                            if Languages.RunModal() = Action::LookupOK then begin
                                Rec.Translations := '';
                                Languages.SetSelectionFilter(Language);
                                RecRef.GetTable(Language);

                                if Language.FindSet() then
                                    repeat
                                        if Language.Code <> '' then
                                            Rec.Translations += Language.Code + ';';
                                    until Language.Next() = 0;
                                //Remove last semicolon
                                Rec.Translations := CopyStr(CopyStr(Rec.Translations, 1, StrLen(Rec.Translations) - 1), 1, 250);
                                CurrPage.Update();
                            end;
                        end;
                    }
                    field("Export Enum as Integer"; Rec."Export Enum as Integer") { }
                    field("Use Field Captions"; Rec."Use Field Captions")
                    {
                    }
                    field("Use Table Captions"; Rec."Use Table Captions")
                    {
                    }
                    field("Use IDs for Duplicates Only"; Rec."Use IDs for Duplicates Only")
                    {
                    }
                    field("Delete Table"; Rec."Delete Table")
                    {
                        Editable = not FabricOpenMirroring;
                    }
                    field("Delivered DateTime"; Rec."Delivered DateTime") { }
                    field("Export Company Database Tables"; Rec."Export Company Database Tables")
                    {
                        Lookup = true;
                    }
                }
            }
            part(Tables; "ADLSE Setup Tables")
            {
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
                ToolTip = 'Starts the export process by spawning different sessions for each table. The action is disabled in case there are export processes currently running, also in other companies.';
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

            action(Schedule)
            {
                ApplicationArea = All;
                Caption = 'Schedule export';
                ToolTip = 'Schedules the export process as a job queue entry.';
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
                ToolTip = 'Removes the entries in the deleted record list that have already been exported. The codeunit ADLSE Clear Tracked Deletions may be invoked using a job queue entry for the same end.';
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
                ToolTip = 'Removes the history of the export executions. This should be done periodically to free up storage space.';
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

            action(FixIncorrectData)
            {
                ApplicationArea = All;
                Caption = 'Fix incorrect data';
                ToolTip = 'Fixes incorrect tables and fields in the setup. This should be done if you have deleted some tables and fields and you cannot disable them.';
                Image = Error;

                trigger OnAction()
                var
                    ADLSESetup: Codeunit "ADLSE Setup";
                begin
                    ADLSESetup.FixIncorrectData();
                end;
            }
        }
        area(Navigation)
        {
            action(EnumTranslations)
            {
                ApplicationArea = All;
                Caption = 'Enum translations';
                ToolTip = 'Show the translations for the enums used in the selected tables.';
                Image = Translations;
                RunObject = page "ADLSE Enum Translations";
            }
            action(DeletedTablesNotToSync)
            {
                ApplicationArea = All;
                Caption = 'Deleted tables not to sync';
                ToolTip = 'Shows all the tables that are specified not to be tracked for deletes.';
                Image = Delete;
                RunObject = page "Deleted Tables Not To Sync";
            }
            action("Job Queue")
            {
                Caption = 'Job Queue';
                ApplicationArea = All;
                ToolTip = 'Specifies the scheduled Job Queues for the export to Datalake.';
                Image = BulletList;
                trigger OnAction()
                var
                    JobQueueEntry: Record "Job Queue Entry";
                begin
                    JobQueueEntry.SetFilter("Object ID to Run", '%1|%2', Codeunit::"ADLSE Execution", Report::"ADLSE Schedule Task Assignment");
                    Page.Run(Page::"Job Queue Entries", JobQueueEntry);
                end;
            }
            action("Export Category")
            {
                Caption = 'Export Category';
                ApplicationArea = All;
                ToolTip = 'Specifies the Export Categories available for scheduling the export to Datalake.';
                Image = Export;
                RunObject = page "ADLSE Export Categories";
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
                    actionref(StopExport_Promoted; StopExport) { }
                    actionref(SchemaExport_Promoted; SchemaExport) { }
                    actionref(Schedule_Promoted; Schedule) { }
                    actionref(ClearSchemaExported_Promoted; ClearSchemaExported) { }
                }
                actionref(ClearDeletedRecordsList_Promoted; ClearDeletedRecordsList) { }
                actionref(DeleteOldRuns_Promoted; DeleteOldRuns) { }
            }
        }
    }

    var
        FabricOpenMirroring, AzureDataLake : Boolean;
        ClientSecretLbl: Label 'Secret not shown';
        ClientIdLbl: Label 'ID not shown';

    trigger OnInit()
    begin
        Rec.GetOrCreate();
        ADLSECredentials.Init();
        StorageTenantID := ADLSECredentials.GetTenantID();
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
        AzureDataLake := Rec."Storage Type" = Rec."Storage Type"::"Azure Data Lake";
        FabricOpenMirroring := Rec."Storage Type" = Rec."Storage Type"::"Open Mirroring";
    end;

    var
        ADLSECredentials: Codeunit "ADLSE Credentials";
        TrackedDeletedRecordsExist: Boolean;
        ExportInProgress: Boolean;
        [NonDebuggable]
        StorageTenantID: Text;
        [NonDebuggable]
        ClientID: Text;
        [NonDebuggable]
        ClientSecret: Text;
        OldLogsExist: Boolean;
        FailureNotificationID: Guid;
        ExportFailureNotificationMsg: Label 'Data from one or more tables failed to export on the last run. Please check the tables below to see the error(s).';

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Table", 'r')]
    local procedure UpdateNotificationIfAnyTableExportFailed()
    var
        ADLSETable: Record "ADLSE Table";
        ADLSERun: Record "ADLSE Run";
        FailureNotification: Notification;
        Status: Enum "ADLSE Run State";
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