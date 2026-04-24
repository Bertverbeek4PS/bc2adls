// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
namespace bc2adls;
codeunit 82565 "ADLSE Credentials"
{
    Access = Internal;
    // The max sizes of the fields are determined based on the recommendations listed at 
    // https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftstorage

    var
        [NonDebuggable]
        ClientID: Text;

        [NonDebuggable]
        ClientSecret: Text;

        [NonDebuggable]
        StorageTenantID: Text;

        [NonDebuggable]
        ClientCertificate: Text;

        [NonDebuggable]
        ClientCertificatePassword: Text;

        Initialized: Boolean;
        ValueNotFoundErr: Label 'No value found for %1.', Comment = '%1 = name of the key';
        TenantIdKeyNameTok: Label 'adlse-tenant-id', Locked = true;
        ClientIdKeyNameTok: Label 'adlse-client-id', Locked = true;
        ClientSecretKeyNameTok: Label 'adlse-client-secret', Locked = true;
        ClientCertificateKeyNameTok: Label 'adlse-certificate', Locked = true;
        ClientCertificatePasswordKeyNameTok: Label 'adlse-certificate-password', Locked = true;

    [NonDebuggable]
    procedure Init()
    begin
        StorageTenantID := GetSecret(TenantIdKeyNameTok);
        ClientID := GetSecret(ClientIdKeyNameTok);
        ClientSecret := GetSecret(ClientSecretKeyNameTok);
        ClientCertificate := GetSecret(ClientCertificateKeyNameTok);
        ClientCertificatePassword := GetSecret(ClientCertificatePasswordKeyNameTok);
        Initialized := true;
    end;

    procedure IsInitialized(): Boolean
    begin
        exit(Initialized);
    end;

    procedure Check()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        Init();
        CheckValueExists(TenantIdKeyNameTok, StorageTenantID);
        CheckValueExists(ClientIdKeyNameTok, ClientID);
        ADLSESetup.GetSingleton();
        if ADLSESetup."Use Certificate Authentication" then
            CheckValueExists(ClientCertificateKeyNameTok, ClientCertificate)
        else
            CheckValueExists(ClientSecretKeyNameTok, ClientSecret);
    end;

    [NonDebuggable]
    procedure GetTenantID(): Text
    begin
        exit(StorageTenantID);
    end;

    [NonDebuggable]
    procedure SetTenantID(NewTenantIdValue: Text): Text
    begin
        StorageTenantID := NewTenantIdValue;
        SetSecret(TenantIdKeyNameTok, NewTenantIdValue);
    end;

    [NonDebuggable]
    procedure GetClientID(): Text
    begin
        exit(ClientID);
    end;

    [NonDebuggable]
    procedure SetClientID(NewClientIDValue: Text): Text
    begin
        ClientID := NewClientIDValue;
        SetSecret(ClientIdKeyNameTok, NewClientIDValue);
    end;

    [NonDebuggable]
    procedure IsClientIDSet(): Boolean
    begin
        exit(GetClientID() <> '');
    end;

    [NonDebuggable]
    procedure GetClientSecret(): Text
    begin
        exit(ClientSecret);
    end;

    [NonDebuggable]
    procedure SetClientSecret(NewClientSecretValue: Text): Text
    begin
        ClientSecret := NewClientSecretValue;
        SetSecret(ClientSecretKeyNameTok, NewClientSecretValue);
    end;

    [NonDebuggable]
    procedure IsClientSecretSet(): Boolean
    begin
        exit(GetClientSecret() <> '');
    end;

    [NonDebuggable]
    procedure GetClientCertificate(): Text
    begin
        exit(ClientCertificate);
    end;

    [NonDebuggable]
    procedure SetClientCertificate(NewCertificateValue: Text): Text
    begin
        ClientCertificate := NewCertificateValue;
        // Certificates are too large for IsolatedStorage.SetEncrypted; store plain.
        // The PFX is protected by its own password (stored encrypted separately).
        SetPlain(ClientCertificateKeyNameTok, NewCertificateValue);
    end;

    [NonDebuggable]
    procedure IsClientCertificateSet(): Boolean
    begin
        exit(GetClientCertificate() <> '');
    end;

    [NonDebuggable]
    procedure GetClientCertificatePassword(): Text
    begin
        exit(ClientCertificatePassword);
    end;

    [NonDebuggable]
    procedure SetClientCertificatePassword(NewPasswordValue: Text): Text
    begin
        ClientCertificatePassword := NewPasswordValue;
        SetSecret(ClientCertificatePasswordKeyNameTok, NewPasswordValue);
    end;

    [NonDebuggable]
    local procedure GetSecret(KeyName: Text) Secret: Text
    begin
        if not IsolatedStorage.Contains(KeyName, IsolatedStorageDataScope()) then
            exit('');
#pragma warning disable LC0043            
        IsolatedStorage.Get(KeyName, IsolatedStorageDataScope(), Secret);
#pragma warning restore LC0043
    end;

    [NonDebuggable]
    local procedure SetSecret(KeyName: Text; Secret: Text)
    begin
#pragma warning disable LC0043
        if EncryptionEnabled() and EncryptionKeyExists() then begin
            IsolatedStorage.SetEncrypted(KeyName, Secret, IsolatedStorageDataScope());
            exit;
        end;
        IsolatedStorage.Set(KeyName, Secret, IsolatedStorageDataScope());
#pragma warning restore LC0043
    end;

    [NonDebuggable]
    local procedure SetPlain(KeyName: Text; Value: Text)
    begin
#pragma warning disable LC0043
        IsolatedStorage.Set(KeyName, Value, IsolatedStorageDataScope());
#pragma warning restore LC0043
    end;

    [NonDebuggable]
    local procedure CheckValueExists(KeyName: Text; Val: Text)
    begin
        if Val.Trim() = '' then
            Error(ValueNotFoundErr, KeyName);
    end;

    local procedure IsolatedStorageDataScope(): DataScope
    begin
        exit(DataScope::Module); // so that all companies share the same settings
    end;
}