//A list page that is build on table Enum Translation
page 82569 "ADLSE Enum Translations"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "ADLSE Enum Translation";


    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
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

    actions
    {
        area(Processing)
        {
            action(RefreshOptions)
            {
                ApplicationArea = All;
                Caption = 'Refresh Options';
                ToolTip = 'Refresh the options of the enum fields.';
                Image = Refresh;

                trigger OnAction();
                begin
                    Rec.RefreshOptions();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(RefreshOptions_Promoted; RefreshOptions) { }
            }
        }
    }
}
