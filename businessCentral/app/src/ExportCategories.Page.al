page 82566 "ADLSE Export Categories"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Export Catgories';
    PageType = List;
    SourceTable = "ADLSE Export Category Table";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    Caption = 'Code';
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                }
            }
        }
    }
}

