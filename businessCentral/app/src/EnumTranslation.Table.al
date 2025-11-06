#pragma warning disable LC0015
table 82567 "ADLSE Enum Translation"
#pragma warning restore
{
    DataClassification = ToBeClassified;
    Caption = 'ADLSE Enum Translation';
    Access = Internal;
    LookupPageId = "ADLSE Enum Translations";
    DrillDownPageId = "ADLSE Enum Translations";

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
    }

    keys
    {
        key(Key1; "Table Id", "Field Id")
        {
            Clustered = true;
        }
    }

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Enum Translation", 'i')]
    local procedure InsertEnum(TableId: Integer; FieldNo: Integer; FieldName: Text[30])
    var
        ADLSEUtil: Codeunit "ADLSE Util";
    begin
        Rec.Init();
        Rec."Table Id" := TableId;
        Rec."Compliant Table Name" := CopyStr(ADLSEUtil.GetDataLakeCompliantTableName(TableId), 1, MaxStrLen((Rec."Compliant Table Name")));
        Rec."Field Id" := FieldNo;
        Rec."Compliant Field Name" := CopyStr(ADLSEUtil.GetDataLakeCompliantFieldName(TableId, FieldNo), 1, MaxStrLen((Rec."Compliant Field Name")));
        Rec.Insert(true);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE table", 'r')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Enum Translation", 'd')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Enum Translation Lang", 'd')]
    procedure RefreshOptions()
    var
        ADLSETable: Record "ADLSE Table";
        ADLSEEnumTranslation: Record "ADLSE Enum Translation";
        ADLSEEnumTranslationLang: Record "ADLSE Enum Translation Lang";
        ADLSESetupRec: Record "ADLSE Setup";
        RecordField: Record Field;
        ADLSEExternalEvents: Codeunit "ADLSE External Events";
        ADLSERecordRef: RecordRef;
    begin
        ADLSEEnumTranslation.DeleteAll(false);
        ADLSEEnumTranslationLang.DeleteAll(false);

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
        if not ADLSETable.Get(ADLSEEnumTranslationLang.RecordId.TableNo) then begin
            ADLSETable.Add(ADLSEEnumTranslationLang.RecordId.TableNo);
            ADLSETable.AddAllFields();
        end;

        ADLSEExternalEvents.OnRefreshOptions(ADLSESetupRec);
    end;

    local procedure InsertEnums(ADLSERecordRef: RecordRef; FieldRec: Record Field)
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSEEnumTranslationLang: Record "ADLSE Enum Translation Lang";
        TranslationHelper: Codeunit "Translation Helper";
        FieldRef: FieldRef;
        i: Integer;
        x: Integer;
        Translations: List of [Text];
    begin
        ADLSESetup.GetSingleton();
        FieldRef := ADLSERecordRef.Field(FieldRec."No.");
        InsertEnum(FieldRec.TableNo, FieldRec."No.", FieldRec.FieldName);
        for i := 1 to FieldRef.EnumValueCount() do begin
            //Insert language captions
            Translations := ADLSESetup.Translations.Split(';');
            Translations.Remove('');
            for x := 1 to Translations.Count() do begin
                TranslationHelper.SetGlobalLanguageByCode(CopyStr(Translations.Get(x), 1, 10));
                ADLSEEnumTranslationLang.InsertEnumLanguage(CopyStr(Translations.Get(x), 1, 10), FieldRec.TableNo, FieldRec."No.", FieldRec.FieldName, FieldRef.GetEnumValueOrdinal(i), FieldRef.GetEnumValueCaption(i));
            end;
        end;
        TranslationHelper.RestoreGlobalLanguage();
    end;
}