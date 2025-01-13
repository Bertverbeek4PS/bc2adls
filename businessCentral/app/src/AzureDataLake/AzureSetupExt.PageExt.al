pageextension 82560 "Azure Setup Ext" extends "ADLSE Setup"
{
    layout
    {
        addafter("Tenant ID")
        {
            group(Account)
            {
                Caption = 'Azure Data Lake';
                Editable = AzureDataLake;
                field(Container; Rec.Container)
                {
                    ApplicationArea = All;
                }
                field(AccountName; Rec."Account Name")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    var
        AzureDataLake: Boolean;

    trigger OnAfterGetRecord()
    begin
        AzureDataLake := Rec."Storage Type" = Rec."Storage Type"::"Azure Data Lake";
    end;
}