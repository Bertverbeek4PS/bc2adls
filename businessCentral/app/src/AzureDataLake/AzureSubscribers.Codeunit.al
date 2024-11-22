codeunit 82579 "Azure Subscribers"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ADLSE Execution", 'OnStartExportOnAfterCheckSetup', '', true, true)]
    local procedure OnStartExportOnAfterCheckSetup()
    var
        ADLSE: Codeunit ADLSE;
        ADLSEGen2Util: Codeunit "ADLSE Gen 2 Util";
        ADLSECredentials: Codeunit "ADLSE Credentials";
        ADLSIntegrations: Interface "ADLS Integrations";
    begin
        ADLSE.selectbc2adlsIntegrations(ADLSIntegrations);
        ADLSECredentials.Init();

        if not ADLSEGen2Util.ContainerExists(ADLSIntegrations.GetBaseUrl(), ADLSECredentials) then
            ADLSEGen2Util.CreateContainer(ADLSIntegrations.GetBaseUrl(), ADLSECredentials);
    end;
}