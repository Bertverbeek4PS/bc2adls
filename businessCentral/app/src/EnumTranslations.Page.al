//A list page that is build on table Enum Translation
page 82569 "ADLSE Enum Translations"
{
    PageType = List;
    ApplicationArea = All;
    Caption = 'ADLSE Enum Translations';
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
                }
                field(CompliantFieldName; Rec."Compliant Field Name")
                {
                    Editable = false;
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

                trigger OnAction()
                begin
                    Rec.RefreshOptions();
                end;
            }
        }
        area(Navigation)
        {
            action(Translations)
            {
                ApplicationArea = All;
                Caption = 'Translations';
                ToolTip = 'View the translations of the enum fields.';
                Image = Language;

                trigger OnAction()
                var
                    ADLSEEnumTranslationLang: Record "ADLSE Enum Translation Lang";
                    ADLSEEnumTranslationsLang: Page "ADLSE Enum Translations Lang";
                begin
                    ADLSEEnumTranslationLang.SetRange("Table Id", Rec."Table Id");
                    ADLSEEnumTranslationLang.SetRange("Field Id", Rec."Field Id");
                    ADLSEEnumTranslationsLang.SetSelectionFilter(ADLSEEnumTranslationLang);
                    ADLSEEnumTranslationsLang.RunModal();
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
