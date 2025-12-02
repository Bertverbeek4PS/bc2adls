table 82560 "ADLSE Export Category Table"
{
    Caption = 'Export Category Table';
    DataClassification = ToBeClassified;
    LookupPageId = "ADLSE Export Categories";
    DataPerCompany = false;

    fields
    {
        field(1; "Code"; Code[50])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(10; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }
}