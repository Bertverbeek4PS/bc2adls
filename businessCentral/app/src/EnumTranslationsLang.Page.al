//A list page that is build on table Enum Translation
page 82565 "ADLSE Enum Translations Lang"
{
    PageType = List;
    ApplicationArea = All;
    Caption = 'Enum Translations Language';
    UsageCategory = Lists;
    SourceTable = "ADLSE Enum Translation Lang";


    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(LanguageCode; Rec."Language Code")
                {
                    Editable = false;
                }
                field(CompliantTableName; Rec."Compliant Table Name")
                {
                    Editable = false;
                }
                field(CompliantFieldName; Rec."Compliant Field Name")
                {
                    Editable = false;
                }
                field(EnumValueCaption; Rec."Enum Value Caption")
                {
                    Editable = false;
                }
            }
        }
    }
}
