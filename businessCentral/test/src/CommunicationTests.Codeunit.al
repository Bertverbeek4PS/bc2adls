codeunit 85572 "ADLSE Communication Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] bc2adls Communication
    end;

    var
        ADLSELibrarybc2adls: Codeunit "ADLSE Library - bc2adls";
        LibraryAssert: Codeunit "Library Assert";
        LibraryERM: Codeunit "Library - ERM";
        "Storage Type": Enum "ADLSE Storage Type";
        IsInitialized: Boolean;

    [Test]
    procedure TestInit_InitializesCorrectly()
    var
        ADLSETable: Record "ADLSE Table";
        ADLSECommunication: Codeunit "ADLSE Communication";
        ADLSEExecute: Codeunit "ADLSE Execute";
        ADLSEGen2UtilMock: Codeunit "ADLSE Gen 2 Util Mock";
        FieldIdList: List of [Integer];
    begin
        // [SCENARIO] Init initializes the communication codeunit correctly
        // [GIVEN] A configured table for export
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSETable.Add(Database::"Reason Code");
        ADLSELibrarybc2adls.InsertFields();
        ADLSELibrarybc2adls.EnableFields();

        FieldIdList := ADLSEExecute.CreateFieldListForTable(Database::"Reason Code");

        // [WHEN] Init is called
        Session.BindSubscription(ADLSEGen2UtilMock);
        ADLSECommunication.Init(Database::"Reason Code", FieldIdList, 0, false);
        Session.UnbindSubscription(ADLSEGen2UtilMock);

        // [THEN] No error occurs (initialization successful)
    end;

    [Test]
    procedure TestCheckEntity_NewEntity_FlagsUpdate()
    var
        ADLSETable: Record "ADLSE Table";
        ADLSECommunication: Codeunit "ADLSE Communication";
        ADLSEExecute: Codeunit "ADLSE Execute";
        ADLSEGen2UtilMock: Codeunit "ADLSE Gen 2 Util Mock";
        FieldIdList: List of [Integer];
        EntityJsonNeedsUpdate: Boolean;
        ManifestJsonsNeedsUpdate: Boolean;
    begin
        // [SCENARIO] CheckEntity flags entity and manifest for update when they don't exist
        // [GIVEN] A configured table with no existing entity in the data lake
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSETable.Add(Database::"Reason Code");
        ADLSELibrarybc2adls.InsertFields();
        ADLSELibrarybc2adls.EnableFields();

        FieldIdList := ADLSEExecute.CreateFieldListForTable(Database::"Reason Code");

        ADLSEGen2UtilMock.SetBlobExists(false);
        Session.BindSubscription(ADLSEGen2UtilMock);

        ADLSECommunication.Init(Database::"Reason Code", FieldIdList, 0, false);

        // [WHEN] CheckEntity is called with schema update flag
        ADLSECommunication.CheckEntity("ADLSE CDM Format"::Parquet, EntityJsonNeedsUpdate, ManifestJsonsNeedsUpdate, true);

        Session.UnbindSubscription(ADLSEGen2UtilMock);

        // [THEN] Both flags indicate update is needed
        LibraryAssert.IsTrue(EntityJsonNeedsUpdate, 'Entity should need update when blob does not exist');
        LibraryAssert.IsTrue(ManifestJsonsNeedsUpdate, 'Manifest should need update when entity is new');
    end;

    [Test]
    procedure TestCheckEntity_ExistingEntity_NoUpdateNeeded()
    var
        ADLSETable: Record "ADLSE Table";
        ADLSECommunication: Codeunit "ADLSE Communication";
        ADLSEExecute: Codeunit "ADLSE Execute";
        ADLSEGen2UtilMock: Codeunit "ADLSE Gen 2 Util Mock";
        FieldIdList: List of [Integer];
        EntityJsonNeedsUpdate: Boolean;
        ManifestJsonsNeedsUpdate: Boolean;
        ExpectedEntityBlobPath: Text;
        ExpectedManifestBlobPath: Text;
    begin
        // [SCENARIO] CheckEntity does not flag update when entity already exists with same schema
        // [GIVEN] A configured table with existing identical entity in data lake
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSETable.Add(Database::"Reason Code");
        ADLSELibrarybc2adls.InsertFields();
        ADLSELibrarybc2adls.EnableFields();

        FieldIdList := ADLSEExecute.CreateFieldListForTable(Database::"Reason Code");

        // Set up mock to return existing content
        ExpectedEntityBlobPath := 'https://bc2adls.blob.core.windows.net/bc2adls/ReasonCode-231.cdm.json';
        ExpectedManifestBlobPath := 'https://bc2adls.blob.core.windows.net/bc2adls/data.manifest.cdm.json';

        ADLSEGen2UtilMock.SetBlobExists(true);
        ADLSEGen2UtilMock.AddContent(ExpectedEntityBlobPath, ADLSELibrarybc2adls.GetExpectedEntityJson(Database::"Reason Code"));
        ADLSEGen2UtilMock.AddContent(ExpectedManifestBlobPath, ADLSELibrarybc2adls.GetExpectedManifestJson(Database::"Reason Code"));

        Session.BindSubscription(ADLSEGen2UtilMock);

        ADLSECommunication.Init(Database::"Reason Code", FieldIdList, 0, false);

        // [WHEN] CheckEntity is called
        ADLSECommunication.CheckEntity("ADLSE CDM Format"::Parquet, EntityJsonNeedsUpdate, ManifestJsonsNeedsUpdate, true);

        Session.UnbindSubscription(ADLSEGen2UtilMock);

        // [THEN] No update is needed when schemas match
        LibraryAssert.IsFalse(EntityJsonNeedsUpdate, 'Entity should not need update when schemas match');
    end;

    [Test]
    procedure TestCreateEntityContent_CreatesValidContent()
    var
        ADLSETable: Record "ADLSE Table";
        ADLSECommunication: Codeunit "ADLSE Communication";
        ADLSEExecute: Codeunit "ADLSE Execute";
        ADLSEGen2UtilMock: Codeunit "ADLSE Gen 2 Util Mock";
        FieldIdList: List of [Integer];
    begin
        // [SCENARIO] CreateEntityContent generates valid entity JSON
        // [GIVEN] A configured table
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSETable.Add(Database::"Reason Code");
        ADLSELibrarybc2adls.InsertFields();
        ADLSELibrarybc2adls.EnableFields();

        FieldIdList := ADLSEExecute.CreateFieldListForTable(Database::"Reason Code");

        Session.BindSubscription(ADLSEGen2UtilMock);
        ADLSECommunication.Init(Database::"Reason Code", FieldIdList, 0, false);

        // [WHEN] CreateEntityContent is called
        ADLSECommunication.CreateEntityContent();

        Session.UnbindSubscription(ADLSEGen2UtilMock);

        // [THEN] No error occurs (content created successfully)
    end;

    [Test]
    procedure TestTryCollectAndSendRecord_SingleRecord_Succeeds()
    var
        ADLSETable: Record "ADLSE Table";
        ReasonCode: Record "Reason Code";
        ADLSECommunication: Codeunit "ADLSE Communication";
        ADLSEExecute: Codeunit "ADLSE Execute";
        ADLSEGen2UtilMock: Codeunit "ADLSE Gen 2 Util Mock";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        FieldIdList: List of [Integer];
        LastTimestampExported: BigInteger;
        RecordTimestamp: BigInteger;
        Success: Boolean;
    begin
        // [SCENARIO] TryCollectAndSendRecord successfully collects a record
        // [GIVEN] A configured table with a record
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        ReasonCode.DeleteAll(false);
        LibraryERM.CreateReasonCode(ReasonCode);

        ADLSETable.Add(Database::"Reason Code");
        ADLSELibrarybc2adls.InsertFields();
        ADLSELibrarybc2adls.EnableFields();

        FieldIdList := ADLSEExecute.CreateFieldListForTable(Database::"Reason Code");

        ADLSEGen2UtilMock.SetBlobExists(true);
        Session.BindSubscription(ADLSEGen2UtilMock);

        ADLSECommunication.Init(Database::"Reason Code", FieldIdList, 0, false);

        RecordRef.GetTable(ReasonCode);
        FieldRef := RecordRef.Field(0); // Timestamp
        Evaluate(RecordTimestamp, Format(FieldRef.Value()));

        // [WHEN] TryCollectAndSendRecord is called
        Success := ADLSECommunication.TryCollectAndSendRecord(RecordRef, RecordTimestamp, LastTimestampExported, false);

        Session.UnbindSubscription(ADLSEGen2UtilMock);

        // [THEN] The operation succeeds
        LibraryAssert.IsTrue(Success, 'Should successfully collect record');
    end;

    [Test]
    procedure TestTryFinish_FlushesPayload()
    var
        ADLSETable: Record "ADLSE Table";
        ReasonCode: Record "Reason Code";
        ADLSECommunication: Codeunit "ADLSE Communication";
        ADLSEExecute: Codeunit "ADLSE Execute";
        ADLSEGen2UtilMock: Codeunit "ADLSE Gen 2 Util Mock";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        FieldIdList: List of [Integer];
        LastTimestampExported: BigInteger;
        RecordTimestamp: BigInteger;
        Success: Boolean;
    begin
        // [SCENARIO] TryFinish flushes any remaining payload
        // [GIVEN] A communication instance with collected records
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        ReasonCode.DeleteAll(false);
        LibraryERM.CreateReasonCode(ReasonCode);

        ADLSETable.Add(Database::"Reason Code");
        ADLSELibrarybc2adls.InsertFields();
        ADLSELibrarybc2adls.EnableFields();

        FieldIdList := ADLSEExecute.CreateFieldListForTable(Database::"Reason Code");

        ADLSEGen2UtilMock.SetBlobExists(true);
        Session.BindSubscription(ADLSEGen2UtilMock);

        ADLSECommunication.Init(Database::"Reason Code", FieldIdList, 0, false);

        RecordRef.GetTable(ReasonCode);
        FieldRef := RecordRef.Field(0);
        Evaluate(RecordTimestamp, Format(FieldRef.Value()));

        ADLSECommunication.TryCollectAndSendRecord(RecordRef, RecordTimestamp, LastTimestampExported, false);

        // [WHEN] TryFinish is called
        Success := ADLSECommunication.TryFinish(LastTimestampExported);

        Session.UnbindSubscription(ADLSEGen2UtilMock);

        // [THEN] The operation succeeds
        LibraryAssert.IsTrue(Success, 'Should successfully finish and flush payload');
    end;

    [Test]
    procedure TestResetTableExport_AzureDataLake()
    var
        ADLSETable: Record "ADLSE Table";
        ADLSECommunication: Codeunit "ADLSE Communication";
        ADLSEGen2UtilMock: Codeunit "ADLSE Gen 2 Util Mock";
    begin
        // [SCENARIO] ResetTableExport works for Azure Data Lake storage
        // [GIVEN] A configured table with Azure Data Lake storage
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSETable.Add(Database::"Reason Code");
        ADLSELibrarybc2adls.InsertFields();

        Session.BindSubscription(ADLSEGen2UtilMock);

        // [WHEN] ResetTableExport is called
        ADLSECommunication.ResetTableExport(Database::"Reason Code");

        Session.UnbindSubscription(ADLSEGen2UtilMock);

        // [THEN] No error occurs
    end;

    local procedure Initialize()
    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ADLSE Communication Tests");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ADLSE Communication Tests");

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ADLSE Communication Tests");
    end;
}
