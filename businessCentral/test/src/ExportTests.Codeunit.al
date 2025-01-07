codeunit 85566 "ADLSE Export Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    trigger OnRun()
    begin
        // [FEATURE] bc2adls Export
    end;

    var
        ADLSETable: Record "ADLSE Table";
        ADLSLibrarybc2adls: Codeunit "ADLSE Library - bc2adls";
        LibraryAssert: Codeunit "Library Assert";
        LibraryDialogHandler: Codeunit "Library - Dialog Handler";
        LibraryERM: Codeunit "Library - ERM";
        IsInitialized: Boolean;
        "Storage Type": Enum "ADLSE Storage Type";

    [Test]
    procedure ExportSingleEntityFirstRun()
    var
        ADLSERun: Record "ADLSE Run";
        ReasonCode: Record "Reason Code";
        ADLSEExecute: Codeunit "ADLSE Execute";
        ADLSEGen2UtilMock: Codeunit "ADLSE Gen 2 Util Mock";
        ADLSESessionManager: Codeunit "ADLSE Session Manager";
        i: Integer;
        ExpectedEntityBlobPathTok: Label 'https://bc2adls.blob.core.windows.net/bc2adls/ReasonCode-231.cdm.json', Locked = true;
        ExpectedEntityJsonTok: Label '{"jsonSchemaSemanticVersion":"1.0.0","imports":[{"corpusPath":"cdm:/foundations.cdm.json"}],"definitions":[{"entityName":"ReasonCode-231","exhibitsTraits":[],"displayName":"Reason Code","description":"Represents the table Reason Code","hasAttributes":[{"name":"Code-1","dataFormat":"String","appliedTraits":[],"displayName":"Code","maximumLength":10,"isPrimaryKey":true},{"name":"timestamp-0","dataFormat":"Int64","appliedTraits":[],"displayName":"timestamp","maximumLength":8},{"name":"systemId-2000000000","dataFormat":"Guid","appliedTraits":[],"displayName":"$systemId","maximumLength":16},{"name":"SystemCreatedAt-2000000001","dataFormat":"DateTime","appliedTraits":[],"displayName":"SystemCreatedAt","maximumLength":8},{"name":"SystemCreatedBy-2000000002","dataFormat":"Guid","appliedTraits":[],"displayName":"SystemCreatedBy","maximumLength":16},{"name":"SystemModifiedAt-2000000003","dataFormat":"DateTime","appliedTraits":[],"displayName":"SystemModifiedAt","maximumLength":8},{"name":"SystemModifiedBy-2000000004","dataFormat":"Guid","appliedTraits":[],"displayName":"SystemModifiedBy","maximumLength":16},{"name":"$Company","dataFormat":"String","appliedTraits":[],"displayName":"$Company","maximumLength":30}]}]}', Locked = true;
        ExpectedManifestBlobPathTok: Label 'https://bc2adls.blob.core.windows.net/bc2adls/data.manifest.cdm.json', Locked = true;
        ExpectedManifestJsonTok: Label '{"jsonSchemaSemanticVersion":"1.0.0","imports":[],"manifestName":"data-manifest","explanation":"Data exported from the Business Central to the Azure Data Lake Storage","entities":[{"type":"LocalEntity","entityName":"ReasonCode-231","entityPath":"ReasonCode-231.cdm.json/ReasonCode-231","dataPartitionPatterns":[{"name":"ReasonCode-231","rootLocation":"data/ReasonCode-231/","globPattern":"*.parquet","exhibitsTraits":[{"traitReference":"is.partition.format.parquet"}]}]}],"relationships":[]}', Locked = true;
    begin
        // [SCENARIO 101] E2E Test Export Single Entity
        // [GIVEN] Initialized test environment
        Initialize();
        ADLSLibrarybc2adls.CleanUp();
        ADLSESessionManager.SavePendingTables('');
        ADLSEGen2UtilMock.AddContent(ExpectedEntityBlobPathTok, ExpectedEntityJsonTok);
        ADLSEGen2UtilMock.AddContent(ExpectedManifestBlobPathTok, ExpectedManifestJsonTok);
        ADLSEGen2UtilMock.SetBlobExists(true);

        ReasonCode.DeleteAll(false);
        for i := 1 to 10 do
            LibraryERM.CreateReasonCode(ReasonCode);

        // [GIVEN] Setup bc2adls for Azure Blob Storage
        ADLSLibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        // [GIVEN] Setup bc2adls table 
        ADLSETable.Add(Database::"Reason Code");
        ADLSLibrarybc2adls.InsertFields();

        // [WHEN] Excuting the export
        Session.BindSubscription(ADLSEGen2UtilMock);
        ADLSEExecute.Run(ADLSETable);
        Session.UnbindSubscription(ADLSEGen2UtilMock);

        // [THEN] Verify the export is marked as successfull
        ADLSERun.SetRange("Table ID", ADLSETable."Table ID");
        ADLSERun.FindLast();
        LibraryAssert.AreEqual(ADLSERun.State::Success, ADLSERun.State, 'The state of the export was not registered as successfull');
        LibraryAssert.AreNotEqual(0DT, ADLSERun.Started, 'The Start DateTime is not set');
        LibraryAssert.AreNotEqual(0DT, ADLSERun.Ended, 'The End DateTime is not set');
    end;

    [Test]
    procedure ExportDelta()
    var
        ADLSETableLastTimestamp: Record "ADLSE Table Last Timestamp";
        ReasonCode: Record "Reason Code";
        ADLSEExecute: Codeunit "ADLSE Execute";
        ADLSEGen2UtilMock: Codeunit "ADLSE Gen 2 Util Mock";
        ADLSESessionManager: Codeunit "ADLSE Session Manager";
        TempBlob: Codeunit "Temp Blob";
        FieldRef: FieldRef;
        RecordRef: RecordRef;
        InStr: InStream;
        OutStr: OutStream;
        TimeStamp: BigInteger;
        i: Integer;
        PayloadLine: Text;
        ExpectedEntityBlobPathTok: Label 'https://bc2adls.blob.core.windows.net/bc2adls/ReasonCode-231.cdm.json', Locked = true;
    begin
        // [SCENARIO 101] Test Export Delta
        // [GIVEN] Initialized test environment
        Initialize();
        ADLSLibrarybc2adls.CleanUp();
        ADLSESessionManager.SavePendingTables('');

        // [GIVEN] Setup bc2adls for Azure Blob Storage
        ADLSLibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        // [GIVEN] Multiple records
        ReasonCode.DeleteAll(false);
        for i := 1 to 10 do
            LibraryERM.CreateReasonCode(ReasonCode);

        // [GIVEN] Setup bc2adls table 
        ADLSETable.Add(Database::"Reason Code");
        ADLSLibrarybc2adls.InsertFields();
        ADLSLibrarybc2adls.EnableFields();

        // [GIVEN] A new created record
        LibraryERM.CreateReasonCode(ReasonCode);

        // [GIVEN] A previous successfull export
        RecordRef.GetTable(ReasonCode);
        FieldRef := RecordRef.Field(0);
        Evaluate(TimeStamp, Format(FieldRef.Value()));
        ADLSETableLastTimestamp.TrySaveUpdatedLastTimestamp(Database::"Reason Code", TimeStamp - 1, false); // Minus 1 should make that the new created record is included in the export

        // [WHEN] Excuting the export
        ADLSEGen2UtilMock.AddContent(ExpectedEntityBlobPathTok, ADLSLibrarybc2adls.GetExpectedEntityJson(Database::"Reason Code"));
        ADLSEGen2UtilMock.AddContent(ADLSLibrarybc2adls.GetExpectedManifestBlobPath(), ADLSLibrarybc2adls.GetExpectedManifestJson(Database::"Reason Code"));
        ADLSEGen2UtilMock.SetBlobExists(true);
        Session.BindSubscription(ADLSEGen2UtilMock);
        ADLSEExecute.Run(ADLSETable);
        Session.UnbindSubscription(ADLSEGen2UtilMock);

        // [THEN] Verify the export contains only two lines
        i := 0;
        TempBlob.CreateOutStream(OutStr);
        OutStr.Write(ADLSEGen2UtilMock.GetBody());
        TempBlob.CreateInStream(InStr);
        while not InStr.EOS do begin
            InStr.ReadText(PayloadLine);
            if PayloadLine <> '' then i += 1;
        end;
        LibraryAssert.AreEqual(2, i, 'The payload should exist of only two lines');
    end;

    local procedure Initialize()
    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";

    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ADLSE Export Tests");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ADLSE Export Tests");

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ADLSE Export Tests");
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024]);
    begin
        LibraryDialogHandler.HandleMessage(Message);
    end;
}