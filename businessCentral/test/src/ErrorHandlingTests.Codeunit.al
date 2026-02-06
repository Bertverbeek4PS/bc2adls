codeunit 85575 "ADLSE Error Handling Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] bc2adls Error Handling
    end;

    var
        ADLSELibrarybc2adls: Codeunit "ADLSE Library - bc2adls";
        LibraryAssert: Codeunit "Library Assert";
        LibraryERM: Codeunit "Library - ERM";
        "Storage Type": Enum "ADLSE Storage Type";
        IsInitialized: Boolean;

    [Test]
    procedure TestExport_MockSimulatesFailure()
    var
        ADLSEGen2UtilMockExtended: Codeunit "ADLSE Gen 2 Util Mock Extended";
        ADLSEGen2Util: Codeunit "ADLSE Gen 2 Util";
        ADLSECredentials: Codeunit "ADLSE Credentials";
        BlobExists: Boolean;
        Content: JsonObject;
    begin
        // [SCENARIO] Mock correctly simulates storage failure
        // [GIVEN] Mock configured to simulate failure
        Initialize();

        ADLSEGen2UtilMockExtended.SetSimulateFailure(true, 'Simulated storage failure');
        Session.BindSubscription(ADLSEGen2UtilMockExtended);

        // [WHEN] GetBlobContent is called (which triggers the mock)
        // [THEN] The simulated error is thrown
        asserterror Content := ADLSEGen2Util.GetBlobContent('test/path', ADLSECredentials, BlobExists);

        Session.UnbindSubscription(ADLSEGen2UtilMockExtended);

        // [THEN] The error message matches
        LibraryAssert.ExpectedError('Simulated storage failure');
    end;

    [Test]
    procedure TestTryCollectAndSendRecord_Failure_ReturnsFalse()
    var
        ADLSETable: Record "ADLSE Table";
        ReasonCode: Record "Reason Code";
        ADLSECommunication: Codeunit "ADLSE Communication";
        ADLSEExecute: Codeunit "ADLSE Execute";
        ADLSEGen2UtilMockExtended: Codeunit "ADLSE Gen 2 Util Mock Extended";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        FieldIdList: List of [Integer];
        LastTimestampExported: BigInteger;
        RecordTimestamp: BigInteger;
        Success: Boolean;
    begin
        // [SCENARIO] TryCollectAndSendRecord returns false on failure
        // [GIVEN] A configured table with simulated failure during send
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        ReasonCode.DeleteAll(false);
        LibraryERM.CreateReasonCode(ReasonCode);

        ADLSETable.Add(Database::"Reason Code");
        ADLSELibrarybc2adls.InsertFields();
        ADLSELibrarybc2adls.EnableFields();

        FieldIdList := ADLSEExecute.CreateFieldListForTable(Database::"Reason Code");

        ADLSEGen2UtilMockExtended.SetBlobExists(true);
        ADLSEGen2UtilMockExtended.SetSimulateFailure(true, 'Simulated send failure');
        Session.BindSubscription(ADLSEGen2UtilMockExtended);

        ADLSECommunication.Init(Database::"Reason Code", FieldIdList, 0, false);

        RecordRef.GetTable(ReasonCode);
        FieldRef := RecordRef.Field(0);
        Evaluate(RecordTimestamp, Format(FieldRef.Value()));

        // [WHEN] TryCollectAndSendRecord is called
        Success := ADLSECommunication.TryCollectAndSendRecord(RecordRef, RecordTimestamp, LastTimestampExported, false);

        Session.UnbindSubscription(ADLSEGen2UtilMockExtended);

        // [THEN] Returns false
        LibraryAssert.IsFalse(Success, 'Should return false on failure');
    end;

    [Test]
    procedure TestTryFinish_Failure_ReturnsFalse()
    var
        ADLSETable: Record "ADLSE Table";
        ReasonCode: Record "Reason Code";
        ADLSECommunication: Codeunit "ADLSE Communication";
        ADLSEExecute: Codeunit "ADLSE Execute";
        ADLSEGen2UtilMock: Codeunit "ADLSE Gen 2 Util Mock";
        ADLSEGen2UtilMockExtended: Codeunit "ADLSE Gen 2 Util Mock Extended";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        FieldIdList: List of [Integer];
        LastTimestampExported: BigInteger;
        RecordTimestamp: BigInteger;
        Success: Boolean;
    begin
        // [SCENARIO] TryFinish returns false on failure during flush
        // [GIVEN] A communication instance with data that fails during flush
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        ReasonCode.DeleteAll(false);
        LibraryERM.CreateReasonCode(ReasonCode);

        ADLSETable.Add(Database::"Reason Code");
        ADLSELibrarybc2adls.InsertFields();
        ADLSELibrarybc2adls.EnableFields();

        FieldIdList := ADLSEExecute.CreateFieldListForTable(Database::"Reason Code");

        // First collect data successfully
        ADLSEGen2UtilMock.SetBlobExists(true);
        Session.BindSubscription(ADLSEGen2UtilMock);

        ADLSECommunication.Init(Database::"Reason Code", FieldIdList, 0, false);

        RecordRef.GetTable(ReasonCode);
        FieldRef := RecordRef.Field(0);
        Evaluate(RecordTimestamp, Format(FieldRef.Value()));

        ADLSECommunication.TryCollectAndSendRecord(RecordRef, RecordTimestamp, LastTimestampExported, false);

        Session.UnbindSubscription(ADLSEGen2UtilMock);

        // Now simulate failure during finish
        ADLSEGen2UtilMockExtended.SetSimulateFailure(true, 'Simulated flush failure');
        Session.BindSubscription(ADLSEGen2UtilMockExtended);

        // [WHEN] TryFinish is called
        Success := ADLSECommunication.TryFinish(LastTimestampExported);

        Session.UnbindSubscription(ADLSEGen2UtilMockExtended);

        // [THEN] Returns false
        LibraryAssert.IsFalse(Success, 'Should return false on flush failure');
    end;

    [Test]
    procedure TestRunState_Failed_IsRecorded()
    var
        ADLSERun: Record "ADLSE Run";
        TableId: Integer;
    begin
        // [SCENARIO] Failed run state is recorded correctly
        // [GIVEN] A run that fails
        Initialize();
        TableId := Database::"Reason Code";

        // Delete any existing runs for this table
        ADLSERun.SetRange("Table ID", TableId);
        ADLSERun.DeleteAll();

        // [WHEN] A failed run is registered by starting and canceling
        ADLSERun.RegisterStarted(TableId);
        ADLSERun.CancelRun(TableId);

        // [THEN] The run is marked as failed
        ADLSERun.SetRange("Table ID", TableId);
        ADLSERun.FindLast();
        LibraryAssert.AreEqual(ADLSERun.State::Failed, ADLSERun.State, 'Run should be marked as failed');
    end;

    [Test]
    procedure TestRunState_Success_IsRecorded()
    var
        ADLSERun: Record "ADLSE Run";
        TableId: Integer;
    begin
        // [SCENARIO] Successful run state is recorded correctly
        // [GIVEN] A run that succeeds
        Initialize();
        TableId := Database::"Reason Code";

        // Delete any existing runs for this table
        ADLSERun.SetRange("Table ID", TableId);
        ADLSERun.DeleteAll();

        // [WHEN] A successful run is registered
        ADLSELibrarybc2adls.MockCreateExport(TableId);

        // [THEN] The run is marked as successful
        ADLSERun.SetRange("Table ID", TableId);
        ADLSERun.FindLast();
        LibraryAssert.AreEqual(ADLSERun.State::Success, ADLSERun.State, 'Run should be marked as successful');
    end;

    [Test]
    procedure TestCredentialsCheck_MissingCredentials_ThrowsError()
    var
        ADLSECredentials: Codeunit "ADLSE Credentials";
    begin
        // [SCENARIO] Missing credentials throws appropriate error
        // [GIVEN] Credentials are not set
        Initialize();
        ClearCredentials();

        // [WHEN] Check is called
        // [THEN] An error is thrown
        asserterror ADLSECredentials.Check();
        LibraryAssert.ExpectedError('No value found for');
    end;

    [Test]
    procedure TestSetupValidation_InvalidContainerName_ThrowsError()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        // [SCENARIO] Invalid container name throws validation error
        // [GIVEN] Setup record
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSESetup.Get(0);

        // [WHEN] Invalid container name is set (uppercase)
        // [THEN] An error is thrown
        asserterror ADLSESetup.Validate(Container, 'InvalidContainer');
        LibraryAssert.ExpectedError('container name is in an incorrect format');
    end;

    [Test]
    procedure TestSetupValidation_InvalidAccountName_ThrowsError()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        // [SCENARIO] Invalid account name throws validation error
        // [GIVEN] Setup record
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSESetup.Get(0);

        // [WHEN] Invalid account name is set (uppercase)
        // [THEN] An error is thrown
        asserterror ADLSESetup.Validate("Account Name", 'InvalidAccountName');
        LibraryAssert.ExpectedError('account name is in an incorrect format');
    end;

    [Test]
    procedure TestFieldTypeNotSupported_ThrowsError()
    var
        Field: Record Field;
        ADLSEUtil: Codeunit "ADLSE Util";
    begin
        // [SCENARIO] Unsupported field type throws error
        // [GIVEN] A field with unsupported type (BLOB)
        Initialize();

        Field.SetRange(Type, Field.Type::BLOB);
        if Field.FindFirst() then begin
            // [WHEN] CheckFieldTypeForExport is called
            // [THEN] An error is thrown
            asserterror ADLSEUtil.CheckFieldTypeForExport(Field);
            LibraryAssert.ExpectedError('is not supported');
        end;
    end;

    [Test]
    procedure TestSchemaChangeDetection_FieldRemoved_ThrowsError()
    var
        ADLSETable: Record "ADLSE Table";
        ADLSECDMUtil: Codeunit "ADLSE CDM Util";
        ADLSEExecute: Codeunit "ADLSE Execute";
        OldEntityContent: JsonObject;
        NewEntityContent: JsonObject;
        FieldIdList: List of [Integer];
        ReducedFieldIdList: List of [Integer];
        FieldId: Integer;
        Counter: Integer;
    begin
        // [SCENARIO] Removing a field from entity throws error
        // [GIVEN] An entity with fields, then a reduced field list
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSETable.Add(Database::"Reason Code");
        ADLSELibrarybc2adls.InsertFields();
        ADLSELibrarybc2adls.EnableFields();

        FieldIdList := ADLSEExecute.CreateFieldListForTable(Database::"Reason Code");
        OldEntityContent := ADLSECDMUtil.CreateEntityContent(Database::"Reason Code", FieldIdList);

        // Create reduced field list (skip first non-system field)
        Counter := 0;
        foreach FieldId in FieldIdList do begin
            Counter += 1;
            if Counter > 1 then // Skip first field
                ReducedFieldIdList.Add(FieldId);
        end;

        NewEntityContent := ADLSECDMUtil.CreateEntityContent(Database::"Reason Code", ReducedFieldIdList);

        // [WHEN] CheckChangeInEntities is called with removed field
        // [THEN] An error is thrown about removed field
        asserterror ADLSECDMUtil.CheckChangeInEntities(OldEntityContent, NewEntityContent, 'TestEntity');
        LibraryAssert.ExpectedError('cannot be removed');
    end;

    [Test]
    procedure TestMaximumRetries_ExceedsLimit_ThrowsError()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        // [SCENARIO] Setting Maximum Retries above limit throws error
        // [GIVEN] Setup record
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSESetup.Get(0);

        // [WHEN] Maximum Retries is set above 10
        // [THEN] An error is thrown
        asserterror ADLSESetup.Validate("Maximum Retries", 11);
        LibraryAssert.ExpectedError('equal or smaller than 10');
    end;

    local procedure Initialize()
    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ADLSE Error Handling Tests");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ADLSE Error Handling Tests");

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ADLSE Error Handling Tests");
    end;

    local procedure ClearCredentials()
    begin
        if IsolatedStorage.Contains('adlse-tenant-id', DataScope::Module) then
            IsolatedStorage.Delete('adlse-tenant-id', DataScope::Module);
        if IsolatedStorage.Contains('adlse-client-id', DataScope::Module) then
            IsolatedStorage.Delete('adlse-client-id', DataScope::Module);
        if IsolatedStorage.Contains('adlse-client-secret', DataScope::Module) then
            IsolatedStorage.Delete('adlse-client-secret', DataScope::Module);
    end;
}
