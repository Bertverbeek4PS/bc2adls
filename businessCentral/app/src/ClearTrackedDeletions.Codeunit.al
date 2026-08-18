// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
namespace bc2adls;
codeunit 82573 "ADLSE Clear Tracked Deletions"
{
    /// This codeunit removes the tracked deleted records- those that track deletions of records from tables being exported, so 
    /// that the data lake becomes aware of them and removes those records from the final set of records. Once, these trackings 
    /// have been exported to the data lake, they are no more required. This codeunit removes such records and may be invoked
    /// from a job queue that runs at a low- frequency and periodically flushes such data to manage storage space.

    Access = Internal;

    trigger OnRun()
    begin
        ClearTrackedDeletedRecords();
    end;

    var
        TrackedDeletedRecordsRemovedMsg: Label 'Representations of deleted records that have been exported previously have been deleted.';

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Table", 'r')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Deleted Record", 'rd')]
    local procedure ClearTrackedDeletedRecords()
    var
        ADLSETable: Record "ADLSE Table";
        ADLSETableLastTimestamp: Record "ADLSE Table Last Timestamp";
        LastEntryNo: BigInteger;
    begin
        ADLSETable.SetLoadFields("Table ID");
        if ADLSETable.FindSet() then
            repeat
                LastEntryNo := ADLSETableLastTimestamp.GetDeletedLastEntryNo(ADLSETable."Table ID");
                DeleteInBatches(ADLSETable."Table ID", LastEntryNo);
                ADLSETableLastTimestamp.SaveDeletedLastEntryNo(ADLSETable."Table ID", 0);
                Commit();
            until ADLSETable.Next() = 0;
        Message(TrackedDeletedRecordsRemovedMsg);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Deleted Record", 'rd')]
    local procedure DeleteInBatches(TableID: Integer; LastEntryNo: BigInteger)
    var
        ADLSEDeletedRecord: Record "ADLSE Deleted Record";
        BatchUpperBound: Integer;
        BatchSize: Integer;
    begin
        BatchSize := 1000;
        // Use Key2 (Table ID) to efficiently seek records for this table.
        // FindFirst returns the record with the lowest Entry No. for this Table ID
        // because Entry No. is the clustered key and acts as the row locator in Key2.
        ADLSEDeletedRecord.SetRange("Table ID", TableID);
        ADLSEDeletedRecord.SetFilter("Entry No.", '<=%1', LastEntryNo);
        while ADLSEDeletedRecord.FindFirst() do begin
            BatchUpperBound := ADLSEDeletedRecord."Entry No." + BatchSize - 1;
            ADLSEDeletedRecord.SetRange("Entry No.", ADLSEDeletedRecord."Entry No.", BatchUpperBound);
            ADLSEDeletedRecord.DeleteAll(false);
            Commit();
            // Restore the Table ID range and Entry No. upper-bound filter for next iteration.
            ADLSEDeletedRecord.SetRange("Entry No.");
            ADLSEDeletedRecord.SetRange("Table ID", TableID);
            ADLSEDeletedRecord.SetFilter("Entry No.", '<=%1', LastEntryNo);
        end;
    end;
}