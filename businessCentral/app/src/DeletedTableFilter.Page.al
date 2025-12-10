namespace bc2adls;

using System.Reflection;

page 11344439 "ADLSE Deleted Table Filter"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "ADLSE Deleted Table Filter";
    Caption = 'Deleted Table Filter';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(TableId; Rec.TableId)
                {
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        TableMetadata: Record "Table Metadata";
                    begin
                        GetTableId(TableMetadata);
                        if Page.RunModal(Page::"Available Table Selection List", TableMetadata) = Action::LookupOK then
                            Rec.TableId := TableMetadata.ID;
                    end;
                }
                field("Table Caption"; Rec."Table Caption") { }
            }
        }
    }
    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Table", 'r')]
    local procedure GetTableId(var TableMetadata: Record "Table Metadata")
    var
        ADLSETable: Record "ADLSE Table";
        TableFilterTxt: Text;
    begin
        ADLSETable.Reset();
        if ADLSETable.FindSet() then
            repeat
                if TableFilterTxt = '' then
                    TableFilterTxt := Format(ADLSETable."Table ID")
                else
                    TableFilterTxt += '|' + Format(ADLSETable."Table ID");
            until ADLSETable.Next() = 0;
        TableMetadata.SetFilter(TableMetadata.ID, TableFilterTxt);
    end;
}