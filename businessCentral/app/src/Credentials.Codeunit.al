// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
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

        Initialized: Boolean;
        ValueNotFoundErr: Label 'No value found for %1.', Comment = '%1 = name of the key';
        TenantIdKeyNameTok: Label 'adlse-tenant-id', Locked = true;
        ClientIdKeyNameTok: Label 'adlse-client-id', Locked = true;
        ClientSecretKeyNameTok: Label 'adlse-client-secret', Locked = true;

    [NonDebuggable]
    procedure Init()
    begin
        StorageTenantID := GetSecret(TenantIdKeyNameTok);
        ClientID := GetSecret(ClientIdKeyNameTok);
        ClientSecret := GetSecret(ClientSecretKeyNameTok);
        Initialized := true;
    end;

    procedure IsInitialized(): Boolean
    begin
        exit(Initialized);
    end;

    procedure Check()
    begin
        Init();
        CheckValueExists(TenantIdKeyNameTok, StorageTenantID);
        CheckValueExists(ClientIdKeyNameTok, ClientID);
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
    local procedure GetSecret(KeyName: Text) Secret: Text
    begin
        if not IsolatedStorage.Contains(KeyName, IsolatedStorageDataScope()) then
            exit('');
        IsolatedStorage.Get(KeyName, IsolatedStorageDataScope(), Secret);
    end;

    [NonDebuggable]
    local procedure SetSecret(KeyName: Text; Secret: Text)
    begin
        if EncryptionEnabled() then begin
            IsolatedStorage.SetEncrypted(KeyName, Secret, IsolatedStorageDataScope());
            exit;
        end;
        IsolatedStorage.Set(KeyName, Secret, IsolatedStorageDataScope());
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