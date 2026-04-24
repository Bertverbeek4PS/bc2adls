// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
namespace bc2adls;

using System.Security.Authentication;
codeunit 82563 "ADLSE Http"
{
    Access = Internal;

    var
        Credentials: Codeunit "ADLSE Credentials";
        HttpMethod: Enum "ADLSE Http Method";
        Url: Text;
        Body: Text;
        ContentTypeJson: Boolean;
        AdditionalRequestHeaders: Dictionary of [Text, Text];
        ResponseHeaders, ResponseContentHeaders : HttpHeaders;
        AzureStorageServiceVersionTok: Label '2020-10-02', Locked = true; // Latest version from https://docs.microsoft.com/en-us/rest/api/storageservices/versioning-for-the-azure-storage-services
        ContentTypeApplicationJsonTok: Label 'application/json', Locked = true;
        ContentTypePlainTextTok: Label 'text/plain; charset=utf-8', Locked = true;
        UnsupportedMethodErr: Label 'Unsupported method: %1', Comment = '%1: http method name';
        OAuthAuthorityTok: Label 'https://login.microsoftonline.com/%1', Comment = '%1: tenant id', Locked = true;
        BearerTok: Label 'Bearer %1', Comment = '%1: access token', Locked = true;
        HttpRequestFailedErr: Label 'There was an error while executing the HTTP request, error request: %1.', Comment = '%1: error message';
        AcquireTokenFailedErr: Label 'Failed to acquire an access token. Verify the credentials configured in the ADLSE Setup.';

    procedure SetMethod(HttpMethodValue: Enum "ADLSE Http Method")
    begin
        HttpMethod := HttpMethodValue;
    end;

    procedure SetUrl(UrlValue: Text)
    begin
        Url := UrlValue;
    end;

    procedure AddHeader(HeaderKey: Text; HeaderValue: Text)
    begin
        AdditionalRequestHeaders.Add(HeaderKey, HeaderValue);
    end;

    procedure AddHeader(HeaderKey: Text; HeaderValue: Integer)
    var
        ADLSEUtil: Codeunit "ADLSE Util";
    begin
        AdditionalRequestHeaders.Add(HeaderKey, ADLSEUtil.ConvertNumberToText(HeaderValue));
    end;

    procedure SetBody(BodyValue: Text)
    begin
        Body := BodyValue;
    end;

    procedure SetContentIsJson()
    begin
        ContentTypeJson := true;
    end;

    procedure GetContentTypeJson(): Text
    begin
        exit(ContentTypeApplicationJsonTok);
    end;

    procedure GetContentTypeTextCsv(): Text
    begin
        exit(ContentTypePlainTextTok);
    end;

    procedure SetAuthorizationCredentials(ADLSECredentials: Codeunit "ADLSE Credentials")
    begin
        Credentials := ADLSECredentials;
    end;

    procedure GetResponseHeaderValue(HeaderKey: Text) Result: List of [Text]
    var
        Values: array[10] of Text;  // max 10 values in each header
        Counter: Integer;
    begin
        if not ResponseHeaders.Contains(HeaderKey) then
            exit;
        ResponseHeaders.GetValues(HeaderKey, Values);
        for Counter := 1 to 10 do
            Result.Add(Values[Counter]);
    end;

    procedure GetResponseContentHeaderValue(HeaderKey: Text) Result: List of [Text]
    var
        Values: array[10] of Text;  // max 10 values in each header
        Counter: Integer;
    begin
        if not ResponseContentHeaders.Contains(HeaderKey) then
            exit;
        ResponseContentHeaders.GetValues(HeaderKey, Values);
        for Counter := 1 to 10 do
            Result.Add(Values[Counter]);
    end;

    procedure InvokeRestApi(var Response: Text) Success: Boolean
    var
        StatusCode: Integer;
    begin
        Success := InvokeRestApi(Response, StatusCode);
    end;

    procedure InvokeRestApi(var Response: Text; var StatusCode: Integer) Success: Boolean
    var
        ADLSESetup: Record "ADLSE Setup";
        HttpClient: HttpClient;
        Headers: HttpHeaders;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        HttpContent: HttpContent;
        HeaderKey: Text;
        HeaderValue: Text;
        HttpRequestSucceeded: Boolean;
    begin
        ADLSESetup.GetSingleton();

        HttpClient.SetBaseAddress(Url);
        if not AddAuthorization(HttpClient, Response) then
            exit(false);

        if (ADLSESetup.GetStorageType() = ADLSESetup."Storage Type"::"Azure Data Lake")
            or (ADLSESetup.GetStorageType() = ADLSESetup."Storage Type"::"Open Mirroring")
        then
            if AdditionalRequestHeaders.Count() > 0 then begin
                Headers := HttpClient.DefaultRequestHeaders();
                foreach HeaderKey in AdditionalRequestHeaders.Keys() do begin
                    AdditionalRequestHeaders.Get(HeaderKey, HeaderValue);
                    Headers.Add(HeaderKey, HeaderValue);
                end;
            end;

        case HttpMethod of
            "ADLSE Http Method"::Get:
                HttpRequestSucceeded := HttpClient.Get(Url, HttpResponseMessage);
            "ADLSE Http Method"::Put:
                begin
                    HttpRequestMessage.Method('PUT');
                    HttpRequestMessage.SetRequestUri(Url);
                    AddContent(HttpContent);
                    HttpRequestSucceeded := HttpClient.Put(Url, HttpContent, HttpResponseMessage);
                end;
            "ADLSE Http Method"::Delete:
                HttpRequestSucceeded := HttpClient.Delete(Url, HttpResponseMessage);
            "ADLSE Http Method"::Patch:
                begin
                    HttpRequestMessage.Method('PATCH');
                    HttpRequestMessage.SetRequestUri(Url);
                    AddContent(HttpContent);
                    HttpRequestMessage.Content(HttpContent);
                    HttpRequestSucceeded := HttpClient.Send(HttpRequestMessage, HttpResponseMessage);
                end;
            "ADLSE Http Method"::Head:
                begin
                    HttpRequestMessage.Method('HEAD');
                    HttpRequestMessage.SetRequestUri(Url);
                    HttpRequestSucceeded := HttpClient.Send(HttpRequestMessage, HttpResponseMessage);
                end;
            else
                Error(UnsupportedMethodErr, HttpMethod);
        end;

        if not HttpRequestSucceeded then begin
            Response := StrSubstNo(HttpRequestFailedErr, HttpResponseMessage.ReasonPhrase());
            exit(false);
        end;

        HttpContent := HttpResponseMessage.Content();
        HttpContent.ReadAs(Response);
        ResponseHeaders := HttpResponseMessage.Headers();
        HttpResponseMessage.Content().GetHeaders(ResponseContentHeaders);
        Success := HttpResponseMessage.IsSuccessStatusCode();
        StatusCode := HttpResponseMessage.HttpStatusCode();
    end;

    local procedure AddContent(var HttpContent: HttpContent)
    var
        ADLSESetup: Record "ADLSE Setup";
        Headers: HttpHeaders;
    begin

        if (not ContentTypeJson) or (ADLSESetup.GetStorageType() = ADLSESetup."Storage Type"::"Azure Data Lake")
        then
            HttpContent.WriteFrom(Body);

        HttpContent.GetHeaders(Headers);
        if ContentTypeJson then begin
            Headers.Remove('Content-Type');
            Headers.Add('Content-Type', 'application/json');
            Headers.Remove('Content-Length');
            if ADLSESetup.GetStorageType() <> ADLSESetup."Storage Type"::"Azure Data Lake" then
                Headers.Add('Content-Length', '0');
        end;

        if (ADLSESetup.GetStorageType() <> ADLSESetup."Storage Type"::"Azure Data Lake") and (not ContentTypeJson) then
            Headers.Remove('Content-Type');
    end;

    local procedure AddAuthorization(HttpClient: HttpClient; var Response: Text) Success: Boolean
    var
        ADLSEUtil: Codeunit "ADLSE Util";
        Headers: HttpHeaders;
        AccessToken: SecretText;
        AuthError: Text;
    begin
        if not Credentials.IsInitialized() then begin // anonymous call
            Success := true;
            exit;
        end;

        AccessToken := AcquireTokenOAuth2(AuthError);
        if AccessToken.IsEmpty() then begin
            Response := AuthError;
            Success := false;
            exit;
        end;
        Headers := HttpClient.DefaultRequestHeaders();
        Headers.Add('Authorization', SecretStrSubstNo(BearerTok, AccessToken));
        Headers.Add('x-ms-version', AzureStorageServiceVersionTok);
        Headers.Add('x-ms-date', ADLSEUtil.GetCurrentDateTimeInGMTFormat());
        Success := true;
    end;

    [NonDebuggable]
    local procedure AcquireTokenOAuth2(var AuthError: Text) AccessToken: Text
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSETokenCache: Codeunit "ADLSE Token Cache";
        OAuth2: Codeunit OAuth2;
        AccessTokenSecret: SecretText;
        ClientSecretText: SecretText;
        CertificateSecret: SecretText;
        CertificatePasswordSecret: SecretText;
        IdToken: Text;
        Scopes: List of [Text];
        OAuthAuthorityUrl: Text;
    begin
        if ADLSETokenCache.IsTokenValid() then
            exit(ADLSETokenCache.GetCachedToken());

        case ADLSESetup.GetStorageType() of
            ADLSESetup."Storage Type"::"Azure Data Lake":
                Scopes.Add('https://storage.azure.com/user_impersonation');
            ADLSESetup."Storage Type"::"Microsoft Fabric":
                Scopes.Add('https://storage.azure.com/.default');
        end;

        OAuthAuthorityUrl := StrSubstNo(OAuthAuthorityTok, Credentials.GetTenantID());
        ADLSESetup.GetSingleton();
        if ADLSESetup."Use Certificate Authentication" then begin
            CertificateSecret := Credentials.GetClientCertificate();
            CertificatePasswordSecret := Credentials.GetClientCertificatePassword();
            OAuth2.AcquireTokensWithCertificate(
                Credentials.GetClientID(), CertificateSecret, CertificatePasswordSecret,
                '', OAuthAuthorityUrl, Scopes, AccessTokenSecret, IdToken);
        end else begin
            ClientSecretText := Credentials.GetClientSecret();
            OAuth2.AcquireTokenWithClientCredentials(
                Credentials.GetClientID(), ClientSecretText,
                OAuthAuthorityUrl, '', Scopes, AccessTokenSecret);
        end;

        AccessToken := AccessTokenSecret.Unwrap();
        if AccessToken = '' then begin
            AuthError := AcquireTokenFailedErr;
            exit;
        end;

        // Cache the token with a default 55-minute window (tokens typically last 1 hour)
        ADLSETokenCache.SetToken(AccessToken, CurrentDateTime() + (55 * 60 * 1000));
    end;
}