// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
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
                    Found := not CurrRecRef.IsEmpty()
                else
                    Found := CurrRecRef.FindSet(false);

                CurrReport.Break();
            end;
        }
    }

    var
        CurrRecRef: RecordRef;
        Found: Boolean;
        OnlyCheckForExists: Boolean;

    local procedure GetResult(RecRef: RecordRef): Boolean
    begin
        UseRequestPage(false);
        CurrRecRef := RecRef;
        RunModal();
        exit(Found);
    end;

    internal procedure RecordsExist(RecRef: RecordRef): Boolean
    begin
        OnlyCheckForExists := true;
        exit(GetResult(RecRef));
    end;

    internal procedure FindRecords(RecRef: RecordRef): Boolean
    begin
        OnlyCheckForExists := false;
        exit(GetResult(RecRef));
    end;

    internal procedure RecordsExist(var ADLSEDeletedRecord: Record "ADLSE Deleted Record") Result: Boolean
    begin
        CurrRecRef.GetTable(ADLSEDeletedRecord);
        Result := RecordsExist(CurrRecRef);
        CurrRecRef.SetTable(ADLSEDeletedRecord);
    end;

    internal procedure FindRecords(var ADLSEDeletedRecord: Record "ADLSE Deleted Record") Result: Boolean
    begin
        CurrRecRef.GetTable(ADLSEDeletedRecord);
        Result := FindRecords(CurrRecRef);
        CurrRecRef.SetTable(ADLSEDeletedRecord);
    end;

}