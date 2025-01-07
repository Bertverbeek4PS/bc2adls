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
        ADLSELibrarybc2adls: Codeunit "ADLSE Library - bc2adls";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryAssert: Codeunit "Library Assert";
        LibraryDialogHandler: Codeunit "Library - Dialog Handler";
        "Storage Type": Enum "ADLSE Storage Type";
        IsInitialized: Boolean;

    [Test]
    procedure TestCorrectNameContainer()
    var
        ContainerName: Text;
    begin
        // [SCENARIO 101] Test Field Container with to short name
        // [GIVEN] Initialized test environment
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        // [GIVEN] Setup bc2adls table for Azure Blob Storage
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        // [GIVEN]
        ContainerName := LibraryUtility.GenerateRandomNumericText(LibraryRandom.RandIntInRange(3, 63));

        // [WHEN] Container name is set to "TestContainer"
        ADLSESetup.Validate("Container", ContainerName);

        // [THEN] An error is thrown
        LibraryAssert.AreEqual(ADLSESetup.Container, ContainerName, 'Container names are not equal.');
    end;

    [Test]
    procedure TestCorrectNameContainerWithCapitals()
    var
        ContainerNameIncorrectFormatErr: Label 'The container name is in an incorrect format.';
    begin
        // [SCENARIO 102] Test Field Container with capitals
        // [GIVEN] Initialized test environment
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        // [GIVEN] Setup bc2adls table for Azure Blob Storage
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        // [WHEN] Container name is set to "TestContainer"
        asserterror ADLSESetup.Validate("Container", 'TestContainer');

        // [THEN] An error is thrown
        LibraryAssert.ExpectedError(ContainerNameIncorrectFormatErr);
    end;

    [Test]
    procedure TestCorrectNameContainerWithMultipleDashesTogether()
    var
        ContainerNameIncorrectFormatErr: Label 'The container name is in an incorrect format.';
    begin
        // [SCENARIO 103] Test Field Container with multiple dashes together
        // [GIVEN] Initialized test environment
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        // [GIVEN] Setup bc2adls table for Azure Blob Storage
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        // [WHEN] Container name is set to "TestContainer"
        asserterror ADLSESetup.Validate("Container", 'Test--Container');

        // [THEN] An error is thrown
        LibraryAssert.ExpectedError(ContainerNameIncorrectFormatErr);
    end;

    [Test]
    procedure TestCorrectNameContainerWithToLong()
    begin
        // [SCENARIO 104] Test Field Container with to long name
        // [GIVEN] Initialized test environment
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        // [GIVEN] Setup bc2adls table for Azure Blob Storage
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        // [WHEN] Container name is set to "TestContainer"
        asserterror ADLSESetup.Validate("Container", LibraryUtility.GenerateRandomNumericText(70));

        // [THEN] An error is thrown
        LibraryAssert.ExpectedError('The length of the string is 70, but it must be less than or equal to 63 characters.');
    end;

    [Test]
    procedure TestCorrectNameContainerWithToShort()
    var
        ContainerNameIncorrectFormatErr: Label 'The container name is in an incorrect format.';
    begin
        // [SCENARIO 105] Test Field Container with to short name
        // [GIVEN] Initialized test environment
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        // [GIVEN] Setup bc2adls table for Azure Blob Storage
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        // [WHEN] Container name is set to "TestContainer"
        asserterror ADLSESetup.Validate("Container", LibraryUtility.GenerateRandomNumericText(2));

        // [THEN] An error is thrown
        LibraryAssert.ExpectedError(ContainerNameIncorrectFormatErr);
    end;

    [Test]
    procedure InsertTableForExport()
    var
        InsertedTable: Integer;
    begin
        // [SCENARIO 106] Add a table for export
        // [GIVEN] Initialized test environment
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        // [GIVEN] Setup bc2adls table for Azure Blob Storage
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        // [WHEN] Insert a table for export
        InsertedTable := ADLSELibrarybc2adls.InsertTable();
        ADLSETable := ADLSELibrarybc2adls.GetRandomTable();

        // [THEN] Check if the table is inserted
        LibraryAssert.AreEqual(ADLSETable."Table ID", InsertedTable, 'Tables are not equal');
    end;

    [Test]
    procedure InsertFieldForExport()
    var
        InsertedTable: Integer;
        FieldId: Integer;
    begin
        // [SCENARIO 107] Add a field for export of an excisting table
        // [GIVEN] Initialized test environment
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        // [GIVEN] Setup bc2adls table for Azure Blob Storage
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        // [GIVEN] Insert a table for export
        InsertedTable := ADLSELibrarybc2adls.InsertTable();
        ADLSETable.Get(InsertedTable);
        ADLSELibrarybc2adls.InsertFields();
        FieldId := ADLSELibrarybc2adls.GetRandomField(ADLSETable);

        // [WHEN] A field is enabled for export
        ADLSELibrarybc2adls.EnableField(InsertedTable, FieldId);

        // [THEN] Check if the field is enabled
        ADLSEField.Get(InsertedTable, FieldId);
        LibraryAssert.AreEqual(ADLSETable."Table ID", InsertedTable, 'Tables are not equal');
        LibraryAssert.AreEqual(ADLSEField."Field ID", FieldId, 'Fields are not equal');
    end;

    [Test]
    procedure ScheduleAnExportforJobQueue()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ADLSEScheduleTaskAssignment: Report "ADLSE Schedule Task Assignment";
        JobScheduledTxt: Label 'The job has been scheduled. Please go to the Job Queue Entries page to locate it and make further changes.';
    begin
        // [SCENARIO 108] Schedule an export for the Job Queue
        // [GIVEN] Initialized test environment
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        LibraryDialogHandler.SetExpectedMessage(JobScheduledTxt);

        // [GIVEN] Setup bc2adls table for Azure Blob Storage
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        // [WHEN] Schedule an export for the Job Queue is triggerd        
        ADLSEScheduleTaskAssignment.CreateJobQueueEntry(JobQueueEntry);

        // [THEN] Check if the export is scheduled
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"ADLSE Schedule Task Assignment");
        LibraryAssert.RecordCount(JobQueueEntry, 1);
    end;

    local procedure Initialize()
    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";

    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ADLSE Setup Tests");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ADLSE Setup Tests");

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ADLSE Setup Tests");
    end;


    [MessageHandler]
    procedure MessageHandler(Message: Text[1024]);
    begin
        LibraryDialogHandler.HandleMessage(Message);
    end;
}