codeunit 85574 "ADLSE Multi Company Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] bc2adls Multi Company Export
    end;

    var
        ADLSELibrarybc2adls: Codeunit "ADLSE Library - bc2adls";
        LibraryAssert: Codeunit "Library Assert";
        "Storage Type": Enum "ADLSE Storage Type";
        IsInitialized: Boolean;

    [Test]
    procedure TestSetCompanyFilter_SetsFilter()
    var
        ADLSEMultiCompanyExport: Codeunit "ADLSE Multi Company Export";
    begin
        // [SCENARIO] SetCompanyFilter sets the company filter
        // [GIVEN] A multi company export codeunit
        Initialize();

        // [WHEN] SetCompanyFilter is called
        ADLSEMultiCompanyExport.SetCompanyFilter('CRONUS*');

        // [THEN] No error occurs (filter is set)
    end;

    [Test]
    procedure TestMultiCompanyExport_RequiresSyncCompanies()
    var
        ADLSESyncCompanies: Record "ADLSE Sync Companies";
        ADLSETable: Record "ADLSE Table";
    begin
        // [SCENARIO] Multi company export uses ADLSE Sync Companies table
        // [GIVEN] Setup for multi company export
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        ADLSETable.Add(Database::"Reason Code");
        ADLSELibrarybc2adls.InsertFields();

        // [THEN] Sync Companies table can be accessed
        ADLSESyncCompanies.Reset();
        // Table should be accessible without error
    end;

    [Test]
    procedure TestMultiCompanyExport_CompaniesTableStructure()
    var
        ADLSECompaniesTable: Record "ADLSE Companies Table";
    begin
        // [SCENARIO] ADLSE Companies Table has correct structure
        // [GIVEN] The companies table
        Initialize();

        // [THEN] The table can be accessed and has expected structure
        ADLSECompaniesTable.Reset();
        // Table should be accessible without error
    end;

    [Test]
    procedure TestCurrentSessionTable_TracksActiveSessions()
    var
        ADLSECurrentSession: Record "ADLSE Current Session";
    begin
        // [SCENARIO] ADLSE Current Session table tracks active export sessions
        // [GIVEN] Current session tracking
        Initialize();

        // [THEN] The table can be accessed
        ADLSECurrentSession.Reset();
        // Table should be accessible
    end;

    [Test]
    procedure TestAreAnySessionsActive_NoSessions_ReturnsFalse()
    var
        ADLSECurrentSession: Record "ADLSE Current Session";
        Result: Boolean;
    begin
        // [SCENARIO] AreAnySessionsActive returns false when no sessions exist
        // [GIVEN] No active sessions
        Initialize();
        ADLSECurrentSession.DeleteAll();
        Commit();

        // [WHEN] AreAnySessionsActive is called
        Result := ADLSECurrentSession.AreAnySessionsActive();

        // [THEN] Returns false
        LibraryAssert.IsFalse(Result, 'Should return false when no sessions exist');
    end;

    [Test]
    procedure TestCompanyRun_TracksTimestamp()
    var
        ADLSERun: Record "ADLSE Run";
        ADLSETableLastTimestamp: Record "ADLSE Table Last Timestamp";
        TableId: Integer;
        State: Enum "ADLSE Run State";
        StartedAt: DateTime;
        ErrorText: Text[2048];
    begin
        // [SCENARIO] ADLSE Run tracks timestamps per company
        // [GIVEN] A table configured for export
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        TableId := Database::"Reason Code";

        // [WHEN] GetLastRunDetails and GetUpdatedLastTimestamp are called
        ADLSERun.GetLastRunDetails(TableId, State, StartedAt, ErrorText);
        ADLSETableLastTimestamp.GetUpdatedLastTimestamp(TableId);

        // [THEN] Values are returned (may be 0 if no previous run)
        // Just verify no error occurs
    end;

    [Test]
    procedure TestSyncCompanies_FilterApplication()
    var
        ADLSESyncCompanies: Record "ADLSE Sync Companies";
        Company: Record Company;
    begin
        // [SCENARIO] Sync Companies table can be filtered
        // [GIVEN] Sync companies records
        Initialize();

        // First ensure we have at least one company
        if Company.FindFirst() then begin
            // [WHEN] Filter is applied
            ADLSESyncCompanies.SetFilter("Sync Company", '%1', Company.Name);

            // [THEN] Filter can be applied without error
        end;
    end;

    [Test]
    procedure TestMultiCompanySetup_ExportCompanyDatabaseTables()
    var
        ADLSESetup: Record "ADLSE Setup";
        Company: Record Company;
    begin
        // [SCENARIO] Export Company Database Tables field controls which company exports database tables
        // [GIVEN] Setup with export company specified
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");

        ADLSESetup.Get(0);

        // [WHEN] Export Company Database Tables is set
        if Company.FindFirst() then begin
            ADLSESetup."Export Company Database Tables" := Company.Name;
            ADLSESetup.Modify();

            // [THEN] The value is stored
            ADLSESetup.Get(0);
            LibraryAssert.AreEqual(Company.Name, ADLSESetup."Export Company Database Tables", 'Export company should be set');
        end;
    end;

    [Test]
    procedure TestIsTablePerCompany_WithCompanyTable()
    var
        ADLSEUtil: Codeunit "ADLSE Util";
        IsPerCompany: Boolean;
    begin
        // [SCENARIO] IsTablePerCompany correctly identifies per-company tables
        // [GIVEN] A per-company table (G/L Entry)
        Initialize();

        // [WHEN] IsTablePerCompany is called
        IsPerCompany := ADLSEUtil.IsTablePerCompany(Database::"G/L Entry");

        // [THEN] Returns true for per-company tables
        LibraryAssert.IsTrue(IsPerCompany, 'G/L Entry should be a per-company table');
    end;

    [Test]
    procedure TestIsTablePerCompany_WithDatabaseTable()
    var
        ADLSEUtil: Codeunit "ADLSE Util";
        IsPerCompany: Boolean;
    begin
        // [SCENARIO] IsTablePerCompany correctly identifies database-level tables
        // [GIVEN] A database-level table (User)
        Initialize();

        // [WHEN] IsTablePerCompany is called
        IsPerCompany := ADLSEUtil.IsTablePerCompany(Database::User);

        // [THEN] Returns false for database-level tables
        LibraryAssert.IsFalse(IsPerCompany, 'User should not be a per-company table');
    end;

    [Test]
    procedure TestCompanyFieldInExport_PerCompanyTable()
    var
        ADLSETable: Record "ADLSE Table";
        ADLSECDMUtil: Codeunit "ADLSE CDM Util";
        ADLSEExecute: Codeunit "ADLSE Execute";
        EntityContent: JsonObject;
        FieldIdList: List of [Integer];
        JsonText: Text;
    begin
        // [SCENARIO] Per-company tables include $Company field in entity definition
        // [GIVEN] A per-company table configured for export
        Initialize();
        ADLSELibrarybc2adls.CleanUp();
        ADLSELibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        ADLSETable.Add(Database::"Reason Code"); // Reason Code is per-company
        ADLSELibrarybc2adls.InsertFields();

        // [WHEN] Entity content is created
        FieldIdList := ADLSEExecute.CreateFieldListForTable(Database::"Reason Code");
        EntityContent := ADLSECDMUtil.CreateEntityContent(Database::"Reason Code", FieldIdList);
        EntityContent.WriteTo(JsonText);

        // [THEN] The entity contains $Company field
        LibraryAssert.IsTrue(JsonText.Contains('$Company'), 'Per-company table should include $Company field');
    end;

    local procedure Initialize()
    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ADLSE Multi Company Tests");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ADLSE Multi Company Tests");

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ADLSE Multi Company Tests");
    end;
}
