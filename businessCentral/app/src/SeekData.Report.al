// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
namespace bc2adls;

using System.Utilities;
report 82560 "ADLSE Seek Data"
{
    ProcessingOnly = true;
    DataAccessIntent = ReadOnly;
    UsageCategory = None;

    dataset
    {
        dataitem(Number; Integer)
        {
            trigger OnAfterGetRecord()
            begin
                if OnlyCheckForExists then
                    Found := not CurrRecordRef.IsEmpty()
                else
                    Found := CurrRecordRef.FindSet(false);

                CurrReport.Break();
            end;
        }
    }

    var
        CurrRecordRef: RecordRef;
        Found: Boolean;
        OnlyCheckForExists: Boolean;

    local procedure GetResult(RecordRef: RecordRef): Boolean
    begin
        UseRequestPage(false);
        CurrRecordRef := RecordRef;
        RunModal();
        exit(Found);
    end;

    internal procedure RecordsExist(RecordRef: RecordRef): Boolean
    begin
        OnlyCheckForExists := true;
        exit(GetResult(RecordRef));
    end;

    internal procedure FindRecords(RecordRef: RecordRef): Boolean
    begin
        OnlyCheckForExists := false;
        exit(GetResult(RecordRef));
    end;

    internal procedure RecordsExist(var ADLSEDeletedRecord: Record "ADLSE Deleted Record") Result: Boolean
    begin
        CurrRecordRef.GetTable(ADLSEDeletedRecord);
        Result := RecordsExist(CurrRecordRef);
        CurrRecordRef.SetTable(ADLSEDeletedRecord);
    end;

    internal procedure FindRecords(var ADLSEDeletedRecord: Record "ADLSE Deleted Record") Result: Boolean
    begin
        CurrRecordRef.GetTable(ADLSEDeletedRecord);
        Result := FindRecords(CurrRecordRef);
        CurrRecordRef.SetTable(ADLSEDeletedRecord);
    end;

}