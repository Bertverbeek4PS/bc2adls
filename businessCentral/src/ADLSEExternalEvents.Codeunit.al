// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
codeunit 82574 "ADLSE External Events"
{
    Access = Internal;
    SingleInstance = true;

    var
        StorageType, Instance, Resource : Text[250];

    procedure OnTableExportRunEnded(RunId: Integer; Started: DateTime; Ended: DateTime; TableId: Integer; State: Enum "ADLSE Run State")
    var
        ADLSEUtil: Codeunit "ADLSE Util";
    begin
        GetSetup();

        ExportEntityEnded(RunId, Started, Ended, State, StorageType, Instance, Resource, CopyStr(ADLSEUtil.GetDataLakeCompliantTableName(TableId), 1, 250));
#pragma warning disable AL0432
        TableExportRunEnded(RunId, State, Instance, CopyStr(ADLSEUtil.GetDataLakeCompliantTableName(TableId), 1, 250));
#pragma warning restore AL0432
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
}