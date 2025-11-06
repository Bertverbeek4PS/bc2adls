table 82569 "Deleted Tables Not to Sync"
{
    DataClassification = ToBeClassified;
    Caption = 'Deleted Tables Not to Sync';

    fields
    {
        field(1; TableId; Integer)
        {
            TableRelation = "ADLSE Table"."Table ID";
            Caption = 'Table ID';
        }
        field(5; "Table Caption"; Text[100])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Name" where("Object ID" = field(TableId)));
            Caption = 'Table Caption';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; TableId)
        {
            Clustered = true;
        }
    }
}