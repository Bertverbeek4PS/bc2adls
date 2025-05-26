// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
#pragma warning disable LC0015
table 82560 "ADLSE Setup"
#pragma warning restore
{
    Access = Internal;
    Caption = 'ADLSE Setup';
    DataClassification = CustomerContent;
    DataPerCompany = false;
    DataCaptionFields = Container;

    fields
    {
        field(1; "Primary Key"; Integer)
        {
            AllowInCustomizations = Always;
            Caption = 'Primary Key';
            Editable = false;
        }

        field(5; "Account Name"; Text[24])
        {
            Caption = 'Account Name';
            ToolTip = 'Specifies the name of the storage account.';

            trigger OnValidate()
            begin
                // Name constraints based on https://learn.microsoft.com/en-us/azure/storage/common/storage-account-overview#storage-account-name
                if (StrLen(Rec."Account Name") < 3) or (StrLen(Rec."Account Name") > 24) // between 3 and 24 characters long
                    or TextCharactersOtherThan(Rec."Account Name", 'abcdefghijklmnopqrstuvwxyz1234567890') // only made of lower case letters and numerals
                then
                    Error(AccountNameIncorrectFormatErr);
            end;
        }

        field(2; Container; Text[63])
        {
            Caption = 'Container';
            ToolTip = 'Specifies the name of the container where the data is going to be uploaded. Please refer to constraints on container names at https://docs.microsoft.com/en-us/rest/api/storageservices/naming-and-referencing-containers--blobs--and-metadata.';

            trigger OnValidate()
            begin
                // Name constraints based on https://docs.microsoft.com/en-us/rest/api/storageservices/naming-and-referencing-containers--blobs--and-metadata
                if (StrLen(Container) < 3) or (StrLen(Container) > 63) // between 6 and 63 characters long
                    or TextCharactersOtherThan(Container, 'abcdefghijklmnopqrstuvwxyz1234567890-') // only made of lower case letters, numerals and dashes
                    or (StrPos(Container, '--') <> 0) // no occurence of multiple dashes together
                then
                    Error(ContainerNameIncorrectFormatErr);
            end;
        }

        field(3; MaxPayloadSizeMiB; Integer)
        {
            Caption = 'Max payload size (MiBs)';
            ToolTip = 'Specifies the maximum size of the upload for each block of data in MiBs. A large value will reduce the number of iterations to upload the data but may interfear with the performance of other processes running on this environment.';
            InitValue = 4;
            // Refer max limit for put block calls (https://docs.microsoft.com/en-us/rest/api/storageservices/put-block#remarks)
            MaxValue = 4000;
            MinValue = 1;
        }

        field(4; DataFormat; Enum "ADLSE CDM Format")
        {
            Caption = 'CDM data format';
            ToolTip = 'Specifies the format in which to store the exported data in the ''data'' CDM folder. The Parquet format is recommended for storing the data with the best fidelity.';
            InitValue = Parquet;
        }

        field(10; Running; Boolean)
        {
            Caption = 'Exporting data';
            Editable = false;
            ObsoleteReason = 'Use ADLSE Current Session::AreAnySessionsActive() instead';
            ObsoleteTag = '1.2.2.0';
            ObsoleteState = Removed;
        }

        field(11; "Emit telemetry"; Boolean)
        {
            Caption = 'Emit telemetry';
            InitValue = true;
            ToolTip = 'Specifies if operational telemetry will be emitted to this extension publisher''s telemetry pipeline. You will have to configure a telemetry account for this extension first.';
        }

        field(15; "Multi- Company Export"; Boolean)
        {
            Caption = 'Multi- company export';
            InitValue = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'Schema update and export of data is now seperated.';

            trigger OnValidate()
            var
                ADLSECurrentSession: Record "ADLSE Current Session";
            begin
                if Rec."Multi- Company Export" = xRec."Multi- Company Export" then
                    exit;

                // ensure that no current export sessions running
                ADLSECurrentSession.CheckForNoActiveSessions();
            end;
        }

        field(20; "Skip Timestamp Sorting On Recs"; Boolean)
        {
            Caption = 'Skip row version sorting';
            InitValue = false;
            ToolTip = 'Specifies that the records are not sorted as per their row version before exporting them to the lake. Enabling this may interfear with how incremental data is pushed to the lake in subsequent export runs- please refer to the documentation.';
        }

        field(25; "Storage Type"; Enum "ADLSE Storage Type")
        {
            Caption = 'Storage type';
            ToolTip = 'Specifies the type of storage type to use.';

            trigger OnValidate()
            var
                OpenMirroringPreviewLbl: label 'Microsoft Fabric - Open Mirroring connection in bc2adls is still in preview. Please use it with caution.';
            begin
                if Rec."Storage Type" = Rec."Storage Type"::"Open Mirroring" then
                    Message(OpenMirroringPreviewLbl);
            end;
        }

        field(30; Workspace; Text[100])
        {
            Caption = 'Workspace';
            ToolTip = 'Specifies the name of the Workspace where the data is going to be uploaded. This can be a name or a GUID.';
            trigger OnValidate()
            var
                ValidGuid: Guid;
            begin
                if not Evaluate(ValidGuid, Rec.Workspace) then
                    if (StrLen(Rec.Workspace) < 3) or (StrLen(Rec.Workspace) > 24)
                        or TextCharactersOtherThan(Rec.Workspace, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_')
                    then
                        Error(WorkspaceIncorrectFormatErr);
            end;
        }
        field(31; Lakehouse; Text[100])
        {
            Caption = 'Lakehouse';
            ToolTip = 'Specifies the name of the Lakehouse where the data is going to be uploaded. This can be a name or a GUID.';
            trigger OnValidate()
            var
                ValidGuid: Guid;
            begin
                if not Evaluate(ValidGuid, Rec.Lakehouse) then
                    if (StrLen(Rec.Lakehouse) < 3) or (StrLen(Rec.Lakehouse) > 24)
                        or TextCharactersOtherThan(Rec.Lakehouse, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_')
                    then
                        Error(LakehouseIncorrectFormatErr);
            end;
        }
        field(32; LandingZone; Text[250])
        {
            Caption = 'Landing Zone';
            ToolTip = 'Specifies the name of the Landing Zone where the data is going to be uploaded. This Landing Zone you can find at the Replication Status page in Microsoft Fabric.';
        }
        field(35; "Schema Exported On"; DateTime)
        {
            AllowInCustomizations = Always;
            Caption = 'Schema exported on';
        }
        field(40; "Translations"; Text[250])
        {
            Caption = 'Translations';
            ToolTip = 'Specifies the translations for the enums used in the selected tables.';
        }
        field(45; "Export Enum as Integer"; Boolean)
        {
            Caption = 'Export Enum as Integer';
            ToolTip = 'Specifies if the enums will be exported as integers instead of strings. This is useful if you want to use the enums in Power BI.';
            trigger OnValidate()
            begin
                if Rec."Schema Exported On" <> 0DT then
                    Error(ErrorInfo.Create(SchemaAlreadyExportedErr, true));
            end;
        }
        field(50; "Delete Table"; Boolean)
        {
            Caption = 'Delete table';
            ToolTip = 'Specifies if the table will be deleted if a reset of the table is done.';
        }
        field(55; "Maximum Retries"; Integer)
        {
            AllowInCustomizations = Always;
            Caption = 'Maximum retries';
            InitValue = 0;

            trigger OnValidate()
            begin
                if Rec."Maximum Retries" > 10 then begin
                    MaxReqErrorInfo.DataClassification := DataClassification::SystemMetadata;
                    MaxReqErrorInfo.ErrorType := ErrorType::Client;
                    MaxReqErrorInfo.Verbosity := Verbosity::Error;
                    MaxReqErrorInfo.Message := MaximumRetriesErr;
                    Error(MaxReqErrorInfo);
                end;
            end;
        }
        field(60; "Delivered DateTime"; Boolean)
        {
            Caption = 'Add delivered DateTime';
            ToolTip = 'Specifies if the column DeliveredDateTime will be added to the CSV export file.';
        }
        //Add field for lookup to table companies
        field(65; "Export Company Database Tables"; Text[30])
        {
            Caption = 'Export Company Database Tables';
            ToolTip = 'Specifies the company for the export of the database tables.';
            TableRelation = Company.Name;


        }
        field(70; "Delayed Export"; Integer)
        {
            Caption = 'Delayed Export';
            ToolTip = 'Specifies the delayed export time in seconds (0 = No delay).';
            InitValue = 0;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    var
        MaxReqErrorInfo: ErrorInfo;
        ContainerNameIncorrectFormatErr: Label 'The container name is in an incorrect format. Please only use abcdefghijklmnopqrstuvwxyz1234567890_';
        AccountNameIncorrectFormatErr: Label 'The account name is in an incorrect format. Please only use abcdefghijklmnopqrstuvwxyz1234567890';
        WorkspaceIncorrectFormatErr: Label 'The workspace is in an incorrect format. Please only use abcdefghijklmnopqrstuvwxyz1234567890_ or a valid GUID';
        LakehouseIncorrectFormatErr: Label 'The lakehouse is in an incorrect format. Please only use abcdefghijklmnopqrstuvwxyz1234567890_ or a valid GUID';
        RecordDoesNotExistErr: Label 'No record on this table exists.';
        PrimaryKeyValueLbl: Label '0', Locked = true;
        SchemaAlreadyExportedErr: Label 'Schema already exported. Please perform the action "clear schema export date" before changing the schema.';
        MaximumRetriesErr: Label 'Please enter a value that is equal or smaller than 10 for the maximum retries.';
        NoSchemaExportedErr: Label 'No schema has been exported yet. Please export schema first before exporting the data.';

    local procedure TextCharactersOtherThan(String: Text; CharString: Text): Boolean
    var
        Index: Integer;
        Letter: Text;
    begin
        for Index := 1 to StrLen(String) do begin
            Letter := CopyStr(String, Index, 1);
            if StrPos(CharString, Letter) = 0 then
                exit(true);
        end;
    end;

    procedure GetSingleton()
    begin
        if not Exists() then
            Error(RecordDoesNotExistErr);
    end;

    procedure GetOrCreate()
    begin
        if Exists() then
            exit;
        "Primary Key" := GetPrimaryKeyValue();
        Insert();
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Setup", 'r')]
    procedure Exists(): Boolean
    begin
        exit(Rec.Get(GetPrimaryKeyValue()));
    end;

    local procedure GetPrimaryKeyValue() PKValue: Integer
    begin
        Evaluate(PKValue, PrimaryKeyValueLbl, 9);
    end;

    procedure GetStorageType(): Enum "ADLSE Storage Type"
    begin
        Rec.GetSingleton();
        exit(Rec."Storage Type");
    end;

    procedure SchemaExported()
    begin
        Rec.GetSingleton();
        if Rec."Schema Exported On" <> 0DT then
            Error(ErrorInfo.Create(SchemaAlreadyExportedErr, true));
    end;

    procedure CheckSchemaExported()
    begin
        Rec.GetSingleton();
        if Rec."Schema Exported On" = 0DT then
            Error(NoSchemaExportedErr);
    end;
}