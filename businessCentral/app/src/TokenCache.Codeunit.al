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
    procedure GetCachedToken(): Text
    var
        Token: Text;
    begin
        if not IsolatedStorage.Contains(AccessTokenKeyNameTok, DataScope::Module) then
            exit('');
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
    procedure SetToken(Token: Text; ExpiresAt: DateTime)
    begin
        // Guard against concurrent sessions attempting to insert the same key simultaneously.
        // IsolatedStorage.Set does INSERT when the key is not yet visible in this session,
        // so a concurrent committed insert by another session causes "record already exists".
        // Note: On BC On-Premises, DisableWriteInsideTryFunctions is True by default,
        // which blocks database writes (incl. IsolatedStorage) in TryFunction procedures.
        // Set it to False in the server configuration if you encounter token cache errors.
        // See https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-handling-errors-using-try-methods
        if not TryWriteToCache(Token, ExpiresAt) then begin
            ClearCache();
            if not TryWriteToCache(Token, ExpiresAt) then;
        end;
    end;

    [TryFunction]
    [NonDebuggable]
    local procedure TryWriteToCache(Token: Text; ExpiresAt: DateTime)
    begin
#pragma warning disable LC0043
        IsolatedStorage.Set(AccessTokenKeyNameTok, Token, DataScope::Module);
        IsolatedStorage.Set(TokenExpiresAtKeyNameTok, Format(ExpiresAt, 0, 9), DataScope::Module);
#pragma warning restore LC0043
    end;

    procedure IsTokenValid(): Boolean
    begin
        if GetCachedToken() = '' then
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