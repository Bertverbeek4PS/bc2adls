page 82577 "ADLSE Export Categories"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Export Catgories';
    PageType = List;
    SourceTable = "ADLSE Export Category";


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

