codeunit 85573 "ADLSE Credentials Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] bc2adls Credentials
    end;

    var
        LibraryAssert: Codeunit "Library Assert";
        IsInitialized: Boolean;

    [Test]
    procedure TestIsInitialized_BeforeInit_ReturnsFalse()
    var
        ADLSECredentials: Codeunit "ADLSE Credentials";
    begin
        // [SCENARIO] IsInitialized returns false before Init is called
        // [GIVEN] A fresh credentials instance
        Initialize();

        // [WHEN] IsInitialized is checked before Init
        // [THEN] Returns false
        LibraryAssert.IsFalse(ADLSECredentials.IsInitialized(), 'Should not be initialized before Init call');
    end;

    [Test]
    procedure TestInit_SetsInitializedFlag()
    var
        ADLSECredentials: Codeunit "ADLSE Credentials";
    begin
        // [SCENARIO] Init sets the initialized flag
        // [GIVEN] A credentials instance
        Initialize();

        // [WHEN] Init is called
        ADLSECredentials.Init();

        // [THEN] IsInitialized returns true
        LibraryAssert.IsTrue(ADLSECredentials.IsInitialized(), 'Should be initialized after Init call');
    end;

    [Test]
    procedure TestSetAndGetTenantID()
    var
        ADLSECredentials: Codeunit "ADLSE Credentials";
        TestTenantId: Text;
    begin
        // [SCENARIO] SetTenantID stores and GetTenantID retrieves the tenant ID
        // [GIVEN] A credentials instance
        Initialize();
        TestTenantId := 'test-tenant-id-' + Format(CreateGuid());

        // [WHEN] SetTenantID is called followed by Init and GetTenantID
        ADLSECredentials.SetTenantID(TestTenantId);
        ADLSECredentials.Init();

        // [THEN] The stored value is retrieved
        LibraryAssert.AreEqual(TestTenantId, ADLSECredentials.GetTenantID(), 'Tenant ID should match');
    end;

    [Test]
    procedure TestSetAndGetClientID()
    var
        ADLSECredentials: Codeunit "ADLSE Credentials";
        TestClientId: Text;
    begin
        // [SCENARIO] SetClientID stores and GetClientID retrieves the client ID
        // [GIVEN] A credentials instance
        Initialize();
        TestClientId := 'test-client-id-' + Format(CreateGuid());

        // [WHEN] SetClientID is called followed by Init and GetClientID
        ADLSECredentials.SetClientID(TestClientId);
        ADLSECredentials.Init();

        // [THEN] The stored value is retrieved
        LibraryAssert.AreEqual(TestClientId, ADLSECredentials.GetClientID(), 'Client ID should match');
    end;

    [Test]
    procedure TestSetAndGetClientSecret()
    var
        ADLSECredentials: Codeunit "ADLSE Credentials";
        TestSecret: Text;
    begin
        // [SCENARIO] SetClientSecret stores and GetClientSecret retrieves the secret
        // [GIVEN] A credentials instance
        Initialize();
        TestSecret := 'test-secret-' + Format(CreateGuid());

        // [WHEN] SetClientSecret is called followed by Init and GetClientSecret
        ADLSECredentials.SetClientSecret(TestSecret);
        ADLSECredentials.Init();

        // [THEN] The stored value is retrieved
        LibraryAssert.AreEqual(TestSecret, ADLSECredentials.GetClientSecret(), 'Client secret should match');
    end;

    [Test]
    procedure TestIsClientIDSet_WithValue_ReturnsTrue()
    var
        ADLSECredentials: Codeunit "ADLSE Credentials";
        TestClientId: Text;
    begin
        // [SCENARIO] IsClientIDSet returns true when client ID is set
        // [GIVEN] A credentials instance with client ID set
        Initialize();
        TestClientId := 'test-client-id-' + Format(CreateGuid());
        ADLSECredentials.SetClientID(TestClientId);
        ADLSECredentials.Init();

        // [WHEN] IsClientIDSet is called
        // [THEN] Returns true
        LibraryAssert.IsTrue(ADLSECredentials.IsClientIDSet(), 'IsClientIDSet should return true');
    end;

    [Test]
    procedure TestIsClientSecretSet_WithValue_ReturnsTrue()
    var
        ADLSECredentials: Codeunit "ADLSE Credentials";
        TestSecret: Text;
    begin
        // [SCENARIO] IsClientSecretSet returns true when secret is set
        // [GIVEN] A credentials instance with secret set
        Initialize();
        TestSecret := 'test-secret-' + Format(CreateGuid());
        ADLSECredentials.SetClientSecret(TestSecret);
        ADLSECredentials.Init();

        // [WHEN] IsClientSecretSet is called
        // [THEN] Returns true
        LibraryAssert.IsTrue(ADLSECredentials.IsClientSecretSet(), 'IsClientSecretSet should return true');
    end;

    [Test]
    procedure TestCheck_AllCredentialsSet_NoError()
    var
        ADLSECredentials: Codeunit "ADLSE Credentials";
    begin
        // [SCENARIO] Check does not error when all credentials are set
        // [GIVEN] A credentials instance with all values set
        Initialize();
        ADLSECredentials.SetTenantID('test-tenant-' + Format(CreateGuid()));
        ADLSECredentials.SetClientID('test-client-' + Format(CreateGuid()));
        ADLSECredentials.SetClientSecret('test-secret-' + Format(CreateGuid()));

        // [WHEN] Check is called
        // [THEN] No error is thrown
        ADLSECredentials.Check();
    end;

    [Test]
    procedure TestCredentialsPersistence_AcrossInstances()
    var
        ADLSECredentials1: Codeunit "ADLSE Credentials";
        ADLSECredentials2: Codeunit "ADLSE Credentials";
        TestTenantId: Text;
        TestClientId: Text;
        TestSecret: Text;
    begin
        // [SCENARIO] Credentials persist across codeunit instances
        // [GIVEN] Credentials set in one instance
        Initialize();
        TestTenantId := 'persist-tenant-' + Format(CreateGuid());
        TestClientId := 'persist-client-' + Format(CreateGuid());
        TestSecret := 'persist-secret-' + Format(CreateGuid());

        ADLSECredentials1.SetTenantID(TestTenantId);
        ADLSECredentials1.SetClientID(TestClientId);
        ADLSECredentials1.SetClientSecret(TestSecret);

        // [WHEN] A new instance retrieves the credentials
        ADLSECredentials2.Init();

        // [THEN] The values are the same
        LibraryAssert.AreEqual(TestTenantId, ADLSECredentials2.GetTenantID(), 'Tenant ID should persist');
        LibraryAssert.AreEqual(TestClientId, ADLSECredentials2.GetClientID(), 'Client ID should persist');
        LibraryAssert.AreEqual(TestSecret, ADLSECredentials2.GetClientSecret(), 'Client secret should persist');
    end;

    [Test]
    procedure TestCredentialsPersistence_AcrossInstances()
    var
        ADLSECredentials1: Codeunit "ADLSE Credentials";
        ADLSECredentials2: Codeunit "ADLSE Credentials";
        TestTenantId: Text;
        TestClientId: Text;
        TestSecret: Text;
    begin
        // [SCENARIO] Credentials persist across codeunit instances
        // [GIVEN] Credentials set in one instance
        Initialize();
        TestTenantId := 'persist-tenant-' + Format(CreateGuid());
        TestClientId := 'persist-client-' + Format(CreateGuid());
        TestSecret := 'persist-secret-' + Format(CreateGuid());

        ADLSECredentials1.SetTenantID(TestTenantId);
        ADLSECredentials1.SetClientID(TestClientId);
        ADLSECredentials1.SetClientSecret(TestSecret);

        // [WHEN] A new instance retrieves the credentials
        ADLSECredentials2.Init();

        // [THEN] The values are the same
        LibraryAssert.AreEqual(TestTenantId, ADLSECredentials2.GetTenantID(), 'Tenant ID should persist');
        LibraryAssert.AreEqual(TestClientId, ADLSECredentials2.GetClientID(), 'Client ID should persist');
        LibraryAssert.AreEqual(TestSecret, ADLSECredentials2.GetClientSecret(), 'Client secret should persist');
    end;

    [Test]
    procedure TestSetAndGetClientCertificate()
    var
        ADLSECredentials: Codeunit "ADLSE Credentials";
        TestCertificate: Text;
    begin
        // [SCENARIO] SetClientCertificate stores and GetClientCertificate retrieves the certificate
        // [GIVEN] A credentials instance
        Initialize();
        TestCertificate := 'test-certificate-base64-' + Format(CreateGuid());

        // [WHEN] SetClientCertificate is called followed by Init and GetClientCertificate
        ADLSECredentials.SetClientCertificate(TestCertificate);
        ADLSECredentials.Init();

        // [THEN] The stored value is retrieved
        LibraryAssert.AreEqual(TestCertificate, ADLSECredentials.GetClientCertificate(), 'Certificate should match');
    end;

    [Test]
    procedure TestIsClientCertificateSet_WithValue_ReturnsTrue()
    var
        ADLSECredentials: Codeunit "ADLSE Credentials";
    begin
        // [SCENARIO] IsClientCertificateSet returns true when certificate is set
        // [GIVEN] A credentials instance with a certificate set
        Initialize();
        ADLSECredentials.SetClientCertificate('test-cert-' + Format(CreateGuid()));
        ADLSECredentials.Init();

        // [WHEN] IsClientCertificateSet is called
        // [THEN] Returns true
        LibraryAssert.IsTrue(ADLSECredentials.IsClientCertificateSet(), 'IsClientCertificateSet should return true');
    end;

    [Test]
    procedure TestSetAndGetClientCertificatePassword()
    var
        ADLSECredentials: Codeunit "ADLSE Credentials";
        TestPassword: Text;
    begin
        // [SCENARIO] SetClientCertificatePassword stores and GetClientCertificatePassword retrieves the password
        // [GIVEN] A credentials instance
        Initialize();
        TestPassword := 'test-cert-password-' + Format(CreateGuid());

        // [WHEN] SetClientCertificatePassword is called followed by Init and GetClientCertificatePassword
        ADLSECredentials.SetClientCertificatePassword(TestPassword);
        ADLSECredentials.Init();

        // [THEN] The stored value is retrieved
        LibraryAssert.AreEqual(TestPassword, ADLSECredentials.GetClientCertificatePassword(), 'Certificate password should match');
    end;

    local procedure Initialize()
    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ADLSE Credentials Tests");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ADLSE Credentials Tests");

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ADLSE Credentials Tests");
    end;
}
