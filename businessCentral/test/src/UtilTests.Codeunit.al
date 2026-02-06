codeunit 85570 "ADLSE Util Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] bc2adls Util
    end;

    var
        ADLSELibrarybc2adls: Codeunit "ADLSE Library - bc2adls";
        LibraryAssert: Codeunit "Library Assert";
        "Storage Type": Enum "ADLSE Storage Type";
        IsInitialized: Boolean;

    [Test]
    procedure TestToText_Guid_RemovesBraces()
    var
        ADLSEUtil: Codeunit "ADLSE Util";
        TestGuid: Guid;
        Result: Text;
    begin
        // [SCENARIO] ToText converts a GUID to text without braces
        // [GIVEN] A GUID value
        TestGuid := CreateGuid();

        // [WHEN] ToText is called
        Result := ADLSEUtil.ToText(TestGuid);

        // [THEN] The result does not contain braces
        LibraryAssert.IsFalse(Result.Contains('{'), 'Result should not contain opening brace');
        LibraryAssert.IsFalse(Result.Contains('}'), 'Result should not contain closing brace');
    end;

    [Test]
    procedure TestConcatenate_MultipleItems_ReturnsCommaSeparated()
    var
        ADLSEUtil: Codeunit "ADLSE Util";
        Items: List of [Text];
        Result: Text;
    begin
        // [SCENARIO] Concatenate joins list items with commas
        // [GIVEN] A list of text items
        Items.Add('Item1');
        Items.Add('Item2');
        Items.Add('Item3');

        // [WHEN] Concatenate is called
        Result := ADLSEUtil.Concatenate(Items);

        // [THEN] Items are joined with commas
        LibraryAssert.AreEqual('Item1, Item2, Item3', Result, 'Items should be comma-separated');
    end;

    [Test]
    procedure TestConcatenate_SingleItem_ReturnsItem()
    var
        ADLSEUtil: Codeunit "ADLSE Util";
        Items: List of [Text];
        Result: Text;
    begin
        // [SCENARIO] Concatenate with single item returns just that item
        // [GIVEN] A list with one item
        Items.Add('SingleItem');

        // [WHEN] Concatenate is called
        Result := ADLSEUtil.Concatenate(Items);

        // [THEN] Returns the single item
        LibraryAssert.AreEqual('SingleItem', Result, 'Should return single item without comma');
    end;

    [Test]
    procedure TestGetTableCaption_ValidTable_ReturnsCaption()
    var
        ADLSEUtil: Codeunit "ADLSE Util";
        Caption: Text;
    begin
        // [SCENARIO] GetTableCaption returns the caption for a valid table
        // [WHEN] GetTableCaption is called with a valid table ID
        Caption := ADLSEUtil.GetTableCaption(Database::"Reason Code");

        // [THEN] The caption is returned
        LibraryAssert.AreNotEqual('', Caption, 'Caption should not be empty');
    end;

    [Test]
    procedure TestGetDataLakeCompliantTableName_ReturnsValidName()
    var
        ADLSEUtil: Codeunit "ADLSE Util";
        TableName: Text;
    begin
        // [SCENARIO] GetDataLakeCompliantTableName returns a valid data lake name
        // [GIVEN] Setup exists
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        // [WHEN] GetDataLakeCompliantTableName is called
        TableName := ADLSEUtil.GetDataLakeCompliantTableName(Database::"Reason Code");

        // [THEN] The name is not empty and contains expected format
        LibraryAssert.AreNotEqual('', TableName, 'Table name should not be empty');
        LibraryAssert.IsTrue(TableName.Contains('ReasonCode') or TableName.Contains('Reason'), 'Should contain table name');
    end;

    [Test]
    procedure TestGetDataLakeCompliantName_RemovesSpecialChars()
    var
        ADLSEUtil: Codeunit "ADLSE Util";
        Result: Text;
    begin
        // [SCENARIO] GetDataLakeCompliantName removes special characters
        // [GIVEN] Setup exists
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        // [WHEN] GetDataLakeCompliantName is called with special characters
        Result := ADLSEUtil.GetDataLakeCompliantName('Test Name With Spaces!@#');

        // [THEN] Special characters are removed
        LibraryAssert.IsFalse(Result.Contains(' '), 'Should not contain spaces');
        LibraryAssert.IsFalse(Result.Contains('!'), 'Should not contain exclamation');
        LibraryAssert.IsFalse(Result.Contains('@'), 'Should not contain at sign');
        LibraryAssert.IsFalse(Result.Contains('#'), 'Should not contain hash');
    end;

    [Test]
    procedure TestGetDataLakeCompliantName_KeepsAlphanumeric()
    var
        ADLSEUtil: Codeunit "ADLSE Util";
        Result: Text;
    begin
        // [SCENARIO] GetDataLakeCompliantName keeps alphanumeric characters
        // [GIVEN] Setup exists
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        // [WHEN] GetDataLakeCompliantName is called with alphanumeric name
        Result := ADLSEUtil.GetDataLakeCompliantName('Test123Name');

        // [THEN] Alphanumeric characters are kept
        LibraryAssert.AreEqual('Test123Name', Result, 'Alphanumeric characters should be preserved');
    end;

    [Test]
    procedure TestIsTablePerCompany_CompanyTable_ReturnsTrue()
    var
        ADLSEUtil: Codeunit "ADLSE Util";
        Result: Boolean;
    begin
        // [SCENARIO] IsTablePerCompany returns true for company-specific tables
        // [WHEN] IsTablePerCompany is called with a per-company table
        Result := ADLSEUtil.IsTablePerCompany(Database::"G/L Entry");

        // [THEN] Returns true
        LibraryAssert.IsTrue(Result, 'G/L Entry should be a per-company table');
    end;

    [Test]
    procedure TestCheckFieldTypeForExport_SupportedTypes_NoError()
    var
        Field: Record Field;
        ADLSEUtil: Codeunit "ADLSE Util";
    begin
        // [SCENARIO] CheckFieldTypeForExport does not error for supported field types
        // [GIVEN] A field with supported type (Integer)
        Field.SetRange(TableNo, Database::"Reason Code");
        Field.SetRange(Type, Field.Type::Code);
        if Field.FindFirst() then begin
            // [WHEN] CheckFieldTypeForExport is called
            // [THEN] No error is thrown
            ADLSEUtil.CheckFieldTypeForExport(Field);
        end;
    end;

    [Test]
    procedure TestCheckFieldTypeForExport_UnsupportedType_ThrowsError()
    var
        Field: Record Field;
        ADLSEUtil: Codeunit "ADLSE Util";
    begin
        // [SCENARIO] CheckFieldTypeForExport errors for unsupported field types
        // [GIVEN] A field with unsupported type (BLOB/Media)
        Field.SetRange(Type, Field.Type::BLOB);
        if Field.FindFirst() then begin
            // [WHEN] CheckFieldTypeForExport is called
            // [THEN] An error is thrown
            asserterror ADLSEUtil.CheckFieldTypeForExport(Field);
            LibraryAssert.ExpectedErrorCode('Dialog');
        end;
    end;

    [Test]
    procedure TestConvertFieldToText_IntegerField()
    var
        ReasonCode: Record "Reason Code";
        ADLSEUtil: Codeunit "ADLSE Util";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        Result: Text;
    begin
        // [SCENARIO] ConvertFieldToText converts integer fields correctly
        // [GIVEN] A record with an integer field value
        Initialize();

        // Use timestamp field which is BigInteger
        RecordRef.Open(Database::"Reason Code");
        if RecordRef.FindFirst() then begin
            FieldRef := RecordRef.Field(0); // Timestamp

            // [WHEN] ConvertFieldToText is called
            Result := ADLSEUtil.ConvertFieldToText(FieldRef);

            // [THEN] The result is a valid number string
            LibraryAssert.AreNotEqual('', Result, 'Result should not be empty');
        end;
        RecordRef.Close();
    end;

    [Test]
    procedure TestConvertFieldToText_TextField()
    var
        ReasonCode: Record "Reason Code";
        ADLSEUtil: Codeunit "ADLSE Util";
        LibraryERM: Codeunit "Library - ERM";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        Result: Text;
    begin
        // [SCENARIO] ConvertFieldToText converts text fields with proper quoting
        // [GIVEN] A record with a text field value
        Initialize();
        LibraryERM.CreateReasonCode(ReasonCode);

        RecordRef.GetTable(ReasonCode);
        FieldRef := RecordRef.Field(ReasonCode.FieldNo(Code)); // Code field

        // [WHEN] ConvertFieldToText is called
        Result := ADLSEUtil.ConvertFieldToText(FieldRef);

        // [THEN] The result is quoted
        LibraryAssert.IsTrue(Result.StartsWith('"'), 'Text should be quoted');
        LibraryAssert.IsTrue(Result.EndsWith('"'), 'Text should end with quote');
    end;

    [Test]
    procedure TestAddSystemFields_AddsRequiredFields()
    var
        ADLSEUtil: Codeunit "ADLSE Util";
        FieldIdList: List of [Integer];
    begin
        // [SCENARIO] AddSystemFields adds all required system fields
        // [WHEN] AddSystemFields is called
        ADLSEUtil.AddSystemFields(FieldIdList);

        // [THEN] The list contains system fields
        LibraryAssert.IsTrue(FieldIdList.Contains(0), 'Should contain timestamp field (0)');
        LibraryAssert.IsTrue(FieldIdList.Contains(2000000000), 'Should contain SystemId field');
        LibraryAssert.IsTrue(FieldIdList.Contains(2000000001), 'Should contain SystemCreatedAt field');
        LibraryAssert.IsTrue(FieldIdList.Contains(2000000002), 'Should contain SystemCreatedBy field');
        LibraryAssert.IsTrue(FieldIdList.Contains(2000000003), 'Should contain SystemModifiedAt field');
        LibraryAssert.IsTrue(FieldIdList.Contains(2000000004), 'Should contain SystemModifiedBy field');
    end;

    [Test]
    procedure TestCreateCsvHeader_IncludesFieldNames()
    var
        ADLSETable: Record "ADLSE Table";
        ADLSEUtil: Codeunit "ADLSE Util";
        ADLSEExecute: Codeunit "ADLSE Execute";
        RecordRef: RecordRef;
        FieldIdList: List of [Integer];
        Header: Text;
    begin
        // [SCENARIO] CreateCsvHeader creates a proper CSV header line
        // [GIVEN] A table with fields configured
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSETable.Add(Database::"Reason Code");
        ADLSELibrarybc2adls.InsertFields();

        RecordRef.Open(Database::"Reason Code");
        FieldIdList := ADLSEExecute.CreateFieldListForTable(Database::"Reason Code");

        // [WHEN] CreateCsvHeader is called
        Header := ADLSEUtil.CreateCsvHeader(RecordRef, FieldIdList);

        // [THEN] The header contains field names separated by commas
        LibraryAssert.IsTrue(Header.Contains(','), 'Header should contain comma separators');
        LibraryAssert.AreNotEqual('', Header, 'Header should not be empty');
        RecordRef.Close();
    end;

    [Test]
    procedure TestGetTextValueForKeyInJson_ReturnsValue()
    var
        ADLSEUtil: Codeunit "ADLSE Util";
        TestObject: JsonObject;
        Result: Text;
    begin
        // [SCENARIO] GetTextValueForKeyInJson extracts text value from JSON
        // [GIVEN] A JSON object with a text property
        TestObject.Add('testKey', 'testValue');

        // [WHEN] GetTextValueForKeyInJson is called
        Result := ADLSEUtil.GetTextValueForKeyInJson(TestObject, 'testKey');

        // [THEN] The value is returned
        LibraryAssert.AreEqual('testValue', Result, 'Should return the value for the key');
    end;

    [Test]
    procedure TestJsonTokenExistsWithValueInArray_Exists_ReturnsTrue()
    var
        ADLSEUtil: Codeunit "ADLSE Util";
        TestArray: JsonArray;
        TestObject: JsonObject;
        Result: Boolean;
    begin
        // [SCENARIO] JsonTokenExistsWithValueInArray returns true when value exists
        // [GIVEN] A JSON array with an object containing a property
        TestObject.Add('name', 'TestEntity');
        TestArray.Add(TestObject);

        // [WHEN] JsonTokenExistsWithValueInArray is called
        Result := ADLSEUtil.JsonTokenExistsWithValueInArray(TestArray, 'name', 'TestEntity');

        // [THEN] Returns true
        LibraryAssert.IsTrue(Result, 'Should find the value in the array');
    end;

    [Test]
    procedure TestJsonTokenExistsWithValueInArray_NotExists_ReturnsFalse()
    var
        ADLSEUtil: Codeunit "ADLSE Util";
        TestArray: JsonArray;
        TestObject: JsonObject;
        Result: Boolean;
    begin
        // [SCENARIO] JsonTokenExistsWithValueInArray returns false when value doesn't exist
        // [GIVEN] A JSON array with an object not containing the searched value
        TestObject.Add('name', 'OtherEntity');
        TestArray.Add(TestObject);

        // [WHEN] JsonTokenExistsWithValueInArray is called
        Result := ADLSEUtil.JsonTokenExistsWithValueInArray(TestArray, 'name', 'TestEntity');

        // [THEN] Returns false
        LibraryAssert.IsFalse(Result, 'Should not find the value in the array');
    end;

    local procedure Initialize()
    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ADLSE Util Tests");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ADLSE Util Tests");

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ADLSE Util Tests");
    end;
}
