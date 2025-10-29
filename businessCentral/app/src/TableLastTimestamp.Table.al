// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
table 82564 "ADLSE Table Last Timestamp"
{
    /// <summary>
    /// Keeps track of the last exported timestamps of different tables.
    /// <remarks>This table is not per company table as some of the tables it represents may not be data per company. Company name field has been added to differentiate them.</remarks>
    /// </summary>

    Access = Internal;
    Caption = 'ADLSE Table Last Timestamp';
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

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Table Last Timestamp", 'r')]
    procedure ExistsUpdatedLastTimestamp(TableID: Integer): Boolean
    begin
        exit(Rec.Get(GetCompanyNameToLookFor(TableID), TableID));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Table", 'r')]
    procedure GetUpdatedLastTimestamp(TableID: Integer): BigInteger
    var
        ADLSETable: Record "ADLSE Table";
        InitialLoadStartDate: Date;
        MinTimestamp: BigInteger;
    begin
        if ExistsUpdatedLastTimestamp(TableID) then
            if Rec."Updated Last Timestamp" <> 0 then
                exit(Rec."Updated Last Timestamp");

        if ADLSETable.Get(TableID) then;
        if ADLSETable."Initial Load Start Date" = 0D then
            exit(0);

        InitialLoadStartDate := ADLSETable."Initial Load Start Date";
        MinTimestamp := GetMinTimestampFromDate(TableID, InitialLoadStartDate);
        if MinTimestamp > 0 then
            exit(MinTimestamp);

        exit(0);
    end;

    local procedure GetMinTimestampFromDate(TableID: Integer; StartDate: Date): BigInteger
    var
        RecordRef: RecordRef;
        TimestampFieldRef: FieldRef;
        ModifiedAtFieldRef: FieldRef;
        MinTimestamp: BigInteger;
        FilterDateTime: DateTime;
    begin
        RecordRef.Open(TableID);
        FilterDateTime := CreateDateTime(StartDate, 0T);

        ModifiedAtFieldRef := RecordRef.Field(RecordRef.SystemModifiedAtNo());
        ModifiedAtFieldRef.SetFilter('>=%1', FilterDateTime);

        if RecordRef.FindFirst() then begin
            TimestampFieldRef := RecordRef.Field(0);
            MinTimestamp := TimestampFieldRef.Value();
        end else begin
            RecordRef.Reset();
            ModifiedAtFieldRef := RecordRef.Field(RecordRef.SystemModifiedAtNo());
            ModifiedAtFieldRef.SetFilter('<%1', FilterDateTime);

            if RecordRef.FindLast() then begin
                TimestampFieldRef := RecordRef.Field(0);
                MinTimestamp := TimestampFieldRef.Value();
            end;
        end;

        RecordRef.Close();
        exit(MinTimestamp);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Table Last Timestamp", 'r')]
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

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Table Last Timestamp", 'rmi')]
    local procedure RecordLastTimestamp(TableID: Integer; Timestamp: BigInteger; Upsert: Boolean): Boolean
#if not CLEAN27
    var
        ADLSETable: Record "ADLSE Table";
    begin
        if not ADLSETable.CheckIfNeedToCommitExternally(TableID) then
            exit(RecordLastTimestamp_InCurrSession(TableID, Timestamp, Upsert))
        else
            exit(RecordLastTimestamp_InBkgSession(TableID, Timestamp, Upsert));
    end;

    procedure RecordLastTimestamp_InCurrSession(TableID: Integer; Timestamp: BigInteger; Upsert: Boolean): Boolean
#endif
    var
        Company: Text;
    begin
        Company := GetCompanyNameToLookFor(TableID);
        if Rec.Get(Company, TableID) then begin
            ChangeLastTimestamp(Timestamp, Upsert);
            exit(Rec.Modify(true));
        end else begin
            Rec.Init();
            Rec."Company Name" := CopyStr(Company, 1, 30);
            Rec."Table ID" := TableID;
            ChangeLastTimestamp(Timestamp, Upsert);
            exit(Rec.Insert(true));
        end;
    end;

#if not CLEAN27
    local procedure RecordLastTimestamp_InBkgSession(TableID: Integer; Timestamp: BigInteger; Upsert: Boolean): Boolean
    var
        SessionInstruction: Record "Session Instruction";
        ParamsJson: JsonObject;
    begin
        SessionInstruction."Object Type" := SessionInstruction."Object Type"::Table;
        SessionInstruction."Object ID" := Database::"ADLSE Table Last Timestamp";
        SessionInstruction.Method := "ADLSE Session Method"::"Handle Last Timestamp Update";
        ParamsJson.Add('TableId', TableID);
        ParamsJson.Add('Timestamp', Timestamp);
        ParamsJson.Add('Upsert', Upsert);
        SessionInstruction.Params := Format(ParamsJson);
        SessionInstruction.ExecuteInNewSession();
        exit(true);
    end;
#endif

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