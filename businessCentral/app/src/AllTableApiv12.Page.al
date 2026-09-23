namespace bc2adls;
using System.Reflection;
page 82567 "ADLSE All Table API v12"
{
    PageType = API;
    APIPublisher = 'bc2adlsTeamMicrosoft';
    APIGroup = 'bc2adls';
    APIVersion = 'v1.2';
    EntityName = 'adlseAllTable';
    EntitySetName = 'adlseAllTables';
    SourceTable = "Table Metadata";
    SourceTableView = where(TableType = const(Normal));
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                Caption = 'definitions';
                field(systemId; Rec.SystemId)
                {
                    Caption = 'SystemId';
                }
                field(objectID; Rec.ID)
                {
                    Caption = 'Object ID';
                }
                field(entityName; ADLSEUtil.GetDataLakeCompliantTableName(Rec.ID))
                {
                    Caption = 'Entity Name';
                }
                field(displayName; ADLSEUtil.GetTableName(Rec.ID))
                {
                    Caption = 'Display Name';
                }
                field(description; StrSubstNo(RepresentsTableTxt, ADLSEUtil.GetTableName(Rec.ID)))
                {
                    Caption = 'Description';
                }
                field(enabledADLSE; ADLSEEnabled)
                {
                    Caption = 'Enabled ADLSE';
                }
            }
            part(fields; "ADLSE All Field API v12")
            {
                EntityName = 'adlseAllField';
                EntitySetName = 'adlseAllFields';
                SubPageLink = TableNo = field(ID);
            }
        }
    }
    var
        ADLSEUtil: Codeunit "ADLSE Util";
        ADLSEEnabled: Boolean;
        RepresentsTableTxt: Label 'Represents the table %1', Comment = '%1: table caption';


    trigger OnAfterGetRecord()
    var
        ADLSETable: Record "ADLSE Table";
    begin
        ADLSETable.SetRange("Table ID", Rec.ID);
        ADLSETable.SetRange("Enabled", true);
        ADLSEEnabled := not ADLSETable.IsEmpty();
    end;

    trigger OnOpenPage()
    var
        ExclusionIDs: List of [Integer];
        FilterString: Text;
        TableID: Integer;
    begin
        Rec.SetRange(Scope, Rec.Scope::Cloud);
        if Rec.FindSet() then
            repeat
                if not TryOpenRecordRef(Rec.ID) then
                    ExclusionIDs.Add(Rec.ID);
            until Rec.Next() = 0;

        foreach TableID in ExclusionIDs do begin
            if FilterString <> '' then
                FilterString += '&';
            FilterString += '<>' + Format(TableID);
        end;

        Rec.SetFilter(ID, FilterString);
    end;

    [TryFunction]
    local procedure TryOpenRecordRef(TableID: Integer)
    var
        RRef: RecordRef;
    begin
        RRef.Open(TableID);
        RRef.Close();
    end;
}
