codeunit 82578 "Fabric Lakehouse Integration" implements "ADLS Integrations"
{
    procedure GetBaseUrl(): Text
    var
        ADLSESetup: Record "ADLSE Setup";
        ValidGuid: Guid;
        MSFabricUrlTxt: Label 'https://onelake.dfs.fabric.microsoft.com/%1/%2.Lakehouse/Files', Locked = true, Comment = '%1: Workspace name, %2: Lakehouse Name';
        MSFabricUrlGuidTxt: Label 'https://onelake.dfs.fabric.microsoft.com/%1/%2/Files', Locked = true, Comment = '%1: Workspace name, %2: Lakehouse Name';
    begin
        ADLSESetup.GetSingleton();

        if not Evaluate(ValidGuid, ADLSESetup.Lakehouse) then
            exit(StrSubstNo(MSFabricUrlTxt, ADLSESetup.Workspace, ADLSESetup.Lakehouse))
        else
            exit(StrSubstNo(MSFabricUrlGuidTxt, ADLSESetup.Workspace, ADLSESetup.Lakehouse));
    end;

    procedure ResetTableExport(ltableId: Integer)
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSEUtil: Codeunit "ADLSE Util";
        ADLSEGen2Util: Codeunit "ADLSE Gen 2 Util";
        ADLSECredentials: Codeunit "ADLSE Credentials";
        Body: JsonObject;
        ResetTableExportTxt: Label '/reset/%1.txt', Locked = true, Comment = '%1 = Table name';
    begin
        ADLSESetup.GetSingleton();
        ADLSECredentials.Init();

        ADLSEGen2Util.CreateOrUpdateJsonBlob(GetBaseUrl() + StrSubstNo(ResetTableExportTxt, ADLSEUtil.GetDataLakeCompliantTableName(ltableId)), ADLSECredentials, '', Body);
    end;
}