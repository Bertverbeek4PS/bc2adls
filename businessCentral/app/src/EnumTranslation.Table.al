table 82567 "ADLSE Enum Translation"
{
    DataClassification = ToBeClassified;
    Caption = 'ADLSE Enum Translation';
    Access = Internal;

    fields
    {
        field(1; "Table Id"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Table Id';
        }
        field(2; "Compliant Table Name"; Text[40])
        {
            DataClassification = SystemMetadata;
            Caption = 'Compliant Table Name';
        }
        field(3; "Field Id"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Field Id';
        }
        field(4; "Compliant Field Name"; Text[40])
        {
            DataClassification = SystemMetadata;
            Caption = 'Compliant Object Name';
        }
        field(5; "Enum Value Id"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Enum Index';
        }
        field(6; "Enum Value Caption"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'Enum Caption';
        }
    }

    keys
    {
        key(Key1; "Table Id", "Field Id", "Enum Value Id")
        {
            Clustered = true;
        }
    }

    local procedure InsertEnum(TableId: Integer; FieldNo: Integer; FieldName: Text[30]; EnumValueOrdinal: Integer; EnumValueName: Text)
    var
        ADLSEUtil: Codeunit "ADLSE Util";
    begin
        Rec.Init();
        Rec."Table Id" := TableId;
        Rec."Compliant Table Name" := CopyStr(ADLSEUtil.GetDataLakeCompliantTableName(TableId), 1, MaxStrLen((Rec."Compliant Table Name")));
        Rec."Field Id" := FieldNo;
        Rec."Compliant Field Name" := CopyStr(ADLSEUtil.GetDataLakeCompliantFieldName(FieldName, FieldNo), 1, MaxStrLen((Rec."Compliant Field Name")));
        Rec."Enum Value Id" := EnumValueOrdinal;
        Rec."Enum Value Caption" := CopyStr(EnumValueName, 1, MaxStrLen(Rec."Enum Value Caption"));
        Rec.Insert();
    end;

    procedure RefreshOptions()
    var
        ADLSETable: Record "ADLSE Table";
        ADLSEEnumTranslation: Record "ADLSE Enum Translation";
        RecordField: Record Field;
        ADLSERecordRef: RecordRef;
    begin
        ADLSEEnumTranslation.DeleteAll();

        if ADLSETable.FindSet() then
            repeat
                RecordField.SetRange(TableNo, ADLSETable."Table ID");
                RecordField.SetRange("Type", RecordField."Type"::Option);
                RecordField.SetFilter(ObsoleteState, '<>%1', RecordField.ObsoleteState::Removed);
                ADLSERecordRef.Open(ADLSETable."Table ID");
                if RecordField.FindSet() then
                    repeat
                        InsertEnums(ADLSERecordRef, RecordField);
                    until RecordField.Next() = 0;
                ADLSERecordRef.Close();
            until ADLSETable.Next() = 0;

        if not ADLSETable.Get(Rec.RecordId.TableNo) then begin
            ADLSETable.Add(Rec.RecordId.TableNo);
            ADLSETable.AddAllFields();
        end;
    end;

    local procedure InsertEnums(ADLSERecordRef: RecordRef; FieldRec: Record Field)
    var
        FieldRef: FieldRef;
        i: Integer;
    begin
        FieldRef := ADLSERecordRef.Field(FieldRec."No.");
        for i := 1 to FieldRef.EnumValueCount() do
            InsertEnum(FieldRec.TableNo, FieldRec."No.", FieldRec.FieldName, FieldRef.GetEnumValueOrdinal(i), FieldRef.GetEnumValueName(i));
    end;
}