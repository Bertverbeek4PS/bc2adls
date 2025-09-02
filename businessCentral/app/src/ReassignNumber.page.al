page 82565 "Reassign Number"
{
    Caption = 'Reassign Number';
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(NewNumber; NewNumber)
                {
                    Caption = 'New Number';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the new number to be assigned.';
                }
            }
        }
    }

    actions
    {
    }

    var
        NewNumber: Integer;

    procedure GetValues(var NewNewNumber: Integer)
    begin
        NewNewNumber := NewNumber;
    end;

}