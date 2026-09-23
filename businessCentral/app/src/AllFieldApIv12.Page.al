namespace bc2adls;
using System.Reflection;

page 82568 "ADLSE All Field API v12"
{
    PageType = API;
    APIPublisher = 'bc2adlsTeamMicrosoft';
    APIGroup = 'bc2adls';
    APIVersion = 'v1.2';
    EntityName = 'adlseAllField';
    EntitySetName = 'adlseAllFields';
    SourceTable = "Field";
    SourceTableView = where(Enabled = const(true), Class = const(Normal), ObsoleteState = filter(<> Removed));
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(no; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(name; name)
                {
                    Caption = 'name';
                }
                field(dataFormat; DataFormat)
                {
                    Caption = 'dataFormat';
                }
                field(displayName; Rec.FieldName)
                {
                    Caption = 'displayName';
                }
                field(maximumLength; Rec.Len)
                {
                    Caption = 'maximumLength';
                }
                field(enabledADLSE; ADLSEEnabled)
                {
                    Caption = 'Enabled ADLSE';
                }
            }
        }
    }

    var
        name: Text;
        DataFormat: Text;
        ADLSEEnabled: Boolean;

    trigger OnAfterGetRecord()
    var
        ADLSEField: Record "ADLSE Field";
        ADLSECDMUtil: Codeunit "ADLSE CDM Util";
        ADLSEUtil: Codeunit "ADLSE Util";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        AppliedTraits: JsonArray;
    begin
        RecordRef.Open(Rec.TableNo);
        FieldRef := RecordRef.Field(Rec."No.");
        ADLSECDMUtil.GetCDMAttributeDetails(FieldRef.Type(), DataFormat, AppliedTraits);
        name := ADLSEUtil.GetDataLakeCompliantFieldName(FieldRef);
        RecordRef.Close();

        ADLSEField.SetRange("Table ID", Rec.TableNo);
        ADLSEField.SetRange("Field ID", Rec."No.");
        ADLSEField.SetRange("Enabled", true);

        ADLSEEnabled := not ADLSEField.IsEmpty();
    end;
}
