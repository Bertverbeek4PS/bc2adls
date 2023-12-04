//A list page that is build on table Enum Translation
page 82570 "ADLSE Enum Translations Lang"
{
    PageType = List;
    ApplicationArea = All;
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
                    ToolTip = 'The language code.';
                }
                field(CompliantTableName; Rec."Compliant Table Name")
                {
                    Editable = false;
                    ToolTip = 'The name of the table that is compliant with Data Lake standards.';
                }
                field(CompliantFieldName; Rec."Compliant Field Name")
                {
                    Editable = false;
                    ToolTip = 'The name of the field that is compliant with Data Lake standards.';
                }
                field(EnumValueCaption; Rec."Enum Value Caption")
                {
                    Editable = false;
                    ToolTip = 'The caption of the enum value.';
                }
            }
        }
    }
}
