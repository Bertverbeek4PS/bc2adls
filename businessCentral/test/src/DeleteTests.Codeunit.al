codeunit 85563 "ADLSE Delete Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    trigger OnRun()
    begin
        // [FEATURE] bc2adls Delete
    end;

    var
        ADLSETable: Record "ADLSE Table";
        ADLSELibrarybc2adls: Codeunit "ADLSE Library - bc2adls";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryAssert: Codeunit "Library Assert";
        "Storage Type": Enum "ADLSE Storage Type";
        IsInitialized: Boolean;

    [Test]
    procedure DeleteARecordAndVerifyInADLSEDeletedRecord()
    var
        PaymentTerms: Record "Payment Terms";
        ADLSEDeletedRecord: Record "ADLSE Deleted Record";
        PaymentTermGuid: Guid;
    begin
        // [SCENARIO 201] Delete a record, where this action is tracked in the "ADSLE Deleted Record" table
        // [GIVEN] Initialized test environment
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        // [GIVEN] Setup bc2adls table for Azure Blob Storage
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        // [GIVEN] Insert a record
        InsertPaymentTerms(PaymentTerms);
        // [GIVEN] Insert a table for export
        ADLSETable.Add(PaymentTerms.RecordId.TableNo);
        ADLSELibrarybc2adls.InsertFields();
        // [GIVEN] Enable a field for export
        ADLSELibrarybc2adls.EnableField(PaymentTerms.RecordId.TableNo, PaymentTerms.FieldNo(Code));
        ADLSELibrarybc2adls.EnableField(PaymentTerms.RecordId.TableNo, PaymentTerms.FieldNo(Description));
        // [GIVEN] Perform an export
        ADLSELibrarybc2adls.MockCreateExport(PaymentTerms.RecordId.TableNo);

        // [WHEN] a record is deleted   
        DeletePaymentTerms(PaymentTerms, PaymentTermGuid);

        // [THEN] Check if the record is marked as deleted in the "ADLSE Deleted Record" table
        ADLSEDeletedRecord.Reset();
        ADLSEDeletedRecord.SetRange("Table ID", PaymentTerms.RecordId.TableNo);
        if ADLSEDeletedRecord.FindFirst() then
            LibraryAssert.AreEqual(PaymentTermGuid, ADLSEDeletedRecord."System ID", 'The record is not inserted in the "ADLSE Deleted Record" table');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ResetTable()
    var
        ADLSETableLastTimestamp: Record "ADLSE Table Last Timestamp";
        PaymentTerms: Record "Payment Terms";
        BigInt: BigInteger;
    begin
        // [SCENARIO 202] Perform an export of a table and reset the table
        // [GIVEN] Initialized test environment
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        // [GIVEN] Setup bc2adls table for Azure Blob Storage
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        // [GIVEN] Insert a record
        InsertPaymentTerms(PaymentTerms);
        // [GIVEN] Insert a table for export
        ADLSETable.Add(PaymentTerms.RecordId.TableNo);
        ADLSELibrarybc2adls.InsertFields();
        // [GIVEN] Enable a field for export
        ADLSELibrarybc2adls.EnableField(PaymentTerms.RecordId.TableNo, PaymentTerms.FieldNo(Code));
        ADLSELibrarybc2adls.EnableField(PaymentTerms.RecordId.TableNo, PaymentTerms.FieldNo(Description));
        // [GIVEN] Perform an export
        ADLSELibrarybc2adls.MockCreateExport(PaymentTerms.RecordId.TableNo);

        // [WHEN] a record is deleted
        ADLSETable.Get(PaymentTerms.RecordId.TableNo);
        ADLSETable.ResetSelected();

        // [THEN] Check if the record is marked as deleted in the "ADLSE Deleted Record" table
        BigInt := 0;
        ADLSETableLastTimestamp.Reset();
        ADLSETableLastTimestamp.SetRange("Table ID", PaymentTerms.RecordId.TableNo);
        if ADLSETableLastTimestamp.FindFirst() then
            LibraryAssert.AreEqual(BigInt, ADLSETableLastTimestamp."Updated Last Timestamp", 'Timestamp is not reset');

    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ClearTrackedDeletedRecords()
    var
        PaymentTerms: Record "Payment Terms";
        PaymentTermGuid: Guid;
    begin
        // [SCENARIO 203] User can Clear tracked deleted records
        // [GIVEN] Initialized test environment
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        // [GIVEN] Setup bc2adls table for Azure Blob Storage
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        // [GIVEN] Insert a record
        InsertPaymentTerms(PaymentTerms);
        // [GIVEN] Insert a table for export
        ADLSETable.Add(PaymentTerms.RecordId.TableNo);
        ADLSELibrarybc2adls.InsertFields();
        // [GIVEN] Enable a field for export
        ADLSELibrarybc2adls.EnableField(PaymentTerms.RecordId.TableNo, PaymentTerms.FieldNo(Code));
        ADLSELibrarybc2adls.EnableField(PaymentTerms.RecordId.TableNo, PaymentTerms.FieldNo(Description));
        // [GIVEN] Perform an export
        ADLSELibrarybc2adls.MockCreateExport(PaymentTerms.RecordId.TableNo);
        // [GIVEN] a record is deleted   
        DeletePaymentTerms(PaymentTerms, PaymentTermGuid);

        // [WHEN] When the user clears the tracked deleted records
        Codeunit.Run(Codeunit::"ADLSE Clear Tracked Deletions");

        // [THEN] Check if the record is marked as deleted in the "ADLSE Deleted Record" table
        LibraryAssert.TableIsEmpty(Database::"ADLSE Deleted Record");
    end;

    local procedure InsertPaymentTerms(var PaymentTerms: Record "Payment Terms")
    begin
        PaymentTerms.Init();
        PaymentTerms.Code := LibraryUtility.GenerateRandomCode(PaymentTerms.FieldNo(Code), Database::"Payment Terms");
        PaymentTerms.Description := LibraryUtility.GenerateRandomText(MaxStrLen(PaymentTerms.Description));
        PaymentTerms.Insert(true);
    end;

    local procedure DeletePaymentTerms(var PaymentTerms: Record "Payment Terms"; var PaymentTermGuid: Guid)
    begin
        PaymentTerms.FindLast();
        PaymentTermGuid := PaymentTerms.SystemId;
        PaymentTerms.Delete();
    end;

    local procedure Initialize()
    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";

    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ADLSE Delete Tests");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ADLSE Delete Tests");

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ADLSE Delete Tests");
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024]);
    begin
    end;
}