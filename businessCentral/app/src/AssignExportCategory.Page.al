namespace bc2adls;

page 11344437 "ADLSE Assign Export Category"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Assign Export Category';
    PageType = StandardDialog;
    DataCaptionExpression = '';
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            field("Export Category"; ExportCategory)
            {
                Caption = 'Export Catgory';
                TableRelation = "ADLSE Export Category Table".Code;
                ToolTip = 'Specifies Unique Code of an Export Category which can be linked to tables which are part of the export to Azure Datalake.';
            }
        }
    }
    var
        ExportCategory: Code[50];

    procedure GetExportCategoryCode(): Code[50]
    begin
        exit(ExportCategory);
    end;
}
