// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
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
        ADLSEDeletedRecord: Record "ADLSE Deleted Record";
    begin
        ADLSETable.SetLoadFields("Table ID");
        if ADLSETable.FindSet() then
            repeat
                ADLSEDeletedRecord.SetRange("Table ID", ADLSETable."Table ID");
                ADLSEDeletedRecord.SetFilter("Entry No.", '<=%1', ADLSETableLastTimestamp.GetDeletedLastEntryNo(ADLSETable."Table ID"));
                if not ADLSEDeletedRecord.IsEmpty() then
                    ADLSEDeletedRecord.DeleteAll(false);

                ADLSETableLastTimestamp.SaveDeletedLastEntryNo(ADLSETable."Table ID", 0);

                Commit(); //Because of very large numbers of records, we commit after each table.
            until ADLSETable.Next() = 0;
        Message(TrackedDeletedRecordsRemovedMsg);
    end;
}