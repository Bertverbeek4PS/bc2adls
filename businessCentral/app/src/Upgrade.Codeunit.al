// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
codeunit 82572 "ADLSE Upgrade"
{
    Subtype = Upgrade;
    Access = Internal;

    trigger OnCheckPreconditionsPerDatabase()
    var
        ADLSEInstaller: Codeunit "ADLSE Installer";
        ADLSEExecution: Codeunit "ADLSE Execution";
        InvalidFieldsMap: Dictionary of [Integer, List of [Text]];
    begin
        InvalidFieldsMap := ADLSEInstaller.ListInvalidFieldsBeingExported();
        if InvalidFieldsMap.Count() > 0 then begin
            ADLSEExecution.Log('ADLSE-30',
                'Upgrade preconditions not met as there are invalid fields enabled for export. Please see previous telemetry.', Verbosity::Error);
            // raise error on encountering invalid fields so user can react to these errors and fix the export configuration
            Message(InvalidFieldsBeingExportedErr, ConcatenateTableFieldPairs(InvalidFieldsMap));
        end;
    end;

    trigger OnUpgradePerCompany()
    begin
        RetenPolLogEntryAdded();
        ContainerFieldFromIsolatedStorageToSetupField();
        SeperateSchemaAndData();
    end;

    var
        TableFieldsTok: Label '[%1]: %2', Comment = '%1: table caption, %2: list of field captions', Locked = true;
        InvalidFieldsBeingExportedErr: Label 'The following table fields cannot be exported. Please disable them. %1', Comment = '%1 = List of table - field pairs';

    local procedure RetenPolLogEntryAdded()
    var
        ADLSEInstaller: Codeunit "ADLSE Installer";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetRetenPolLogEntryAddedUpgradeTag()) then
            exit;
        ADLSEInstaller.AddAllowedTables();
        UpgradeTag.SetUpgradeTag(GetRetenPolLogEntryAddedUpgradeTag());
    end;

    local procedure ContainerFieldFromIsolatedStorageToSetupField()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetContainerFieldFromIsolatedStorageToSetupFieldUpgradeTag()) then
            exit;
        DoContainerFieldFromIsolatedStorageToSetupField();
        UpgradeTag.SetUpgradeTag(GetContainerFieldFromIsolatedStorageToSetupFieldUpgradeTag());
    end;

    local procedure ConcatenateTableFieldPairs(TableIDFieldNameList: Dictionary of [Integer, List of [Text]]) Result: Text
    var
        ADLSEUtil: Codeunit "ADLSE Util";
        TableID: Integer;
    begin
        foreach TableID in TableIDFieldNameList.Keys() do
            Result += StrSubstNo(TableFieldsTok, ADLSEUtil.GetTableCaption(TableID), ADLSEUtil.Concatenate(TableIDFieldNameList.Get(TableID)));
    end;

    local procedure DoContainerFieldFromIsolatedStorageToSetupField()
    var
        ADLSESetup: Record "ADLSE Setup";
        AccountName: Text;
        StorageAccountKeyNameTok: Label 'adlse-storage-account', Locked = true;
    begin
        if not IsolatedStorage.Contains(StorageAccountKeyNameTok, DataScope::Module) then
            exit;
        IsolatedStorage.Get(StorageAccountKeyNameTok, DataScope::Module, AccountName);

        if not ADLSESetup.Exists() then
            exit;
        ADLSESetup.GetSingleton();

        if ADLSESetup."Account Name" <> '' then
            exit;
        ADLSESetup."Account Name" := CopyStr(AccountName, 1, MaxStrLen(ADLSESetup."Account Name"));
        ADLSESetup.Modify(true);

        IsolatedStorage.Delete(StorageAccountKeyNameTok, DataScope::Module);
    end;

    local procedure SeperateSchemaAndData()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetSeperateSchemaAndDataUpgradeTag()) then
            exit;
        DoGetSeperateSchemaAndData();
        UpgradeTag.SetUpgradeTag(GetSeperateSchemaAndDataUpgradeTag());
    end;

    local procedure DoGetSeperateSchemaAndData()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        if not ADLSESetup.Exists() then
            exit;
        ADLSESetup.GetSingleton();

        if ADLSESetup."Multi- Company Export" then begin
            ADLSESetup."Schema Exported On" := CurrentDateTime();
            ADLSESetup.Modify();
        end;
    end;


    procedure GetRetenPolLogEntryAddedUpgradeTag(): Code[250]
    begin
        exit('MS-334067-ADLSERetenPolLogEntryAdded-20221028');
    end;

    procedure GetContainerFieldFromIsolatedStorageToSetupFieldUpgradeTag(): Code[250]
    begin
        exit('GITHUB-22-ADLSEContainerFieldFromIsolatedStorageToSetupField-20230906');
    end;

    procedure GetSeperateSchemaAndDataUpgradeTag(): Code[250]
    begin
        exit('GITHUB-35-ADLSESeperateSchemaAndData-20230922');
    end;
}