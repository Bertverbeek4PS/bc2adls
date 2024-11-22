codeunit 82577 "Azure Integration" implements "ADLS Integrations"
{
    procedure GetBaseUrl(): Text
    var
        ADLSESetup: Record "ADLSE Setup";
        DefaultContainerName: Text;
        ContainerUrlTxt: Label 'https://%1.blob.core.windows.net/%2', Comment = '%1: Account name, %2: Container Name';
    begin
        ADLSESetup.GetSingleton();

        if DefaultContainerName = '' then
            DefaultContainerName := ADLSESetup.Container;

        exit(StrSubstNo(ContainerUrlTxt, ADLSESetup."Account Name", DefaultContainerName));
    end;

    procedure ResetTableExport(ltableId: Integer)
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSEUtil: Codeunit "ADLSE Util";
        ADLSEGen2Util: Codeunit "ADLSE Gen 2 Util";
        ADLSECredentials: Codeunit "ADLSE Credentials";
    begin
        ADLSESetup.GetSingleton();
        ADLSECredentials.Init();
        ADLSEGen2Util.RemoveDeltasFromDataLake(ADLSEUtil.GetDataLakeCompliantTableName(ltableId), ADLSECredentials);
    end;
}