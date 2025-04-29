// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
page 82565 "ADLSE Table Information API"
{
    PageType = API;
    APIPublisher = 'bc2adlsTeamMicrosoft';
    APIGroup = 'bc2adls';
    APIVersion = 'v1.2';
    EntityName = 'adlseTableInformation';
    EntitySetName = 'adlseTablesInformation';
    SourceTable = "ADLSE Table Information";
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    DelayedInsert = false;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(tableId; Rec."Table ID") { }
                field(tableName; Rec."Table Name") { }
                field(numberOfRecords; Rec."No. of Records") { }

                field(id; Rec.SystemId)
                {
                    Editable = false;
                }
#pragma warning disable LC0016
                field(systemRowVersion; Rec.SystemRowVersion)
                {
                    Editable = false;
                }
#pragma warning restore
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Editable = false;
                }
            }

        }
    }

    trigger OnOpenPage()
    var
        AllObj: Record AllObj;
        ADLSETable: Record "ADLSE Table";
        ADLSEUtil: Codeunit "ADLSE Util";
    begin
        if not AllObj.Get(AllObj."Object Type"::Table, Database::"ADLSE Table") then
            Error(NoADLSESetupFoundErr);

        ADLSETable.SetRange(Enabled, true);
        if ADLSETable.FindSet() then
            repeat
                Rec.Init();
                Rec."Table ID" := ADLSETable."Table ID";
                Rec."No. of Records" := GetTotalDatabaseRecords(ADLSETable."Table ID");
                Rec."Table Name" := ADLSEUtil.GetTableName(ADLSETable."Table ID");
                Rec.Insert();
            until ADLSETable.Next() = 0
        else
            Error(NoADLSETablesFoundErr);
    end;

    var
        NoADLSESetupFoundErr: Label 'No Setup Table for ADLSE found in this environment';
        NoADLSETablesFoundErr: Label 'No Tableselection for ADLSE found in this environment';

    local procedure GetTotalDatabaseRecords(TableID: Integer): Integer
    var
        CountRecordRef: RecordRef;
    begin
        CountRecordRef.Open(TableID);
        exit(CountRecordRef.Count);
    end;
}