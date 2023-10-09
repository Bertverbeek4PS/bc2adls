// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
table 82563 "ADLSE Deleted Record"
{
    Access = Internal;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Editable = false;
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Table ID"; Integer)
        {
            Editable = false;
            Caption = 'Table ID';
        }
        field(3; "System ID"; Guid)
        {
            Editable = false;
            Caption = 'System ID';
        }
        field(4; "Deletion Timestamp"; BigInteger)
        {
            Editable = false;
            Caption = 'Deletion Timestamp';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Table ID")
        {
        }
    }

    procedure TrackDeletedRecord(RecRef: RecordRef)
    var
        SystemIdField: FieldRef;
        TimestampField: FieldRef;
    begin
        if RecRef.IsTemporary() then
            exit;

        SystemIdField := RecRef.Field(RecRef.SystemIdNo());
        if IsNullGuid(SystemIdField.Value()) then
            exit;

        // Do not log a deletion if its for a record that is created after the last sync
        // TODO: This requires tracking the SystemModifiedAt of the last time stamp 
        // and those records being deleted that have a SystemCreatedAt equal to or 
        // greater than this value should be skipped. In case the deletion is being done 
        // while the app is running, ensure that the entry made will be for sure picked up
        // in the next run.   

        Init();
        "Table ID" := RecRef.Number;
        "System ID" := SystemIdField.Value();
        TimestampField := RecRef.Field(0);
        "Deletion Timestamp" := TimestampField.Value();
        "Deletion Timestamp" += 1; // to mark an update that is greater than the last time stamp on this record
        Insert();
    end;
}