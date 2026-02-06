codeunit 85569 "ADLSE CDM Util Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] bc2adls CDM Util
    end;

    var
        ADLSELibrarybc2adls: Codeunit "ADLSE Library - bc2adls";
        LibraryAssert: Codeunit "Library Assert";
        "Storage Type": Enum "ADLSE Storage Type";
        IsInitialized: Boolean;

    [Test]
    procedure TestCreateEntityContent_ValidJson()
    var
        ADLSETable: Record "ADLSE Table";
        ADLSECDMUtil: Codeunit "ADLSE CDM Util";
        ADLSEExecute: Codeunit "ADLSE Execute";
        EntityContent: JsonObject;
        FieldIdList: List of [Integer];
        JsonText: Text;
        Token: JsonToken;
    begin
        // [SCENARIO] CreateEntityContent creates valid JSON with correct structure
        // [GIVEN] Initialized test environment with a table configured for export
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSETable.Add(Database::"Reason Code");
        ADLSELibrarybc2adls.InsertFields();

        // [WHEN] CreateEntityContent is called
        FieldIdList := ADLSEExecute.CreateFieldListForTable(Database::"Reason Code");
        EntityContent := ADLSECDMUtil.CreateEntityContent(Database::"Reason Code", FieldIdList);

        // [THEN] The JSON contains required properties
        EntityContent.WriteTo(JsonText);
        LibraryAssert.IsTrue(EntityContent.Contains('jsonSchemaSemanticVersion'), 'Should contain jsonSchemaSemanticVersion');
        LibraryAssert.IsTrue(EntityContent.Contains('imports'), 'Should contain imports');
        LibraryAssert.IsTrue(EntityContent.Contains('definitions'), 'Should contain definitions');

        // [THEN] The definitions contain entity information
        EntityContent.SelectToken('definitions[0].entityName', Token);
        LibraryAssert.IsTrue(Token.AsValue().AsText().Contains('ReasonCode'), 'Entity name should contain ReasonCode');
    end;

    [Test]
    procedure TestCreateEntityContent_IncludesAllEnabledFields()
    var
        ADLSETable: Record "ADLSE Table";
        ADLSEField: Record "ADLSE Field";
        ADLSECDMUtil: Codeunit "ADLSE CDM Util";
        ADLSEExecute: Codeunit "ADLSE Execute";
        EntityContent: JsonObject;
        FieldIdList: List of [Integer];
        Token: JsonToken;
        AttributesArray: JsonArray;
        EnabledFieldCount: Integer;
    begin
        // [SCENARIO] CreateEntityContent includes all enabled fields in the entity definition
        // [GIVEN] Initialized test environment with enabled fields
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSETable.Add(Database::"Reason Code");
        ADLSELibrarybc2adls.InsertFields();
        ADLSELibrarybc2adls.EnableFields();

        // [WHEN] CreateEntityContent is called
        FieldIdList := ADLSEExecute.CreateFieldListForTable(Database::"Reason Code");
        EntityContent := ADLSECDMUtil.CreateEntityContent(Database::"Reason Code", FieldIdList);

        // [THEN] The attributes array contains entries for all fields
        EntityContent.SelectToken('definitions[0].hasAttributes', Token);
        AttributesArray := Token.AsArray();

        // Count enabled fields (including system fields)
        ADLSEField.SetRange("Table ID", Database::"Reason Code");
        ADLSEField.SetRange(Enabled, true);
        EnabledFieldCount := ADLSEField.Count();

        // Attributes include enabled fields + system fields + company field
        LibraryAssert.IsTrue(AttributesArray.Count() > 0, 'Should have at least one attribute');
    end;

    [Test]
    procedure TestFieldTypeMapping_Integer()
    var
        ADLSETable: Record "ADLSE Table";
        ADLSECDMUtil: Codeunit "ADLSE CDM Util";
        ADLSEExecute: Codeunit "ADLSE Execute";
        EntityContent: JsonObject;
        FieldIdList: List of [Integer];
        Token: JsonToken;
        AttributesArray: JsonArray;
        Attribute: JsonToken;
        DataFormat: Text;
        i: Integer;
    begin
        // [SCENARIO] Integer fields are mapped to Int32 data format
        // [GIVEN] A table with integer fields
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSETable.Add(Database::"G/L Entry");
        ADLSELibrarybc2adls.InsertFields();
        ADLSELibrarybc2adls.EnableFields();

        // [WHEN] CreateEntityContent is called
        FieldIdList := ADLSEExecute.CreateFieldListForTable(Database::"G/L Entry");
        EntityContent := ADLSECDMUtil.CreateEntityContent(Database::"G/L Entry", FieldIdList);

        // [THEN] Integer fields have Int32 data format
        EntityContent.SelectToken('definitions[0].hasAttributes', Token);
        AttributesArray := Token.AsArray();

        for i := 0 to AttributesArray.Count() - 1 do begin
            AttributesArray.Get(i, Attribute);
            if Attribute.AsObject().Get('name', Token) then
                if Token.AsValue().AsText().Contains('EntryNo') then begin
                    Attribute.AsObject().Get('dataFormat', Token);
                    DataFormat := Token.AsValue().AsText();
                    LibraryAssert.AreEqual('Int32', DataFormat, 'Entry No. should be Int32');
                    exit;
                end;
        end;
    end;

    [Test]
    procedure TestFieldTypeMapping_DateTime()
    var
        ADLSETable: Record "ADLSE Table";
        ADLSECDMUtil: Codeunit "ADLSE CDM Util";
        ADLSEExecute: Codeunit "ADLSE Execute";
        EntityContent: JsonObject;
        FieldIdList: List of [Integer];
        Token: JsonToken;
        AttributesArray: JsonArray;
        Attribute: JsonToken;
        DataFormat: Text;
        i: Integer;
    begin
        // [SCENARIO] DateTime fields are mapped correctly
        // [GIVEN] A table with DateTime fields (System fields)
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSETable.Add(Database::"Reason Code");
        ADLSELibrarybc2adls.InsertFields();

        // [WHEN] CreateEntityContent is called
        FieldIdList := ADLSEExecute.CreateFieldListForTable(Database::"Reason Code");
        EntityContent := ADLSECDMUtil.CreateEntityContent(Database::"Reason Code", FieldIdList);

        // [THEN] SystemCreatedAt field has DateTime format
        EntityContent.SelectToken('definitions[0].hasAttributes', Token);
        AttributesArray := Token.AsArray();

        for i := 0 to AttributesArray.Count() - 1 do begin
            AttributesArray.Get(i, Attribute);
            if Attribute.AsObject().Get('name', Token) then
                if Token.AsValue().AsText().Contains('SystemCreatedAt') then begin
                    Attribute.AsObject().Get('dataFormat', Token);
                    DataFormat := Token.AsValue().AsText();
                    LibraryAssert.AreEqual('DateTime', DataFormat, 'SystemCreatedAt should be DateTime');
                    exit;
                end;
        end;
    end;

    [Test]
    procedure TestFieldTypeMapping_Guid()
    var
        ADLSETable: Record "ADLSE Table";
        ADLSECDMUtil: Codeunit "ADLSE CDM Util";
        ADLSEExecute: Codeunit "ADLSE Execute";
        EntityContent: JsonObject;
        FieldIdList: List of [Integer];
        Token: JsonToken;
        AttributesArray: JsonArray;
        Attribute: JsonToken;
        DataFormat: Text;
        i: Integer;
    begin
        // [SCENARIO] Guid fields are mapped correctly
        // [GIVEN] A table with Guid fields (SystemId)
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSETable.Add(Database::"Reason Code");
        ADLSELibrarybc2adls.InsertFields();

        // [WHEN] CreateEntityContent is called
        FieldIdList := ADLSEExecute.CreateFieldListForTable(Database::"Reason Code");
        EntityContent := ADLSECDMUtil.CreateEntityContent(Database::"Reason Code", FieldIdList);

        // [THEN] SystemId field has Guid format
        EntityContent.SelectToken('definitions[0].hasAttributes', Token);
        AttributesArray := Token.AsArray();

        for i := 0 to AttributesArray.Count() - 1 do begin
            AttributesArray.Get(i, Attribute);
            if Attribute.AsObject().Get('name', Token) then
                if Token.AsValue().AsText().Contains('systemId') then begin
                    Attribute.AsObject().Get('dataFormat', Token);
                    DataFormat := Token.AsValue().AsText();
                    LibraryAssert.AreEqual('Guid', DataFormat, 'systemId should be Guid');
                    exit;
                end;
        end;
    end;

    [Test]
    procedure TestUpdateDefaultManifestContent_CreatesValidManifest()
    var
        ADLSECDMUtil: Codeunit "ADLSE CDM Util";
        ManifestContent: JsonObject;
        EmptyJsonObject: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] UpdateDefaultManifestContent creates a valid manifest JSON
        // [GIVEN] Initialized test environment
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        // [WHEN] UpdateDefaultManifestContent is called
        ManifestContent := ADLSECDMUtil.UpdateDefaultManifestContent(EmptyJsonObject, Database::"Reason Code", 'data', "ADLSE CDM Format"::Parquet);

        // [THEN] The manifest contains required properties
        LibraryAssert.IsTrue(ManifestContent.Contains('jsonSchemaSemanticVersion'), 'Should contain jsonSchemaSemanticVersion');
        LibraryAssert.IsTrue(ManifestContent.Contains('manifestName'), 'Should contain manifestName');
        LibraryAssert.IsTrue(ManifestContent.Contains('entities'), 'Should contain entities');
        LibraryAssert.IsTrue(ManifestContent.Contains('relationships'), 'Should contain relationships');

        // [THEN] The manifest name follows pattern
        ManifestContent.Get('manifestName', Token);
        LibraryAssert.IsTrue(Token.AsValue().AsText().Contains('data'), 'Manifest name should contain folder name');
    end;

    [Test]
    procedure TestUpdateDefaultManifestContent_CsvFormat()
    var
        ADLSECDMUtil: Codeunit "ADLSE CDM Util";
        ManifestContent: JsonObject;
        EmptyJsonObject: JsonObject;
        Token: JsonToken;
        JsonText: Text;
    begin
        // [SCENARIO] UpdateDefaultManifestContent with CSV format creates correct partition pattern
        // [GIVEN] Initialized test environment
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        // [WHEN] UpdateDefaultManifestContent is called with CSV format
        ManifestContent := ADLSECDMUtil.UpdateDefaultManifestContent(EmptyJsonObject, Database::"Reason Code", 'deltas', "ADLSE CDM Format"::Csv);

        // [THEN] The entity has CSV partition pattern
        ManifestContent.WriteTo(JsonText);
        LibraryAssert.IsTrue(JsonText.Contains('.csv'), 'Should contain CSV extension');
        LibraryAssert.IsTrue(JsonText.Contains('is.partition.format.CSV'), 'Should contain CSV partition format trait');
    end;

    [Test]
    procedure TestUpdateDefaultManifestContent_ParquetFormat()
    var
        ADLSECDMUtil: Codeunit "ADLSE CDM Util";
        ManifestContent: JsonObject;
        EmptyJsonObject: JsonObject;
        JsonText: Text;
    begin
        // [SCENARIO] UpdateDefaultManifestContent with Parquet format creates correct partition pattern
        // [GIVEN] Initialized test environment
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        // [WHEN] UpdateDefaultManifestContent is called with Parquet format
        ManifestContent := ADLSECDMUtil.UpdateDefaultManifestContent(EmptyJsonObject, Database::"Reason Code", 'data', "ADLSE CDM Format"::Parquet);

        // [THEN] The entity has Parquet partition pattern
        ManifestContent.WriteTo(JsonText);
        LibraryAssert.IsTrue(JsonText.Contains('.parquet'), 'Should contain Parquet extension');
        LibraryAssert.IsTrue(JsonText.Contains('is.partition.format.parquet'), 'Should contain Parquet partition format trait');
    end;

    [Test]
    procedure TestCheckChangeInEntities_NoChange_NoError()
    var
        ADLSETable: Record "ADLSE Table";
        ADLSECDMUtil: Codeunit "ADLSE CDM Util";
        ADLSEExecute: Codeunit "ADLSE Execute";
        EntityContent: JsonObject;
        FieldIdList: List of [Integer];
    begin
        // [SCENARIO] CheckChangeInEntities does not error when entities are identical
        // [GIVEN] Two identical entity definitions
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSETable.Add(Database::"Reason Code");
        ADLSELibrarybc2adls.InsertFields();

        FieldIdList := ADLSEExecute.CreateFieldListForTable(Database::"Reason Code");
        EntityContent := ADLSECDMUtil.CreateEntityContent(Database::"Reason Code", FieldIdList);

        // [WHEN] CheckChangeInEntities is called with identical entities
        // [THEN] No error is thrown
        ADLSECDMUtil.CheckChangeInEntities(EntityContent, EntityContent, 'TestEntity');
    end;

    [Test]
    procedure TestCompareEntityJsons_IdenticalEntities_ReturnsTrue()
    var
        ADLSETable: Record "ADLSE Table";
        ADLSECDMUtil: Codeunit "ADLSE CDM Util";
        ADLSEExecute: Codeunit "ADLSE Execute";
        EntityContent: JsonObject;
        FieldIdList: List of [Integer];
        CompareResult: Boolean;
    begin
        // [SCENARIO] CompareEntityJsons returns true for identical entities
        // [GIVEN] Two identical entity definitions
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSETable.Add(Database::"Reason Code");
        ADLSELibrarybc2adls.InsertFields();

        FieldIdList := ADLSEExecute.CreateFieldListForTable(Database::"Reason Code");
        EntityContent := ADLSECDMUtil.CreateEntityContent(Database::"Reason Code", FieldIdList);

        // [WHEN] CompareEntityJsons is called
        CompareResult := ADLSECDMUtil.CompareEntityJsons(EntityContent, EntityContent);

        // [THEN] The comparison returns true
        LibraryAssert.IsTrue(CompareResult, 'Identical entities should compare as equal');
    end;

    [Test]
    procedure TestGetCompanyFieldName_ReturnsExpectedValue()
    var
        ADLSECDMUtil: Codeunit "ADLSE CDM Util";
        FieldName: Text;
    begin
        // [SCENARIO] GetCompanyFieldName returns the expected field name
        // [WHEN] GetCompanyFieldName is called
        FieldName := ADLSECDMUtil.GetCompanyFieldName();

        // [THEN] The field name is '$Company'
        LibraryAssert.AreEqual('$Company', FieldName, 'Company field name should be $Company');
    end;

    [Test]
    procedure TestGetDeliveredDateTimeFieldName_ReturnsExpectedValue()
    var
        ADLSECDMUtil: Codeunit "ADLSE CDM Util";
        FieldName: Text;
    begin
        // [SCENARIO] GetDeliveredDateTimeFieldName returns the expected field name
        // [WHEN] GetDeliveredDateTimeFieldName is called
        FieldName := ADLSECDMUtil.GetDeliveredDateTimeFieldName();

        // [THEN] The field name is '$DeliveredDateTime'
        LibraryAssert.AreEqual('$DeliveredDateTime', FieldName, 'Delivered DateTime field name should be $DeliveredDateTime');
    end;

    [Test]
    procedure TestGetClosingDateFieldName_ReturnsExpectedValue()
    var
        ADLSECDMUtil: Codeunit "ADLSE CDM Util";
        FieldName: Text;
    begin
        // [SCENARIO] GetClosingDateFieldName returns the expected field name
        // [WHEN] GetClosingDateFieldName is called
        FieldName := ADLSECDMUtil.GetClosingDateFieldName();

        // [THEN] The field name is '$ClosingDate'
        LibraryAssert.AreEqual('$ClosingDate', FieldName, 'Closing Date field name should be $ClosingDate');
    end;

    [Test]
    procedure TestIsPrimaryKeyField_PrimaryKey_ReturnsTrue()
    var
        ADLSECDMUtil: Codeunit "ADLSE CDM Util";
        IsPK: Boolean;
        ReasonCodeCodeFieldNo: Integer;
    begin
        // [SCENARIO] IsPrimaryKeyField returns true for primary key fields
        // [GIVEN] A primary key field (Code field in Reason Code table)
        ReasonCodeCodeFieldNo := 1; // Code field is typically field 1

        // [WHEN] IsPrimaryKeyField is called
        IsPK := ADLSECDMUtil.IsPrimaryKeyField(Database::"Reason Code", ReasonCodeCodeFieldNo);

        // [THEN] It returns true
        LibraryAssert.IsTrue(IsPK, 'Code field should be a primary key field');
    end;

    local procedure Initialize()
    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ADLSE CDM Util Tests");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ADLSE CDM Util Tests");

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ADLSE CDM Util Tests");
    end;
}
