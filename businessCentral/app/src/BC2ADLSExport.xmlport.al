xmlport 62019 "BC2ADLS Export"
{
    Caption = 'BC2ADLS Export';
    UseRequestPage = false;
    Direction = Export;
    Permissions = tabledata "ADLSE Field" = r,
                  tabledata "ADLSE Table" = r;

    schema
    {
        textelement(Root)
        {
            tableelement(ADLSETable; "ADLSE Table")
            {
                MaxOccurs = Unbounded;
                XmlName = 'ADLSETable';
                SourceTableView = where(Enabled = const(true));

                fieldattribute(TableId; ADLSETable."Table ID")
                {
                    Occurrence = Required;
                }

                tableelement(ADLSEField; "ADLSE Field")
                {
                    MinOccurs = Zero;
                    SourceTableView = where(Enabled = const(true));
                    XmlName = 'ADLSEField';

                    fieldattribute(TableID;
                    ADLSEField."Table ID")
                    {
                        Occurrence = Required;
                    }
                    fieldattribute(FieldID; ADLSEField."Field ID")
                    {
                        Occurrence = Required;
                    }

                    trigger OnPreXmlItem()
                    begin
                        ADLSEField.SetRange("Table ID", ADLSETable."Table ID");
                    end;


                }
            }
        }
    }
}