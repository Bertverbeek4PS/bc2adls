// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
codeunit 82574 "ADLSE External Events"
{
    SingleInstance = true;

    var
        ADLSEExternalEventsHelper: Codeunit "ADLSE External Events Helper";
        StorageType, Instance, Resource : Text[250];

    internal procedure OnTableExportRunEnded(RunId: Integer; Started: DateTime; Ended: DateTime; TableId: Integer; State: Enum "ADLSE Run State")
    var
        ADLSEUtil: Codeunit "ADLSE Util";
    begin
        GetSetup();

        ExportEntityEnded(RunId, Started, Ended, State, StorageType, Instance, Resource, CopyStr(ADLSEUtil.GetDataLakeCompliantTableName(TableId), 1, 250));
#pragma warning disable AL0432
        TableExportRunEnded(RunId, State, Instance, CopyStr(ADLSEUtil.GetDataLakeCompliantTableName(TableId), 1, 250));
#pragma warning restore AL0432
    end;

    internal procedure OnEnableFieldChanged(ADLSEField: Record "ADLSE Field")
    var
        ADLSESetup: Record "ADLSE Setup";
        Url: Text[250];
        WebClientUrl: Text[250];
        ADLSEFieldApiUrlTok: Label 'bc2adlsTeamMicrosoft/bc2adls/v1.0/companies(%1)/adlseFields(%2)', Locked = true;
    begin
        ADLSESetup.GetSingleton();
        Url := ADLSEExternalEventsHelper.CreateLink(ADLSEFieldApiUrlTok, ADLSEField.SystemId);
        WebClientUrl := CopyStr(GetUrl(ClientType::Web, CompanyName(), ObjectType::Page, Page::"ADLSE Setup", ADLSESetup), 1, MaxStrLen(WebClientUrl));
        MyBusinessEventEnableFieldChanged(ADLSEField.SystemId, ADLSEField."Table ID", ADLSEField."Field ID", ADLSEField.Enabled, Url, WebClientUrl);
    end;

    internal procedure OnEnableTableChanged(ADLSEtable: Record "ADLSE Table")
    var
        ADLSESetup: Record "ADLSE Setup";
        Url: Text[250];
        WebClientUrl: Text[250];
        ADLSEFieldApiUrlTok: Label 'bc2adlsTeamMicrosoft/bc2adls/v1.0/companies(%1)/adlseTables(%2)', Locked = true;
    begin
        ADLSESetup.GetSingleton();
        Url := ADLSEExternalEventsHelper.CreateLink(ADLSEFieldApiUrlTok, ADLSEtable.SystemId);
        WebClientUrl := CopyStr(GetUrl(ClientType::Web, CompanyName(), ObjectType::Page, Page::"ADLSE Setup", ADLSESetup), 1, MaxStrLen(WebClientUrl));
        MyBusinessEventEnableTableChanged(ADLSEtable.SystemId, ADLSEtable."Table ID", ADLSEtable.Enabled, Url, WebClientUrl);
    end;

    internal procedure OnAddTable(ADLSETable: Record "ADLSE Table")
    var
        ADLSESetup: Record "ADLSE Setup";
        Url: Text[250];
        WebClientUrl: Text[250];
        ADLSEFieldApiUrlTok: Label 'bc2adlsTeamMicrosoft/bc2adls/v1.0/companies(%1)/adlseTables(%2)', Locked = true;
    begin
        ADLSESetup.GetSingleton();
        Url := ADLSEExternalEventsHelper.CreateLink(ADLSEFieldApiUrlTok, ADLSETable.SystemId);
        WebClientUrl := CopyStr(GetUrl(ClientType::Web, CompanyName(), ObjectType::Page, Page::"ADLSE Setup", ADLSESetup), 1, MaxStrLen(WebClientUrl));
        MyBusinessEventOnAddTable(ADLSETable.SystemId, ADLSETable."Table ID", ADLSETable.Enabled, Url, WebClientUrl);
    end;

    internal procedure OnDeleteTable(ADLSETable: Record "ADLSE Table")
    var
        ADLSESetup: Record "ADLSE Setup";
        Url: Text[250];
        WebClientUrl: Text[250];
        ADLSEFieldApiUrlTok: Label 'bc2adlsTeamMicrosoft/bc2adls/v1.0/companies(%1)/adlseTables(%2)', Locked = true;
    begin
        ADLSESetup.GetSingleton();
        Url := ADLSEExternalEventsHelper.CreateLink(ADLSEFieldApiUrlTok, ADLSETable.SystemId);
        WebClientUrl := CopyStr(GetUrl(ClientType::Web, CompanyName(), ObjectType::Page, Page::"ADLSE Setup", ADLSESetup), 1, MaxStrLen(WebClientUrl));
        MyBusinessEventOnDeleteTable(ADLSETable.SystemId, ADLSETable."Table ID", ADLSETable.Enabled, Url, WebClientUrl);
    end;

    internal procedure OnExportSchema(ADLSESetup: Record "ADLSE Setup")
    var
        Url: Text[250];
        WebClientUrl: Text[250];
        ADLSEFieldApiUrlTok: Label 'bc2adlsTeamMicrosoft/bc2adls/v1.0/companies(%1)/adlseSetup(%2)', Locked = true;
    begin
        Url := ADLSEExternalEventsHelper.CreateLink(ADLSEFieldApiUrlTok, ADLSESetup.SystemId);
        WebClientUrl := CopyStr(GetUrl(ClientType::Web, CompanyName(), ObjectType::Page, Page::"ADLSE Setup", ADLSESetup), 1, MaxStrLen(WebClientUrl));
        MyBusinessOnExportSchema(ADLSESetup.SystemId, ADLSESetup."Storage Type", Url, WebClientUrl);
    end;

    internal procedure OnClearSchemaExportedOn(ADLSESetup: Record "ADLSE Setup")
    var
        Url: Text[250];
        WebClientUrl: Text[250];
        ADLSEFieldApiUrlTok: Label 'bc2adlsTeamMicrosoft/bc2adls/v1.0/companies(%1)/adlseSetup(%2)', Locked = true;
    begin
        Url := ADLSEExternalEventsHelper.CreateLink(ADLSEFieldApiUrlTok, ADLSESetup.SystemId);
        WebClientUrl := CopyStr(GetUrl(ClientType::Web, CompanyName(), ObjectType::Page, Page::"ADLSE Setup", ADLSESetup), 1, MaxStrLen(WebClientUrl));
        MyBusinessOnClearSchemaExportedOn(ADLSESetup.SystemId, ADLSESetup."Storage Type", Url, WebClientUrl);
    end;

    internal procedure OnExport(ADLSESetup: Record "ADLSE Setup")
    var
        Url: Text[250];
        WebClientUrl: Text[250];
        ADLSEFieldApiUrlTok: Label 'bc2adlsTeamMicrosoft/bc2adls/v1.0/companies(%1)/adlseSetup(%2)', Locked = true;
    begin
        Url := ADLSEExternalEventsHelper.CreateLink(ADLSEFieldApiUrlTok, ADLSESetup.SystemId);
        WebClientUrl := CopyStr(GetUrl(ClientType::Web, CompanyName(), ObjectType::Page, Page::"ADLSE Setup", ADLSESetup), 1, MaxStrLen(WebClientUrl));
        MyBusinessOnExport(ADLSESetup.SystemId, ADLSESetup."Storage Type", Url, WebClientUrl);
    end;

    internal procedure OnExportFinished(ADLSESetup: Record "ADLSE Setup"; ADLSETable: Record "ADLSE Table")
    var
        Url: Text[250];
        WebClientUrl: Text[250];
        ADLSEFieldApiUrlTok: Label 'bc2adlsTeamMicrosoft/bc2adls/v1.0/companies(%1)/adlseTables(%2)', Locked = true;
    begin
        Url := ADLSEExternalEventsHelper.CreateLink(ADLSEFieldApiUrlTok, ADLSETable.SystemId);
        WebClientUrl := CopyStr(GetUrl(ClientType::Web, CompanyName(), ObjectType::Page, Page::"ADLSE Setup", ADLSESetup), 1, MaxStrLen(WebClientUrl));
        MyBusinessOnAllExportIsFinished(ADLSESetup.SystemId, ADLSESetup."Storage Type", Url, WebClientUrl);
    end;

    internal procedure OnAllExportIsFinished(ADLSESetup: Record "ADLSE Setup")
    var
        Url: Text[250];
        WebClientUrl: Text[250];
        ADLSEFieldApiUrlTok: Label 'bc2adlsTeamMicrosoft/bc2adls/v1.0/companies(%1)/adlseSetup(%2)', Locked = true;
    begin
        Url := ADLSEExternalEventsHelper.CreateLink(ADLSEFieldApiUrlTok, ADLSESetup.SystemId);
        WebClientUrl := CopyStr(GetUrl(ClientType::Web, CompanyName(), ObjectType::Page, Page::"ADLSE Setup", ADLSESetup), 1, MaxStrLen(WebClientUrl));
        MyBusinessOnAllExportIsFinished(ADLSESetup.SystemId, ADLSESetup."Storage Type", Url, WebClientUrl);
    end;

    internal procedure OnRefreshOptions(ADLSESetup: Record "ADLSE Setup")
    var
        Url: Text[250];
        WebClientUrl: Text[250];
        ADLSEFieldApiUrlTok: Label 'bc2adlsTeamMicrosoft/bc2adls/v1.0/companies(%1)/adlseSetup(%2)', Locked = true;
    begin
        Url := ADLSEExternalEventsHelper.CreateLink(ADLSEFieldApiUrlTok, ADLSESetup.SystemId);
        WebClientUrl := CopyStr(GetUrl(ClientType::Web, CompanyName(), ObjectType::Page, Page::"ADLSE Setup", ADLSESetup), 1, MaxStrLen(WebClientUrl));
        MyBusinessOnRefreshOptions(ADLSESetup.SystemId, ADLSESetup."Storage Type", Url, WebClientUrl);
    end;

    local procedure GetSetup()
    var
        ADLSESetup: Record "ADLSE Setup";
    begin
        if (StorageType <> '') and (Instance <> '') and (Resource <> '') then
            exit;

        ADLSESetup.GetSingleton();
        // TODO: Change to ADLSESetup."Storage Type" field and include a case-statement on release of Microsoft Fabric integration
        StorageType := 'Azure Data Lake';
        Instance := ADLSESetup."Account Name";
        Resource := ADLSESetup.Container;
    end;

    [ExternalBusinessEvent('ExportEntityEnded', 'Export entity ended', 'The export of the entity was registered as ended.', EventCategory::ADLSE)]
    local procedure ExportEntityEnded(RunId: Integer; Started: DateTime; Ended: DateTime; State: Enum "ADLSE Run State"; StorageType: Text[250]; Instance: Text[250]; Resource: Text[250]; Entity: Text[250])
    begin
    end;

    [Obsolete('Replaced with the ExportEntityEnded External Business Event', '1.5.0.0')]
    [ExternalBusinessEvent('ExportOfEntityEnded', '[OBSOLETE] Entity export ended', '[OBSOLETE] The export of the entity was registered as ended.', EventCategory::ADLSE)]
    local procedure TableExportRunEnded(RunId: Integer; State: Enum "ADLSE Run State"; Container: Text[250]; EntityName: Text[250])
    begin
    end;

    [ExternalBusinessEvent('EnableFieldChanged', 'Field enabled changed', 'The field enabled is changed on the field table', EventCategory::ADLSE)]
    local procedure MyBusinessEventEnableFieldChanged(SystemId: Guid; TableId: Integer; FieldId: Integer; Enabled: Boolean; Url: Text[250]; WebClientUrl: Text[250])
    begin
    end;

    [ExternalBusinessEvent('EnableTableChanged', 'Table enabled changed', 'The table enabled is changed on the table', EventCategory::ADLSE)]
    local procedure MyBusinessEventEnableTableChanged(SystemId: Guid; TableId: Integer; Enabled: Boolean; Url: Text[250]; WebClientUrl: Text[250])
    begin
    end;

    [ExternalBusinessEvent('OnAfterResetSelected', 'On After Reset is activated', 'When the reset action is done.', EventCategory::ADLSE)]
    local procedure MyBusinessEventOnAfterResetSelected(SystemId: Guid; TableId: Integer)
    begin
    end;

    [ExternalBusinessEvent('OnAddTable', 'On adding table', 'When an table is added in the setup', EventCategory::ADLSE)]
    local procedure MyBusinessEventOnAddTable(SystemId: Guid; TableId: Integer; Enabled: Boolean; Url: Text[250]; WebClientUrl: Text[250])
    begin
    end;

    [ExternalBusinessEvent('OnDeleteTable', 'On deleting table', 'When an table is deleted in the setup', EventCategory::ADLSE)]
    local procedure MyBusinessEventOnDeleteTable(SystemId: Guid; TableId: Integer; Enabled: Boolean; Url: Text[250]; WebClientUrl: Text[250])
    begin
    end;

    [ExternalBusinessEvent('OnExportSchema', 'Export schema', 'When the schema is exported', EventCategory::ADLSE)]
    local procedure MyBusinessOnExportSchema(SystemId: Guid; "Storage Type": Enum "ADLSE Storage Type"; Url: Text[250]; WebClientUrl: Text[250])
    begin
    end;

    [ExternalBusinessEvent('OnClearSchemaExportedOn', 'Clear schema exported on', 'When the field schema exported on is cleared', EventCategory::ADLSE)]
    local procedure MyBusinessOnClearSchemaExportedOn(SystemId: Guid; "Storage Type": Enum "ADLSE Storage Type"; Url: Text[250]; WebClientUrl: Text[250])
    begin
    end;

    [ExternalBusinessEvent('OnExport', 'Export data', 'When the data is exported', EventCategory::ADLSE)]
    local procedure MyBusinessOnExport(SystemId: Guid; "Storage Type": Enum "ADLSE Storage Type"; Url: Text[250]; WebClientUrl: Text[250])
    begin
    end;

    [ExternalBusinessEvent('OnAllExportIsFinished', 'Export is finished of all tables', 'When the export is finished of all tables', EventCategory::ADLSE)]
    local procedure MyBusinessOnAllExportIsFinished(SystemId: Guid; "Storage Type": Enum "ADLSE Storage Type"; Url: Text[250]; WebClientUrl: Text[250])
    begin
    end;

    [ExternalBusinessEvent('OnRefreshOptions', 'Refresh Options', 'When the options are refreshed', EventCategory::ADLSE)]
    local procedure MyBusinessOnRefreshOptions(SystemId: Guid; "Storage Type": Enum "ADLSE Storage Type"; Url: Text[250]; WebClientUrl: Text[250])
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"ADLSE Table", OnAfterResetSelected, '', true, true)]
    local procedure OnAfterResetSelected(ADLSETable: Record "ADLSE Table")
    begin
        MyBusinessEventOnAfterResetSelected(ADLSETable.SystemId, ADLSETable."Table ID");
    end;
}