page 82577 "ADLSE Export Categories"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Export Catgories';
    PageType = List;
    SourceTable = "ADLSE Export Category";
    UsageCategory = Lists;


    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    Caption = 'Code';
                    ToolTip = 'Unique Code of a Export Category which can be linked to tables which are part of the export to Azure Datalake.';
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                    ToolTip = 'Description of the Export Category.';
                }
            }
        }
    }
}

