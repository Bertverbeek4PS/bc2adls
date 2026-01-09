namespace bc2adls;

using System.Reflection;
codeunit 82578 "ADLSE Company Run"
{

    Permissions = tabledata "ADLSE Companies Table" = RIMD;
    TableNo = "ADLSE Companies Table";
    trigger OnRun()
    var
        TableMetadata: Record "Table Metadata";
        ADLSETableLastTimestamp: Record "ADLSE Table Last Timestamp";
        ADLSERun: Record "ADLSE Run";
    begin
        if TableMetadata.Get(Rec."Table ID") then begin
            Rec."Updated Last Timestamp" := ADLSETableLastTimestamp.GetUpdatedLastTimestamp(Rec."Table ID");
            Rec."Last Timestamp Deleted" := ADLSETableLastTimestamp.GetDeletedLastEntryNo(Rec."Table ID");
        end else begin
            Rec."Updated Last Timestamp" := 0;
            Rec."Last Timestamp Deleted" := 0;
        end;
        ADLSERun.GetLastRunDetails(Rec."Table ID", Rec."Last Run State", Rec."Last Started", Rec."Last Error");
        Rec.Modify(false);
    end;
}