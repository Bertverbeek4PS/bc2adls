namespace bc2adls;

using System.Reflection;
page 82564 "Deleted Tables Not To Sync"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Deleted Tables Not to Sync";

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(TableId; rec.TableId)
                {
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        TableMetadata: Record "Table Metadata";
                    begin
                        GetTableId(TableMetadata);
                        if Page.RunModal(Page::"Available Table Selection List", TableMetadata) = Action::LookupOK then
                            rec.TableId := TableMetadata.ID;
                    end;
                }
                field("Table Caption"; rec."Table Caption") { }
            }
        }
    }
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