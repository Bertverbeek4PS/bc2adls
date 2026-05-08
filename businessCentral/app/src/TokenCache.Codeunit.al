// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
namespace bc2adls;
// Token cache uses in-memory storage (SingleInstance) instead of IsolatedStorage
// to avoid lock conflicts between parallel export sessions.
// Each session caches its own token; cross-session sharing is not needed

codeunit 82580 "ADLSE Token Cache"
{
    Access = Internal;
    SingleInstance = true;

    var
        CachedToken: SecretText;
        CachedTokenExpiry: DateTime;

    [NonDebuggable]
    procedure GetCachedToken(): SecretText
    begin
        exit(CachedToken);
    end;

    [NonDebuggable]
    procedure SetToken(Token: SecretText; ExpiresAt: DateTime)
    begin
        CachedToken := Token;
        CachedTokenExpiry := ExpiresAt;
    end;

    procedure IsTokenValid(): Boolean
    begin
        if CachedToken.IsEmpty() then
            exit(false);
        exit(CurrentDateTime() < CachedTokenExpiry);
    end;
}