// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
namespace bc2adls;

using System.Security.Cryptography.X509Certificates;
using System.Security.Cryptography;
using System.Utilities;
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
        OAuthTok: Label 'https://login.microsoftonline.com/%1/oauth2/token', Comment = '%1: tenant id', Locked = true;
        BearerTok: Label 'Bearer %1', Comment = '%1: access token', Locked = true;
        AcquireTokenBodyTok: Label 'resource=%1&scope=%2&client_id=%3&client_secret=%4&grant_type=client_credentials', Comment = '%1: encoded resource url, %2: encoded scope url, %3: client ID, %4: client secret', Locked = true;
        AcquireTokenCertBodyTok: Label 'resource=%1&scope=%2&client_id=%3&client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer&client_assertion=%4&grant_type=client_credentials', Comment = '%1: encoded resource url, %2: encoded scope url, %3: client ID, %4: JWT assertion', Locked = true;
        JwtHeaderTok: Label '{"alg":"RS256","typ":"JWT","x5t":"%1"}', Comment = '%1: base64url-encoded SHA-1 thumbprint', Locked = true;
        JwtPayloadTok: Label '{"aud":"%1","exp":%2,"iss":"%3","jti":"%4","nbf":%5,"sub":"%6"}', Comment = '%1: audience, %2: expiry unix time, %3: issuer (client id), %4: jti guid, %5: not-before unix time, %6: subject (client id)', Locked = true;
        HttpRequestFailedErr: Label 'There was an error while executing the HTTP request, error request: %1.', Comment = '%1: error message';
        AuthHttpRequestFailedErr: Label 'There was an error while acquiring the authentication token, error request: %1.', Comment = '%1: error message';
        CertificateLoadFailedErr: Label 'Could not load the certificate for authentication. Verify the certificate Base64 value and password.';
        InvalidCertificatePrivateKeyErr: Label 'Could not retrieve the private key from the certificate. Ensure the PFX contains a private key.';

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
        ADLSEUtil: Codeunit "ADLSE Util";
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpContent: HttpContent;
        Headers: HttpHeaders;
        HttpResponseMessage: HttpResponseMessage;
        Json: JsonObject;
        Uri: Text;
        RequestBody: Text;
        ResponseBody: Text;
        ScopeUrlEncoded: Text;
        ExpiresInSeconds: Integer;
        HttpRequestFailed: Boolean;
    begin
        // Return cached token if still valid
        if ADLSETokenCache.IsTokenValid() then
            exit(ADLSETokenCache.GetCachedToken());

        case ADLSESetup.GetStorageType() of
            ADLSESetup."Storage Type"::"Azure Data Lake":
                ScopeUrlEncoded := 'https%3A%2F%2Fstorage.azure.com%2Fuser_impersonation'; // url encoded form of https://storage.azure.com/user_impersonation
            ADLSESetup."Storage Type"::"Microsoft Fabric":
                ScopeUrlEncoded := 'https%3A%2F%2Fstorage.azure.com%2F.default'; // url encoded form of https://storage.azure.com/.default                
        end;

        Uri := StrSubstNo(OAuthTok, Credentials.GetTenantID());
        HttpRequestMessage.Method('POST');
        HttpRequestMessage.SetRequestUri(Uri);

        ADLSESetup.GetSingleton();
        if ADLSESetup."Use Certificate Authentication" then
            RequestBody := BuildCertificateTokenRequestBody(ScopeUrlEncoded, Uri, AuthError)
        else
            RequestBody :=
                StrSubstNo(
                    AcquireTokenBodyTok,
                    'https%3A%2F%2Fstorage.azure.com%2F', // url encoded form of https://storage.azure.com/
                    ScopeUrlEncoded,
                    Credentials.GetClientID(),
                    Credentials.GetClientSecret());

        if RequestBody = '' then
            exit; // AuthError already set

        HttpContent.WriteFrom(RequestBody);
        HttpContent.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/x-www-form-urlencoded');

        HttpRequestFailed := not HttpClient.Post(Uri, HttpContent, HttpResponseMessage);
        if HttpRequestFailed then begin
            AuthError := StrSubstNo(AuthHttpRequestFailedErr, HttpResponseMessage.ReasonPhrase());
            exit;
        end;

        HttpContent := HttpResponseMessage.Content();
        HttpContent.ReadAs(ResponseBody);
        if not HttpResponseMessage.IsSuccessStatusCode() then begin
            AuthError := ResponseBody;
            exit;
        end;

        Json.ReadFrom(ResponseBody);
        AccessToken := ADLSEUtil.GetTextValueForKeyInJson(Json, 'access_token');

        // Cache the token with expiry (subtract 5 minutes for safety margin)
        // expires_in is in seconds, default to 3600 (1 hour) if not present
        if not Evaluate(ExpiresInSeconds, ADLSEUtil.GetTextValueForKeyInJson(Json, 'expires_in')) then
            ExpiresInSeconds := 3600;
        ADLSETokenCache.SetToken(AccessToken, CurrentDateTime() + (ExpiresInSeconds * 1000) - (5 * 60 * 1000));
    end;

    [NonDebuggable]
    local procedure BuildCertificateTokenRequestBody(ScopeUrlEncoded: Text; AudienceUri: Text; var AuthError: Text) RequestBody: Text
    var
        X509Cert: Codeunit "X509Certificate2";
        RSA: Codeunit "RSACryptoServiceProvider";
        CertBase64: Text;
        CertPasswordText: Text;
        CertPassword: SecretText;
        CertThumbprintBase64Url: Text;
        PrivateKeyXml: Text;
        JwtHeader: Text;
        JwtPayload: Text;
        JwtHeaderEncoded: Text;
        JwtPayloadEncoded: Text;
        JwtSigningInput: Text;
        SignatureBase64: Text;
        JwtAssertion: Text;
        NowUnix: BigInteger;
        ExpUnix: BigInteger;
        Jti: Text;
    begin
        CertBase64 := Credentials.GetClientCertificate();
        CertPasswordText := Credentials.GetClientCertificatePassword();
        CertPassword := CertPasswordText;

        if not X509Cert.VerifyCertificate(CertBase64, CertPassword, Enum::"X509 Content Type"::Pfx, AuthError) then begin
            AuthError := CertificateLoadFailedErr + ' ' + AuthError;
            exit('');
        end;

        // The hex thumbprint (SHA-1) is base64url-encoded to produce the JWT x5t header value
        CertThumbprintBase64Url := HexToBase64Url(X509Cert.GetCertificateThumbprint(CertBase64, CertPassword, false));

        if not X509Cert.GetCertificatePrivateKey(CertBase64, CertPassword, PrivateKeyXml) then begin
            AuthError := InvalidCertificatePrivateKeyErr;
            exit('');
        end;

        // Current time as Unix epoch (seconds)
        NowUnix := Round((CurrentDateTime() - CreateDateTime(DMY2Date(1, 1, 1970), 0T)) / 1000, 1, '<');
        ExpUnix := NowUnix + 600; // 10-minute assertion lifetime
        Jti := Format(CreateGuid());

        JwtHeader := StrSubstNo(JwtHeaderTok, CertThumbprintBase64Url);
        JwtPayload := StrSubstNo(JwtPayloadTok, AudienceUri, ExpUnix, Credentials.GetClientID(), Jti, NowUnix, Credentials.GetClientID());

        JwtHeaderEncoded := Base64UrlEncode(JwtHeader);
        JwtPayloadEncoded := Base64UrlEncode(JwtPayload);
        JwtSigningInput := JwtHeaderEncoded + '.' + JwtPayloadEncoded;

        RSA.FromXmlString(PrivateKeyXml);
        if not RSA.SignData(JwtSigningInput, Enum::"Hash Algorithm"::SHA256, Enum::"RSA Signature Padding"::Pkcs1, SignatureBase64) then begin
            AuthError := InvalidCertificatePrivateKeyErr;
            exit('');
        end;
        SignatureBase64 := SignatureBase64.Replace('+', '-').Replace('/', '_').Replace('=', '');

        JwtAssertion := JwtSigningInput + '.' + SignatureBase64;

        RequestBody :=
            StrSubstNo(
                AcquireTokenCertBodyTok,
                'https%3A%2F%2Fstorage.azure.com%2F',
                ScopeUrlEncoded,
                Credentials.GetClientID(),
                JwtAssertion);
    end;

    [NonDebuggable]
    local procedure Base64UrlEncode(InputText: Text) Encoded: Text
    var
        Base64: Codeunit "Base64 Convert";
    begin
        Encoded := Base64.ToBase64(InputText);
        Encoded := Encoded.Replace('+', '-').Replace('/', '_').Replace('=', '');
    end;

    // Converts a hex-encoded byte string (e.g. SHA-1 thumbprint) to base64url encoding.
    local procedure HexToBase64Url(HexString: Text) Result: Text
    var
        Base64: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        OStream: OutStream;
        IStream: InStream;
        HexDigits: Text;
        I: Integer;
        ByteVal: Integer;
    begin
        HexDigits := '0123456789abcdef';
        HexString := LowerCase(HexString);
        TempBlob.CreateOutStream(OStream);
        for I := 1 to StrLen(HexString) div 2 do begin
            ByteVal :=
                (StrPos(HexDigits, CopyStr(HexString, (I - 1) * 2 + 1, 1)) - 1) * 16 +
                (StrPos(HexDigits, CopyStr(HexString, (I - 1) * 2 + 2, 1)) - 1);
            OStream.Write(ByteVal, 1);
        end;
        TempBlob.CreateInStream(IStream);
        Result := Base64.ToBase64(IStream);
        Result := Result.Replace('+', '-').Replace('/', '_').Replace('=', '');
    end;
}