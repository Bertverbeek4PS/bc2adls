// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
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

    [NonDebuggable]
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
    begin
        ADLSESetup.GetSingleton();

        HttpClient.SetBaseAddress(Url);
        if not AddAuthorization(HttpClient, Response) then
            exit(false);

        if ADLSESetup.GetStorageType() = ADLSESetup."Storage Type"::"Azure Data Lake" then
            if AdditionalRequestHeaders.Count() > 0 then begin
                Headers := HttpClient.DefaultRequestHeaders();
                foreach HeaderKey in AdditionalRequestHeaders.Keys do begin
                    AdditionalRequestHeaders.Get(HeaderKey, HeaderValue);
                    Headers.Add(HeaderKey, HeaderValue);
                end;
            end;

        case HttpMethod of
            "ADLSE Http Method"::Get:
                HttpClient.Get(Url, HttpResponseMessage);
            "ADLSE Http Method"::Put:
                begin
                    HttpRequestMessage.Method('PUT');
                    HttpRequestMessage.SetRequestUri(Url);
                    AddContent(HttpContent);
                    HttpClient.Put(Url, HttpContent, HttpResponseMessage);
                end;
            "ADLSE Http Method"::Delete:
                HttpClient.Delete(Url, HttpResponseMessage);
            "ADLSE Http Method"::Patch:
                begin
                    HttpRequestMessage.Method('PATCH');
                    HttpRequestMessage.SetRequestUri(Url);
                    AddContent(HttpContent);
                    HttpRequestMessage.Content(HttpContent);
                    HttpClient.Send(HttpRequestMessage, HttpResponseMessage);
                end;
            "ADLSE Http Method"::Head:
                begin
                    HttpRequestMessage.Method('HEAD');
                    HttpRequestMessage.SetRequestUri(Url);
                    HttpClient.Send(HttpRequestMessage, HttpResponseMessage);
                end;
            else
                Error(UnsupportedMethodErr, HttpMethod);
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
        if (ADLSESetup.GetStorageType() = ADLSESetup."Storage Type"::"Azure Data Lake") or
        (ADLSESetup.GetStorageType() = ADLSESetup."Storage Type"::"Microsoft Fabric") and (not ContentTypeJson)
        then
            HttpContent.WriteFrom(Body);

        HttpContent.GetHeaders(Headers);

        if ContentTypeJson then begin
            Headers.Remove('Content-Type');
            Headers.Add('Content-Type', 'application/json');
            Headers.Remove('Content-Length');
            if ADLSESetup.GetStorageType() = ADLSESetup."Storage Type"::"Microsoft Fabric" then
                Headers.Add('Content-Length', '0');
        end;

        if (ADLSESetup.GetStorageType() = ADLSESetup."Storage Type"::"Microsoft Fabric") and (not ContentTypeJson) then
            Headers.Remove('Content-Length');
    end;

    [NonDebuggable]
    local procedure AddAuthorization(HttpClient: HttpClient; var Response: Text) Success: Boolean
    var
        ADLSEUtil: Codeunit "ADLSE Util";
        Headers: HttpHeaders;
        AccessToken: Text;
        AuthError: Text;
    begin
        if not Credentials.IsInitialized() then begin // anonymous call
            Success := true;
            exit;
        end;

        AccessToken := AcquireTokenOAuth2(AuthError);
        if AccessToken = '' then begin
            Response := AuthError;
            Success := false;
            exit;
        end;
        Headers := HttpClient.DefaultRequestHeaders();
        Headers.Add('Authorization', StrSubstNo(BearerTok, AccessToken));
        Headers.Add('x-ms-version', AzureStorageServiceVersionTok);
        Headers.Add('x-ms-date', ADLSEUtil.GetCurrentDateTimeInGMTFormat());
        Success := true;
    end;

    [NonDebuggable]
    local procedure AcquireTokenOAuth2(var AuthError: Text) AccessToken: Text
    var
        ADLSESetup: Record "ADLSE Setup";
        ADSEUtil: Codeunit "ADLSE Util";
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpContent: HttpContent;
        Headers: HttpHeaders;
        HttpResponseMessage: HttpResponseMessage;
        Uri: Text;
        RequestBody: Text;
        ResponseBody: Text;
        Json: JsonObject;
        ScopeUrlEncoded: Text;
    begin
        case ADLSESetup.GetStorageType() of
            ADLSESetup."Storage Type"::"Azure Data Lake":
                ScopeUrlEncoded := 'https%3A%2F%2Fstorage.azure.com%2Fuser_impersonation'; // url encoded form of https://storage.azure.com/user_impersonation
            ADLSESetup."Storage Type"::"Microsoft Fabric":
                ScopeUrlEncoded := 'https%3A%2F%2Fstorage.azure.com%2F.default'; // url encoded form of https://storage.azure.com/.default                
        end;

        Uri := StrSubstNo(OAuthTok, Credentials.GetTenantID());
        HttpRequestMessage.Method('POST');
        HttpRequestMessage.SetRequestUri(Uri);
        RequestBody :=
        StrSubstNo(
                    AcquireTokenBodyTok,
                    'https%3A%2F%2Fstorage.azure.com%2F', // url encoded form of https://storage.azure.com/
                    ScopeUrlEncoded,
                    Credentials.GetClientID(),
                    Credentials.GetClientSecret());
        HttpContent.WriteFrom(RequestBody);
        HttpContent.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/x-www-form-urlencoded');

        HttpClient.Post(Uri, HttpContent, HttpResponseMessage);
        HttpContent := HttpResponseMessage.Content();
        HttpContent.ReadAs(ResponseBody);
        if not HttpResponseMessage.IsSuccessStatusCode() then begin
            AuthError := ResponseBody;
            exit;
        end;

        Json.ReadFrom(ResponseBody);
        AccessToken := ADSEUtil.GetTextValueForKeyInJson(Json, 'access_token');
        // TODO: Store access token in cache, and use it based on expiry date. 
    end;
}