codeunit 85565 "ADLSE Setup Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    trigger OnRun()
    begin
        // [FEATURE] bc2adls Setup
    end;

    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSETable: Record "ADLSE Table";
        ADLSEField: Record "ADLSE Field";
        ADLSLibrarybc2adls: Codeunit "ADLSE Library - bc2adls";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        "Storage Type": Enum "ADLSE Storage Type";
        IsInitialized: Boolean;
        InsertedTable: Integer;

    [Test]
    procedure TestCorrectNameContainer()
    var
        ContainerName: Text;
    begin
        // [SCENARIO 102] Test Field Container with to short name
        // [GIVEN] Initialized test environment
        Initialize();
        // [GIVEN] Setup bc2adls table for Azure Blob Storage
        if not ADLSESetup.Get() then
            ADLSLibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        // [GIVEN]
        ContainerName := LibraryUtility.GenerateRandomNumericText(LibraryRandom.RandIntInRange(3, 63));

        // [WHEN] Container name is set to "TestContainer"
        ADLSESetup.Validate("Container", ContainerName);

        // [THEN] An error is thrown
        Assert.AreEqual(ADLSESetup.Container, ContainerName, 'Container names are not equal.');
    end;

    [Test]
    procedure TestCorrectNameContainerWithCapitals()
    var
        ContainerNameIncorrectFormatErr: Label 'The container name is in an incorrect format.';
    begin
        // [SCENARIO 101] Test Field Container with capitals
        // [GIVEN] Initialized test environment
        Initialize();
        // [GIVEN] Setup bc2adls table for Azure Blob Storage
        if not ADLSESetup.Get() then
            ADLSLibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        // [WHEN] Container name is set to "TestContainer"
        asserterror ADLSESetup.Validate("Container", 'TestContainer');

        // [THEN] An error is thrown
        Assert.ExpectedError(ContainerNameIncorrectFormatErr);
    end;

    [Test]
    procedure TestCorrectNameContainerWithMultipleDashesTogether()
    var
        ContainerNameIncorrectFormatErr: Label 'The container name is in an incorrect format.';
    begin
        // [SCENARIO 102] Test Field Container with multiple dashes together
        // [GIVEN] Initialized test environment
        Initialize();
        // [GIVEN] Setup bc2adls table for Azure Blob Storage
        if not ADLSESetup.Get() then
            ADLSLibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        // [WHEN] Container name is set to "TestContainer"
        asserterror ADLSESetup.Validate("Container", 'Test--Container');

        // [THEN] An error is thrown
        Assert.ExpectedError(ContainerNameIncorrectFormatErr);
    end;

    [Test]
    procedure TestCorrectNameContainerWithToLong()
    begin
        // [SCENARIO 102] Test Field Container with to long name
        // [GIVEN] Initialized test environment
        Initialize();
        // [GIVEN] Setup bc2adls table for Azure Blob Storage
        if not ADLSESetup.Get() then
            ADLSLibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        // [WHEN] Container name is set to "TestContainer"
        asserterror ADLSESetup.Validate("Container", LibraryUtility.GenerateRandomNumericText(70));

        // [THEN] An error is thrown
        Assert.ExpectedError('The length of the string is 70, but it must be less than or equal to 63 characters.');
    end;

    [Test]
    procedure TestCorrectNameContainerWithToShort()
    var
        ContainerNameIncorrectFormatErr: Label 'The container name is in an incorrect format.';
    begin
        // [SCENARIO 102] Test Field Container with to short name
        // [GIVEN] Initialized test environment
        Initialize();
        // [GIVEN] Setup bc2adls table for Azure Blob Storage
        if not ADLSESetup.Get() then
            ADLSLibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        // [WHEN] Container name is set to "TestContainer"
        asserterror ADLSESetup.Validate("Container", LibraryUtility.GenerateRandomNumericText(2));

        // [THEN] An error is thrown
        Assert.ExpectedError(ContainerNameIncorrectFormatErr);
    end;

    [Test]
    procedure InsertTableForExport()
    begin
        // [SCENARIO 001] Add a table for export
        // [GIVEN] Initialized test environment
        Initialize();
        // [GIVEN] Setup bc2adls table for Azure Blob Storage
        ADLSLibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        // [WHEN] Insert a table for export
        InsertedTable := ADLSLibrarybc2adls.InsertTable();
        ADLSETable := ADLSLibrarybc2adls.GetRandomTable();

        // [THEN] Check if the table is inserted
        Assert.AreEqual(ADLSETable."Table ID", InsertedTable, 'Tables are equal');

    end;

    local procedure Initialize()
    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";

    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ADLSE Field API Tests");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ADLSE Field API Tests");

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ADLSE Field API Tests");
    end;
}