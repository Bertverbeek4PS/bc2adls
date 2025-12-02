xmlport 62018 "BC2ADLS Import"
{
    Caption = 'BC2ADLS Import';
    UseRequestPage = false;
    Direction = Import;
    Permissions = tabledata "ADLSE Field" = rmi,
                  tabledata "ADLSE Table" = rmid;

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
                            ADLSEFieldRec.SetRange("Table ID", ADLSEField."Table ID");
                            ADLSEFieldRec.InsertForTable(ADLSETableRec);
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

    trigger OnPreXmlPort()
    var
        ADLSETableRec: Record "ADLSE Table";
        ConfirmManagement: Codeunit "Confirm Management";
        ConfirmQuestionMsg: Label 'With the import all existing ADLSE Tables and Fields will be deleted. Do you want to continue?';
    begin
        if not ADLSETableRec.IsEmpty then
            if GuiAllowed then begin
                if ConfirmManagement.GetResponse(ConfirmQuestionMsg, true) then
                    ADLSETableRec.DeleteAll(true)
                else
                    currXMLport.Quit();
            end else
                ADLSETableRec.DeleteAll(true);

    end;
}