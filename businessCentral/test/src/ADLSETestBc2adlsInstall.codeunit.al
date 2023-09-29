codeunit 85562 "ADLSE Test bc2adls Install"
{
    Subtype = Install;

    var
        TestSuiteMgt: Codeunit "Test Suite Mgt.";

    trigger OnInstallAppPerCompany()
    begin
        SetupTestSuite();
        SetWebServicesKeyforUser();
    end;

    local procedure SetupTestSuite()
    begin
        // Add test codeunits to 'Test Suite With Runner - Isol. Codeunit'
        AddTestsToTestSuite(Enum::"ADLSE Test Suite"::"Test Suite With Runner - Isol. Codeunit", Codeunit::"ADLSE Test bc2adls");
        // Add test codeunits to 'Test Suite With Runner - Isol. Disabled'
        AddTestsToTestSuite(Enum::"ADLSE Test Suite"::"Test Suite With Runner - Isol. Disabled", Codeunit::"ADLSE Test Field API");
    end;

    procedure AddTestsToTestSuite(TestSuite: Enum "ADLSE Test Suite"; TestCodeunitId: Integer)
    var
        ALTestSuite: Record "AL Test Suite";
        SuiteName: Code[10];
        TestRunnerCodeunitId: Integer;
    begin
        TestRunnerCodeunitId := GetDefaultTestRunnerCodeunitId(TestSuite);
        SuiteName := Format(TestRunnerCodeunitId);

        if TestRunnerCodeunitId = 0 then
            exit;

        if not GetOrCreateALTestSuite(ALTestSuite, SuiteName) then
            exit;

        if TestMethodLineExists(SuiteName, TestCodeunitId) then
            UpdateTestMethodLines(SuiteName, TestCodeunitId)
        else begin
            TestSuiteMgt.SelectTestMethodsByRange(ALTestSuite, Format(TestCodeunitId));
            TestSuiteMgt.ChangeTestRunner(ALTestSuite, TestRunnerCodeunitId);
        end;
    end;

    procedure GetDefaultTestRunnerCodeunitId(TestSuite: Enum "ADLSE Test Suite") TestRunnerCodeunitId: Integer;
    var
        TestRunnerMgt: Codeunit "Test Runner - Mgt";
    begin
        case TestSuite of
            TestSuite::"Test Suite With Runner - Isol. Codeunit":
                TestRunnerCodeunitId := TestRunnerMgt.GetCodeIsolationTestRunner();
            TestSuite::"Test Suite With Runner - Isol. Disabled":
                TestRunnerCodeunitId := TestRunnerMgt.GetIsolationDisabledTestRunner();
        end;

        exit(TestRunnerCodeunitId);
    end;

    procedure GetDefaultTestRunnerCodeunitDescription(TestRunnerCodeunitId: Integer) TestRunnerCodeunitDescription: Text[30];
    var
        TestSuite: Enum "ADLSE Test Suite";
    begin
        if (GetDefaultTestSuite(TestSuite, TestRunnerCodeunitId)) then
            exit(CopyStr(DelStr(Format(TestSuite), 1, StrLen('Test Suite With ')), 1, MaxStrLen(TestRunnerCodeunitDescription)));
    end;

    procedure GetDefaultTestSuiteCaption(TestRunnerCodeunitId: Integer) TestRunnerCodeunitName: Text;
    var
        TestSuite: Enum "ADLSE Test Suite";
    begin
        if (GetDefaultTestSuite(TestSuite, TestRunnerCodeunitId)) then
            exit(CopyStr(Format(TestSuite), 1, MaxStrLen(TestRunnerCodeunitName)));
    end;

    procedure GetDefaultTestSuite(var TestSuite: Enum "ADLSE Test Suite"; TestRunnerCodeunitId: Integer): Boolean
    var
        TestRunnerMgt: Codeunit "Test Runner - Mgt";
    begin
        case TestRunnerCodeunitId of
            TestRunnerMgt.GetCodeIsolationTestRunner():
                TestSuite := Enum::"ADLSE Test Suite"::"Test Suite With Runner - Isol. Codeunit";
            TestRunnerMgt.GetIsolationDisabledTestRunner():
                TestSuite := Enum::"ADLSE Test Suite"::"Test Suite With Runner - Isol. Disabled";
            else
                exit(false);
        end;
        exit(true);
    end;

    procedure GetOrCreateALTestSuite(var ALTestSuite: Record "AL Test Suite"; SuiteName: Code[10]): Boolean
    var
        TestRunnerCodeunitId: Integer;
    begin
        if SuiteName = '' then
            exit;
        Clear(ALTestSuite);
        if not ALTestSuite.Get(SuiteName) then begin
            TestSuiteMgt.CreateTestSuite(SuiteName);
            ALTestSuite.Get(SuiteName);
            TestRunnerCodeunitId := ALTestSuite.GetDefaultTestRunner();
            if TestRunnerCodeunitId <> 0 then begin
                ALTestSuite.Description := GetDefaultTestRunnerCodeunitDescription(TestRunnerCodeunitId);
                ALTestSuite.Modify();
            end;
        end;
        exit(true);
    end;

    procedure TestMethodLineExists(SuiteName: Code[10]; TestCodeunitId: Integer): Boolean
    var
        TestMethodLine: Record "Test Method Line";
    begin
        if SuiteName = '' then
            exit;
        TestMethodLine.Reset();
        TestMethodLine.SetRange("Test Suite", SuiteName);
        TestMethodLine.SetRange("Test Codeunit", TestCodeunitId);
        exit(not TestMethodLine.IsEmpty());
    end;

    procedure UpdateTestMethodLines(SuiteName: Code[10]; TestCodeunitId: Integer)
    var
        TestMethodLine: Record "Test Method Line";
    begin
        if SuiteName = '' then
            exit;
        TestMethodLine.SetRange("Test Suite", SuiteName);
        TestMethodLine.SetRange("Test Codeunit", TestCodeunitId);
        TestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::Codeunit);
        if TestMethodLine.FindFirst() then
            TestSuiteMgt.UpdateTestMethods(TestMethodLine);
    end;

    local procedure SetWebServicesKeyforUser()
    var
        IdentityManagement: Codeunit "Identity Management";
    begin
        if IdentityManagement.GetWebServicesKey(UserSecurityId()) = '' then
            IdentityManagement.CreateWebServicesKeyNoExpiry(UserSecurityId());
    end;
}