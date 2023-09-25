// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
table 82564 "ADLSE Table Last Timestamp"
{
    /// <summary>
    /// Keeps track of the last exported timestamps of different tables.
    /// <remarks>This table is not per company table as some of the tables it represents may not be data per company. Company name field has been added to differentiate them.</remarks>
    /// </summary>

    Access = Internal;
    DataClassification = CustomerContent;
    DataPerCompany = false;

    fields
    {
        field(1; "Company Name"; Text[30])
        {
            Editable = false;
            Caption = 'Company name';
            TableRelation = Company.Name;
        }
        field(2; "Table ID"; Integer)
        {
            Editable = false;
            Caption = 'Table ID';
            TableRelation = "ADLSE Table"."Table ID";
        }
        field(3; "Updated Last Timestamp"; BigInteger)
        {
            Editable = false;
            Caption = 'Last timestamp exported for an updated record';
        }
        field(4; "Deleted Last Entry No."; BigInteger)
        {
            Editable = false;
            Caption = 'Entry no. of the last deleted record';
        }
    }

    keys
    {
        key(Key1; "Company Name", "Table ID")
        {
            Clustered = true;
        }
    }

    var
        SaveUpsertLastTimestampFailedErr: Label 'Could not save the last time stamp for the upserts on table %1.', Comment = '%1: table caption';
        SaveDeletionLastTimestampFailedErr: Label 'Could not save the last time stamp for the deletions on table %1.', Comment = '%1: table caption';

    procedure ExistsUpdatedLastTimestamp(TableID: Integer): Boolean
    begin
        exit(Rec.Get(GetCompanyNameToLookFor(TableID), TableID));
    end;

    procedure GetUpdatedLastTimestamp(TableID: Integer): BigInteger
    begin
        if ExistsUpdatedLastTimestamp(TableID) then
            exit(Rec."Updated Last Timestamp");
    end;

    procedure GetDeletedLastEntryNo(TableID: Integer): BigInteger
    begin
        if Rec.Get(GetCompanyNameToLookFor(TableID), TableID) then
            exit(Rec."Deleted Last Entry No.");
    end;

    procedure TrySaveUpdatedLastTimestamp(TableID: Integer; Timestamp: BigInteger; EmitTelemetry: Boolean) Result: Boolean
    var
        ADLSEExecution: Codeunit "ADLSE Execution";
        ADLSEUtil: Codeunit "ADLSE Util";
    begin
        Result := RecordUpsertLastTimestamp(TableID, Timestamp);
        if EmitTelemetry and (not Result) then
            ADLSEExecution.Log('ADLSE-032', StrSubstNo(SaveUpsertLastTimestampFailedErr, ADLSEUtil.GetTableCaption(TableID)), Verbosity::Error);
    end;

    procedure SaveUpdatedLastTimestamp(TableID: Integer; Timestamp: BigInteger)
    var
        ADLSEUtil: Codeunit "ADLSE Util";
    begin
        if not RecordUpsertLastTimestamp(TableID, Timestamp) then
            Error(SaveUpsertLastTimestampFailedErr, ADLSEUtil.GetTableCaption(TableID));
    end;

    local procedure RecordUpsertLastTimestamp(TableID: Integer; Timestamp: BigInteger): Boolean
    begin
        exit(RecordLastTimestamp(TableID, Timestamp, true));
    end;

    procedure TrySaveDeletedLastEntryNo(TableID: Integer; Timestamp: BigInteger; EmitTelemetry: Boolean) Result: Boolean
    var
        ADLSEExecution: Codeunit "ADLSE Execution";
        ADLSEUtil: Codeunit "ADLSE Util";
    begin
        Result := RecordDeletedLastTimestamp(TableID, Timestamp);
        if EmitTelemetry and (not Result) then
            ADLSEExecution.Log('ADLSE-033', StrSubstNo(SaveDeletionLastTimestampFailedErr, ADLSEUtil.GetTableCaption(TableID)), Verbosity::Error);
    end;

    procedure SaveDeletedLastEntryNo(TableID: Integer; Timestamp: BigInteger)
    var
        ADLSEUtil: Codeunit "ADLSE Util";
    begin
        if not RecordDeletedLastTimestamp(TableID, Timestamp) then
            Error(SaveDeletionLastTimestampFailedErr, ADLSEUtil.GetTableCaption(TableID));
    end;

    local procedure RecordDeletedLastTimestamp(TableID: Integer; Timestamp: BigInteger): Boolean
    begin
        exit(RecordLastTimestamp(TableID, Timestamp, false));
    end;

    local procedure RecordLastTimestamp(TableID: Integer; Timestamp: BigInteger; Upsert: Boolean): Boolean
    var
        Company: Text;
    begin
        Company := GetCompanyNameToLookFor(TableID);
        if Rec.Get(Company, TableID) then begin
            ChangeLastTimestamp(Timestamp, Upsert);
            exit(Rec.Modify());
        end else begin
            Rec.Init();
            Rec."Company Name" := CopyStr(Company, 1, 30);
            Rec."Table ID" := TableID;
            ChangeLastTimestamp(Timestamp, Upsert);
            exit(Rec.Insert());
        end;
    end;

    local procedure ChangeLastTimestamp(Timestamp: BigInteger; Upsert: Boolean)
    begin
        if Upsert then
            Rec."Updated Last Timestamp" := Timestamp
        else
            Rec."Deleted Last Entry No." := Timestamp;
    end;

    local procedure GetCompanyNameToLookFor(TableID: Integer): Text
    var
        ADLSEUtil: Codeunit "ADLSE Util";
    begin
        if ADLSEUtil.IsTablePerCompany(TableID) then
            exit(CurrentCompany());
        // else it remains blank
    end;
}