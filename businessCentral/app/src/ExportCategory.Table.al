table 80040 "ADLSE Export Category"
{
    Caption = 'Export Category';
    DataClassification = ToBeClassified;
    LookupPageId = "ADLSE Export Categories";
    ObsoleteReason = 'Replaced with ADLSE Export Category Table.';
    ObsoleteTag = '25.0';
    ObsoleteState = Pending;

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

