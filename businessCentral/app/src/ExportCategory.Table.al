namespace bc2adls;
table 82570 "ADLSE Export Category"
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
            ToolTip = 'Specifies the Unique Code of a Export Category which can be linked to tables which are part of the export to Azure Datalake.';
            NotBlank = true;
        }
        field(10; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the Description of the Export Category.';
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

