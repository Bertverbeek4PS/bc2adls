namespace bc2adls;

using System.Reflection;

table 11344439 "ADLSE Deleted Table Filter"
{
    DataClassification = ToBeClassified;
    Caption = 'ADLSE Deleted Table Filter';
    LookupPageId = "ADLSE Deleted Table Filter";
    DrillDownPageId = "ADLSE Deleted Table Filter";

    fields
    {
        field(1; TableId; Integer)
        {
            TableRelation = "ADLSE Table"."Table ID";
            Caption = 'Table ID';
            ToolTip = 'Specify the ID of the table that should not be tracked for deletes.';
            DataClassification = CustomerContent;
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

    fieldgroups
    {
        fieldgroup(DropDown; TableId)
        {
        }
        fieldgroup(Brick; TableId)
        {
        }
    }
}