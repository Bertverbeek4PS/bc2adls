codeunit 82579 "Azure Subscribers"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ADLSE Execution", 'OnStartExportOnAfterCheckSetup', '', true, true)]
    local procedure OnStartExportOnAfterCheckSetup()
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSE: Codeunit ADLSE;
        ADLSEGen2Util: Codeunit "ADLSE Gen 2 Util";
        ADLSECredentials: Codeunit "ADLSE Credentials";
        ADLSIntegrations: Interface "ADLS Integrations";
    begin
        ADLSESetup.GetSingleton();
        if ADLSESetup."Storage Type" <> ADLSESetup."Storage Type"::"Azure Data Lake" then
            exit;

        ADLSE.selectbc2adlsIntegrations(ADLSIntegrations);
        ADLSECredentials.Init();

        if not ADLSEGen2Util.ContainerExists(ADLSIntegrations.GetBaseUrl(), ADLSECredentials) then
            ADLSEGen2Util.CreateContainer(ADLSIntegrations.GetBaseUrl(), ADLSECredentials);
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ADLSE Http", 'OnBeforeAddContent', '', true, true)]
    local procedure OnBeforeAddContent(var HttpContent: HttpContent; ContentTypeJson: Boolean; body: Text)
    var
        ADLSESetup: Record "ADLSE Setup";
        Headers: HttpHeaders;
    begin
        ADLSESetup.GetSingleton();
        if ADLSESetup."Storage Type" <> ADLSESetup."Storage Type"::"Azure Data Lake" then
            exit;

        if (ADLSESetup.GetStorageType() = ADLSESetup."Storage Type"::"Azure Data Lake") then
            HttpContent.WriteFrom(Body);

        HttpContent.GetHeaders(Headers);

        if ContentTypeJson then begin
            Headers.Remove('Content-Type');
            Headers.Add('Content-Type', 'application/json');
            Headers.Remove('Content-Length');
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ADLSE Http", 'OnBeforeAcquireTokenOAuth2', '', true, true)]
    local procedure OnBeforeAcquireTokenOAuth2(var ScopeUrlEncoded: Text)
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        ADLSESetup.GetSingleton();
        if ADLSESetup."Storage Type" <> ADLSESetup."Storage Type"::"Azure Data Lake" then
            exit;

        ScopeUrlEncoded := 'https%3A%2F%2Fstorage.azure.com%2Fuser_impersonation'; // url encoded form of https://storage.azure.com/user_impersonation
    end;
}