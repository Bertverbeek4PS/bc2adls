codeunit 85576 "ADLSE Setup Validation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] bc2adls Setup Validation
    end;

    var
        ADLSELibrarybc2adls: Codeunit "ADLSE Library - bc2adls";
        LibraryAssert: Codeunit "Library Assert";
        LibraryUtility: Codeunit "Library - Utility";
        "Storage Type": Enum "ADLSE Storage Type";
        IsInitialized: Boolean;

    [Test]
    procedure TestContainerValidation_ValidLowercase()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        // [SCENARIO] Valid lowercase container name is accepted
        // [GIVEN] Setup record
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSESetup.Get(0);

        // [WHEN] Valid lowercase container name is set
        ADLSESetup.Validate(Container, 'validcontainer123');

        // [THEN] No error occurs
        LibraryAssert.AreEqual('validcontainer123', ADLSESetup.Container, 'Container name should be accepted');
    end;

    [Test]
    procedure TestContainerValidation_ValidWithDashes()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        // [SCENARIO] Container name with dashes is accepted
        // [GIVEN] Setup record
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSESetup.Get(0);

        // [WHEN] Container name with dashes is set
        ADLSESetup.Validate(Container, 'valid-container-name');

        // [THEN] No error occurs
        LibraryAssert.AreEqual('valid-container-name', ADLSESetup.Container, 'Container name with dashes should be accepted');
    end;

    [Test]
    procedure TestContainerValidation_InvalidUppercase()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        // [SCENARIO] Container name with uppercase letters is rejected
        // [GIVEN] Setup record
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSESetup.Get(0);

        // [WHEN] Container name with uppercase is set
        // [THEN] An error is thrown
        asserterror ADLSESetup.Validate(Container, 'InvalidContainer');
        LibraryAssert.ExpectedError('container name is in an incorrect format');
    end;

    [Test]
    procedure TestContainerValidation_InvalidDoubleDash()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        // [SCENARIO] Container name with double dashes is rejected
        // [GIVEN] Setup record
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSESetup.Get(0);

        // [WHEN] Container name with double dashes is set
        // [THEN] An error is thrown
        asserterror ADLSESetup.Validate(Container, 'invalid--container');
        LibraryAssert.ExpectedError('container name is in an incorrect format');
    end;

    [Test]
    procedure TestContainerValidation_TooShort()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        // [SCENARIO] Container name that is too short is rejected
        // [GIVEN] Setup record
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSESetup.Get(0);

        // [WHEN] Container name shorter than 3 characters is set
        // [THEN] An error is thrown
        asserterror ADLSESetup.Validate(Container, 'ab');
        LibraryAssert.ExpectedError('container name is in an incorrect format');
    end;

    [Test]
    procedure TestContainerValidation_TooLong()
    var
        ADLSESetup: Record "ADLSE Setup";
        LongName: Text;
    begin
        // [SCENARIO] Container name that is too long is rejected
        // [GIVEN] Setup record
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSESetup.Get(0);

        // [WHEN] Container name longer than 63 characters is set
        LongName := LibraryUtility.GenerateRandomNumericText(70);

        // [THEN] An error is thrown
        asserterror ADLSESetup.Validate(Container, LongName);
        LibraryAssert.ExpectedError('must be less than or equal to 63 characters');
    end;

    [Test]
    procedure TestAccountNameValidation_Valid()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        // [SCENARIO] Valid account name is accepted
        // [GIVEN] Setup record
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSESetup.Get(0);

        // [WHEN] Valid account name is set
        ADLSESetup.Validate("Account Name", 'validaccount123');

        // [THEN] No error occurs
        LibraryAssert.AreEqual('validaccount123', ADLSESetup."Account Name", 'Account name should be accepted');
    end;

    [Test]
    procedure TestAccountNameValidation_InvalidUppercase()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        // [SCENARIO] Account name with uppercase letters is rejected
        // [GIVEN] Setup record
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSESetup.Get(0);

        // [WHEN] Account name with uppercase is set
        // [THEN] An error is thrown
        asserterror ADLSESetup.Validate("Account Name", 'InvalidAccount');
        LibraryAssert.ExpectedError('account name is in an incorrect format');
    end;

    [Test]
    procedure TestAccountNameValidation_TooShort()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        // [SCENARIO] Account name that is too short is rejected
        // [GIVEN] Setup record
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSESetup.Get(0);

        // [WHEN] Account name shorter than 3 characters is set
        // [THEN] An error is thrown
        asserterror ADLSESetup.Validate("Account Name", 'ab');
        LibraryAssert.ExpectedError('account name is in an incorrect format');
    end;

    [Test]
    procedure TestWorkspaceValidation_ValidName()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        // [SCENARIO] Valid workspace name is accepted
        // [GIVEN] Setup record for Microsoft Fabric
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Microsoft Fabric");
        ADLSESetup.Get(0);

        // [WHEN] Valid workspace name is set
        ADLSESetup.Validate(Workspace, 'ValidWorkspace');

        // [THEN] No error occurs
        LibraryAssert.AreEqual('ValidWorkspace', ADLSESetup.Workspace, 'Workspace name should be accepted');
    end;

    [Test]
    procedure TestWorkspaceValidation_ValidGuid()
    var
        ADLSESetup: Record "ADLSE Setup";
        TestGuid: Guid;
    begin
        // [SCENARIO] Valid workspace GUID is accepted
        // [GIVEN] Setup record for Microsoft Fabric
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Microsoft Fabric");
        ADLSESetup.Get(0);

        // [WHEN] Valid GUID is set as workspace
        TestGuid := CreateGuid();
        ADLSESetup.Validate(Workspace, Format(TestGuid));

        // [THEN] No error occurs
    end;

    [Test]
    procedure TestLakehouseValidation_ValidName()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        // [SCENARIO] Valid lakehouse name is accepted
        // [GIVEN] Setup record for Microsoft Fabric
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Microsoft Fabric");
        ADLSESetup.Get(0);

        // [WHEN] Valid lakehouse name is set
        ADLSESetup.Validate(Lakehouse, 'ValidLakehouse');

        // [THEN] No error occurs
        LibraryAssert.AreEqual('ValidLakehouse', ADLSESetup.Lakehouse, 'Lakehouse name should be accepted');
    end;

    [Test]
    procedure TestLakehouseValidation_ValidGuid()
    var
        ADLSESetup: Record "ADLSE Setup";
        TestGuid: Guid;
    begin
        // [SCENARIO] Valid lakehouse GUID is accepted
        // [GIVEN] Setup record for Microsoft Fabric
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Microsoft Fabric");
        ADLSESetup.Get(0);

        // [WHEN] Valid GUID is set as lakehouse
        TestGuid := CreateGuid();
        ADLSESetup.Validate(Lakehouse, Format(TestGuid));

        // [THEN] No error occurs
    end;

    [Test]
    procedure TestMaxPayloadSizeMiB_ValidRange()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        // [SCENARIO] MaxPayloadSizeMiB accepts values within valid range
        // [GIVEN] Setup record
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSESetup.Get(0);

        // [WHEN] Valid payload size is set
        ADLSESetup.Validate(MaxPayloadSizeMiB, 100);

        // [THEN] No error occurs
        LibraryAssert.AreEqual(100, ADLSESetup.MaxPayloadSizeMiB, 'Payload size should be accepted');
    end;

    [Test]
    procedure TestStorageType_OpenMirroring_SetsDeleteTable()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        // [SCENARIO] Setting storage type to Open Mirroring automatically sets Delete Table
        // [GIVEN] Setup record
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSESetup.Get(0);
        ADLSESetup."Delete Table" := false;
        ADLSESetup.Modify();

        // [WHEN] Storage type is changed to Open Mirroring
        ADLSESetup.Validate("Storage Type", "ADLSE Storage Type"::"Open Mirroring");

        // [THEN] Delete Table is set to true
        LibraryAssert.IsTrue(ADLSESetup."Delete Table", 'Delete Table should be true for Open Mirroring');
    end;

    [Test]
    procedure TestDataFormat_DefaultIsParquet()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        // [SCENARIO] Default data format is Parquet
        // [GIVEN] A new setup record
        Initialize();
        ADLSELibrarybc2adls.CleanUp();

        ADLSESetup.GetOrCreate();

        // [THEN] Data format defaults to Parquet
        LibraryAssert.AreEqual("ADLSE CDM Format"::Parquet, ADLSESetup.DataFormat, 'Default data format should be Parquet');
    end;

    [Test]
    procedure TestEmitTelemetry_DefaultIsTrue()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        // [SCENARIO] Default emit telemetry is true
        // [GIVEN] A new setup record
        Initialize();
        ADLSELibrarybc2adls.CleanUp();

        ADLSESetup.GetOrCreate();

        // [THEN] Emit telemetry defaults to true
        LibraryAssert.IsTrue(ADLSESetup."Emit telemetry", 'Default emit telemetry should be true');
    end;

    [Test]
    procedure TestSchemaExported_BlocksEnumIntegerChange()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        // [SCENARIO] Changing Export Enum as Integer after schema export is blocked
        // [GIVEN] Setup with schema already exported
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSESetup.Get(0);
        ADLSESetup."Schema Exported On" := CurrentDateTime();
        ADLSESetup.Modify();

        // [WHEN] Export Enum as Integer is changed
        // [THEN] An error is thrown
        asserterror ADLSESetup.Validate("Export Enum as Integer", true);
        LibraryAssert.ExpectedError('Schema already exported');
    end;

    [Test]
    procedure TestGetSingleton_NoSetup_ThrowsError()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        // [SCENARIO] GetSingleton throws error when no setup exists
        // [GIVEN] No setup record
        Initialize();
        ADLSELibrarybc2adls.CleanUp();

        // [WHEN] GetSingleton is called
        // [THEN] An error is thrown
        asserterror ADLSESetup.GetSingleton();
        LibraryAssert.ExpectedError('No record on this table exists');
    end;

    [Test]
    procedure TestGetOrCreate_CreatesIfNotExists()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        // [SCENARIO] GetOrCreate creates setup if it doesn't exist
        // [GIVEN] No setup record
        Initialize();
        ADLSELibrarybc2adls.CleanUp();

        // [WHEN] GetOrCreate is called
        ADLSESetup.GetOrCreate();

        // [THEN] Setup exists
        LibraryAssert.IsTrue(ADLSESetup.Exists(), 'Setup should be created');
    end;

    [Test]
    procedure TestCheckSchemaExported_NoSchema_ThrowsError()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        // [SCENARIO] CheckSchemaExported throws error when schema not exported
        // [GIVEN] Setup without schema exported
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSESetup.Get(0);
        ADLSESetup."Schema Exported On" := 0DT;
        ADLSESetup.Modify();

        // [WHEN] CheckSchemaExported is called
        // [THEN] An error is thrown
        asserterror ADLSESetup.CheckSchemaExported();
        LibraryAssert.ExpectedError('No schema has been exported');
    end;

    [Test]
    procedure TestGetStorageType_ReturnsCorrectType()
    var
        ADLSESetup: Record "ADLSE Setup";
        StorageTypeResult: Enum "ADLSE Storage Type";
    begin
        // [SCENARIO] GetStorageType returns the configured storage type
        // [GIVEN] Setup with Azure Data Lake storage type
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        // [WHEN] GetStorageType is called
        StorageTypeResult := ADLSESetup.GetStorageType();

        // [THEN] Returns Azure Data Lake
        LibraryAssert.AreEqual("ADLSE Storage Type"::"Azure Data Lake", StorageTypeResult, 'Should return Azure Data Lake');
    end;

    [Test]
    procedure TestTableAdd_ValidTable_Succeeds()
    var
        ADLSETable: Record "ADLSE Table";
    begin
        // [SCENARIO] Adding a valid table succeeds
        // [GIVEN] Setup exists
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        // [WHEN] A valid table is added
        ADLSETable.Add(Database::"Reason Code");

        // [THEN] The table is added and enabled
        LibraryAssert.IsTrue(ADLSETable.Get(Database::"Reason Code"), 'Table should be added');
        LibraryAssert.IsTrue(ADLSETable.Enabled, 'Table should be enabled');
    end;

    [Test]
    procedure TestFieldInsertForTable_InsertsFields()
    var
        ADLSETable: Record "ADLSE Table";
        ADLSEField: Record "ADLSE Field";
    begin
        // [SCENARIO] InsertForTable inserts fields for a table
        // [GIVEN] A table added for export
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSETable.Add(Database::"Reason Code");

        // [WHEN] Fields are inserted
        ADLSEField.InsertForTable(ADLSETable);

        // [THEN] Fields exist for the table
        ADLSEField.SetRange("Table ID", Database::"Reason Code");
        LibraryAssert.IsTrue(ADLSEField.Count() > 0, 'Fields should be inserted');
    end;

    local procedure Initialize()
    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ADLSE Setup Validation Tests");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ADLSE Setup Validation Tests");

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ADLSE Setup Validation Tests");
    end;
}
