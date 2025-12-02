// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
#pragma warning disable LC0015
table 80039 "ADLSE Setup"
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
            Caption = 'Primary Key';
            Editable = false;
        }

        field(5; "Account Name"; Text[24])
        {
            Caption = 'Account Name';

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
            InitValue = 4;
            // Refer max limit for put block calls (https://docs.microsoft.com/en-us/rest/api/storageservices/put-block#remarks)
            MaxValue = 4000;
            MinValue = 1;
        }

        field(4; DataFormat; Enum "ADLSE CDM Format")
        {
            Caption = 'CDM data format';
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
        }

        field(25; "Storage Type"; Enum "ADLSE Storage Type")
        {
            Caption = 'Storage type';

            trigger OnValidate()
            var
                OpenMirroringPreviewLbl: label 'Microsoft Fabric - Open Mirroring connection in bc2adls is still in preview. Please use it with caution.';
            begin
                if Rec."Storage Type" = Rec."Storage Type"::"Open Mirroring" then begin
                    Rec."Delete Table" := true;
                    Message(OpenMirroringPreviewLbl);
                end;
            end;
        }

        field(30; Workspace; Text[100])
        {
            Caption = 'Workspace';
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
        }
        field(35; "Schema Exported On"; DateTime)
        {
            Caption = 'Schema exported on';
        }
        field(40; Translations; Text[2048])
        {
            Caption = 'Translations';
        }
        field(45; "Export Enum as Integer"; Boolean)
        {
            Caption = 'Export Enum as Integer';
            trigger OnValidate()
            begin
                if Rec."Schema Exported On" <> 0DT then
                    Error(ErrorInfo.Create(SchemaAlreadyExportedErr, true));
            end;
        }
        field(50; "Delete Table"; Boolean)
        {
            Caption = 'Delete Table';
        }
        field(55; "Maximum Retries"; Integer)
        {
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
        }
        //Add field for lookup to table companies
        field(65; "Export Company Database Tables"; Text[30])
        {
            Caption = 'Export Company Database Tables';
            TableRelation = Company.Name;


        }
        field(70; "Delayed Export"; Integer)
        {
            Caption = 'Delayed Export';
            InitValue = 0;
        }
        field(75; "Use Field Captions"; Boolean)
        {
            Caption = 'Use Field Captions';
            InitValue = false;
        }
        field(80; "Use IDs for Duplicates Only"; Boolean)
        {
            Caption = 'IDs for Duplicates Only';
            InitValue = false;
        }
        field(95; "Use Table Captions"; Boolean)
        {
            Caption = 'Use Table Captions';
            InitValue = false;
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
    var
        FixitErrorInfo: ErrorInfo;
        ClearSchemaExportDateLbl: Label 'Clear schema export date';
    begin
        Rec.GetSingleton();
        if Rec."Schema Exported On" <> 0DT then begin
            FixitErrorInfo := ErrorInfo.Create(SchemaAlreadyExportedErr, true);
            FixitErrorInfo.AddAction(
                ClearSchemaExportDateLbl,
                Codeunit::"ADLSE Execution",
                'ClearSchemaExportedOn'
            );
            Error(FixitErrorInfo);
        end;
    end;

    procedure CheckSchemaExported()
    begin
        Rec.GetSingleton();
        if Rec."Schema Exported On" = 0DT then
            Error(NoSchemaExportedErr);
    end;
}