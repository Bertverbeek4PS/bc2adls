// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
codeunit 82571 "ADLSE Installer"
{
    Subtype = Install;
    Access = Internal;

    trigger OnInstallAppPerDatabase()
    begin
        DisableTablesExportingInvalidFields();
    end;

    trigger OnInstallAppPerCompany()
    begin
        AddAllowedTables();
    end;

    procedure AddAllowedTables()
    var
        ADLSERun: Record "ADLSE Run";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
    begin
        RetenPolAllowedTables.AddAllowedTable(Database::"ADLSE Run", ADLSERun.FieldNo(SystemModifiedAt));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Table", 'r')]
    procedure ListInvalidFieldsBeingExported() InvalidFieldsMap: Dictionary of [Integer, List of [Text]]
    var
        ADLSETable: Record "ADLSE Table";
        InvalidFields: List of [Text];
    begin
        // find the tables which export fields that have now been obsoleted or are invalid
        ADLSETable.SetRange(Enabled, true);
        if ADLSETable.FindSet() then
            repeat
                InvalidFields := ADLSETable.ListInvalidFieldsBeingExported();
                if InvalidFields.Count() > 0 then
                    InvalidFieldsMap.Add(ADLSETable."Table ID", InvalidFields);
            until ADLSETable.Next() = 0;
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"ADLSE Table", 'rm')]
    local procedure DisableTablesExportingInvalidFields()
    var
        ADLSETable: Record "ADLSE Table";
        ADLSEUtil: Codeunit "ADLSE Util";
        ADLSEExecution: Codeunit "ADLSE Execution";
        InvalidFieldsMap: Dictionary of [Integer, List of [Text]];
        CustomDimensions: Dictionary of [Text, Text];
        TableID: Integer;
    begin
        InvalidFieldsMap := ListInvalidFieldsBeingExported();
        foreach TableID in InvalidFieldsMap.Keys() do begin
            ADLSETable.Get(TableID);
            ADLSETable.Enabled := false;
            ADLSETable.Modify(true);

            Clear(CustomDimensions);
            CustomDimensions.Add('Entity', ADLSEUtil.GetTableCaption(TableID));
            CustomDimensions.Add('ListOfInvalidFields', ADLSEUtil.Concatenate(InvalidFieldsMap.Get(TableID)));
            ADLSEExecution.Log('ADLSE-31', 'Table is disabled for export because it exports invalid fields.', Verbosity::Warning, CustomDimensions);
        end;
    end;
}