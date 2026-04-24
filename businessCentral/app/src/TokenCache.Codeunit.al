// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
namespace bc2adls;

codeunit 82580 "ADLSE Token Cache"
{
    Access = Internal;

    var
        AccessTokenKeyNameTok: Label 'adlse-access-token', Locked = true;
        TokenExpiresAtKeyNameTok: Label 'adlse-token-expires', Locked = true;

    [NonDebuggable]
    procedure GetCachedToken(): SecretText
    var
        Token: SecretText;
    begin
        if not IsolatedStorage.Contains(AccessTokenKeyNameTok, DataScope::Module) then
            exit;
#pragma warning disable LC0043
        IsolatedStorage.Get(AccessTokenKeyNameTok, DataScope::Module, Token);
#pragma warning restore LC0043
        exit(Token);
    end;

    procedure GetTokenExpiry(): DateTime
    var
        ExpiresAtText: Text;
        ExpiresAt: DateTime;
    begin
#pragma warning disable LC0043
        if not IsolatedStorage.Get(TokenExpiresAtKeyNameTok, DataScope::Module, ExpiresAtText) then
            exit(0DT);
#pragma warning restore LC0043
        if not Evaluate(ExpiresAt, ExpiresAtText, 9) then
            exit(0DT);
        exit(ExpiresAt);
    end;

    [NonDebuggable]
    procedure SetToken(Token: SecretText; ExpiresAt: DateTime)
    begin
        ClearCache();
        WriteToCache(Token, ExpiresAt);
    end;

    [NonDebuggable]
    local procedure WriteToCache(Token: SecretText; ExpiresAt: DateTime)
    begin
#pragma warning disable LC0043
        IsolatedStorage.Set(AccessTokenKeyNameTok, Token, DataScope::Module);
        IsolatedStorage.Set(TokenExpiresAtKeyNameTok, Format(ExpiresAt, 0, 9), DataScope::Module);
#pragma warning restore LC0043
    end;

    procedure IsTokenValid(): Boolean
    begin
        if GetCachedToken().IsEmpty() then
            exit(false);
        exit(CurrentDateTime() < GetTokenExpiry());
    end;

    procedure ClearCache()
    begin
#pragma warning disable LC0043
        if IsolatedStorage.Contains(AccessTokenKeyNameTok, DataScope::Module) then
            IsolatedStorage.Delete(AccessTokenKeyNameTok, DataScope::Module);
        if IsolatedStorage.Contains(TokenExpiresAtKeyNameTok, DataScope::Module) then
            IsolatedStorage.Delete(TokenExpiresAtKeyNameTok, DataScope::Module);
#pragma warning restore LC0043
    end;
}