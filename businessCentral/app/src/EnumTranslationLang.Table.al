#pragma warning disable LC0015
table 82568 "ADLSE Enum Translation Lang"
#pragma warning restore
{
    DataClassification = ToBeClassified;
    Caption = 'ADLSE Enum Translation Language';
    Access = Internal;
    LookupPageId = "ADLSE Enum Translations Lang";
    DrillDownPageId = "ADLSE Enum Translations Lang";

    fields
    {
        field(1; "Language Code"; Code[10])
        {
            DataClassification = SystemMetadata;
            Caption = 'Language Code';
            ToolTip = 'Specifies the language code.';
        }
        field(2; "Table Id"; Integer)
        {
            AllowInCustomizations = AsReadOnly;
            DataClassification = SystemMetadata;
            Caption = 'Table Id';
        }
        field(3; "Compliant Table Name"; Text[40])
        {
            DataClassification = SystemMetadata;
            Caption = 'Compliant Table Name';
            ToolTip = 'Specifies the compliant table name of the table that is compliant with Data Lake standards.';
        }
        field(4; "Field Id"; Integer)
        {
            AllowInCustomizations = AsReadOnly;
            DataClassification = SystemMetadata;
            Caption = 'Field Id';
        }
        field(5; "Compliant Field Name"; Text[40])
        {
            DataClassification = SystemMetadata;
            Caption = 'Compliant Object Name';
            ToolTip = 'Specifies the compliant field name of the field that is compliant with Data Lake standards.';
        }
        field(6; "Enum Value Id"; Integer)
        {
            AllowInCustomizations = AsReadOnly;
            DataClassification = SystemMetadata;
            Caption = 'Enum Index';
        }
        field(7; "Enum Value Caption"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'Enum Caption';
            ToolTip = 'Specifies the caption of the enum value.';
        }
    }

    keys
    {
        key(Key1; "Language Code", "Table Id", "Field Id", "Enum Value Id")
        {
            Clustered = true;
        }
    }

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Enum Translation Lang", 'i')]
    procedure InsertEnumLanguage(LanguageCode: Code[10]; TableId: Integer; FieldNo: Integer; FieldName: Text[30]; EnumValueOrdinal: Integer; EnumValueName: Text)
    var
        ADLSEUtil: Codeunit "ADLSE Util";
    begin
        Rec.Init();
        Rec."Language Code" := LanguageCode;
        Rec."Table Id" := TableId;
        Rec."Compliant Table Name" := CopyStr(ADLSEUtil.GetDataLakeCompliantTableName(TableId), 1, MaxStrLen((Rec."Compliant Table Name")));
        Rec."Field Id" := FieldNo;
        Rec."Compliant Field Name" := CopyStr(ADLSEUtil.GetDataLakeCompliantFieldName(TableId, FieldNo), 1, MaxStrLen((Rec."Compliant Field Name")));
        Rec."Enum Value Id" := EnumValueOrdinal;
        Rec."Enum Value Caption" := CopyStr(EnumValueName, 1, MaxStrLen(Rec."Enum Value Caption"));
        Rec.Insert(true);
    end;
}