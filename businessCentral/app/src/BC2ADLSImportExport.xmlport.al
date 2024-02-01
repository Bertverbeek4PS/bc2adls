xmlport 82560 "BC2ADLS Import/Export"
{
    Caption = 'BC2ADLS Import/Export';
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(ADLSETable; "ADLSE Table")
            {
                MaxOccurs = Unbounded;
                XmlName = 'ADLSETable';
                SourceTableView = where(Enabled = const(true));
                UseTemporary = true;

                fieldattribute(TableId; ADLSETable."Table ID")
                {
                    Occurrence = Required;
                }

                tableelement(ADLSEField; "ADLSE Field")
                {
                    MinOccurs = Zero;
                    SourceTableView = where(Enabled = const(true));
                    XmlName = 'ADLSEField';
                    UseTemporary = true;

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

                    trigger OnBeforeInsertRecord()
                    var
                        ADLSETableRec: Record "ADLSE Table";
                        ADLSEFieldRec: Record "ADLSE Field";
                    begin
                        if not ADLSETableRec.Get(ADLSEField."Table ID") then begin
                            ADLSETableRec.Validate("Table ID", ADLSEField."Table ID");
                            ADLSETableRec.Enabled := true;
                            ADLSETableRec.Insert(true);
                            ADLSETable.AddAllFields();
                        end;

                        if ADLSEFieldRec.Get(ADLSEField."Table ID", ADLSEField."Field ID") then begin
                            ADLSEFieldRec.Enabled := true;
                            ADLSEFieldRec.Modify(true);
                        end;

                        currXMLport.Skip();
                    end;
                }
                trigger OnBeforeInsertRecord()
                begin
                    currXMLport.Skip();
                end;
            }
        }
    }
}