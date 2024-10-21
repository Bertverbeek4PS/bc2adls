table 82569 "Deleted Tables Not to Sync"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; TableId; Integer)
        {
            DataClassification = ToBeClassified;
            TableRelation = "ADLSE Table"."Table ID";
            Caption = 'Table ID';
            ToolTip = 'Specify the ID of the table that should not be tracked for deletes.';
        }
        field(5; "Table Caption"; Text[100])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Name" where("Object ID" = field(TableId)));
            Caption = 'Table Caption';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the caption of the table whose data is to exported.';
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