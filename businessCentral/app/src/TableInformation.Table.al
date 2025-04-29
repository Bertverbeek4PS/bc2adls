table 82572 "ADLSE Table Information"
{
    Access = Internal;
    Caption = 'ADLSE Table Information';
    DataClassification = CustomerContent;
    TableType = Temporary;
    Permissions = tabledata "ADLSE Field" = rd,
                  tabledata "ADLSE Table Last Timestamp" = d,
                  tabledata "ADLSE Deleted Record" = d;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            AllowInCustomizations = Never;
            Caption = 'Table ID';
        }
        field(2; "Table Name"; Text[30])
        {
            AllowInCustomizations = Never;
            Caption = 'Table Name';
        }
        field(3; "No. of Records"; Integer)
        {
            AllowInCustomizations = Never;
            Caption = 'No. of Records';
        }
    }

    keys
    {
        key(Key1; "Table ID")
        {
            Clustered = true;
        }
    }
}