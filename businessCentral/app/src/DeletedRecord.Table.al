// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
#pragma warning disable LC0015
table 82563 "ADLSE Deleted Record"
#pragma warning restore
{
    Access = Internal;
    Caption = 'ADLSE Deleted Record';
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

    procedure TrackDeletedRecord(RecordRef: RecordRef)
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSEUtil: Codeunit "ADLSE Util";
        SystemIdFieldRef: FieldRef;
        TimestampFieldRef: FieldRef;
    begin
        if RecordRef.IsTemporary() then
            exit;

        if RecordRef.CurrentCompany() <> CompanyName() then //workarround for records which are deleted usings changecompany
            Rec.ChangeCompany(RecordRef.CurrentCompany());

        SystemIdFieldRef := RecordRef.Field(RecordRef.SystemIdNo());
        if IsNullGuid(SystemIdFieldRef.Value()) then
            exit;

        //Handle deletes in table on tenant level and deleted in another company
        if not ADLSEUtil.IsTablePerCompany(RecordRef.Number()) then begin
            ADLSESetup.GetSingleton();
            ChangeCompany(ADLSESetup."Export Company Database Tables");
        end;

        // Do not log a deletion if its for a record that is created after the last sync
        // TODO: This requires tracking the SystemModifiedAt of the last time stamp 
        // and those records being deleted that have a SystemCreatedAt equal to or 
        // greater than this value should be skipped. In case the deletion is being done 
        // while the app is running, ensure that the entry made will be for sure picked up
        // in the next run.   

        Init();
        "Table ID" := RecordRef.Number;
        "System ID" := SystemIdFieldRef.Value();
        TimestampFieldRef := RecordRef.Field(0);
        "Deletion Timestamp" := TimestampFieldRef.Value();
        "Deletion Timestamp" += 1; // to mark an update that is greater than the last time stamp on this record
        Insert();
    end;
}