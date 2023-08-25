// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
codeunit 82574 "ADLSE External Events"
{
    internal procedure OnTableExportRunEnded(RunId: Integer; TableId: Integer; State: Enum "ADLSE Run State")
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSEUtil: Codeunit "ADLSE Util";
    begin
        ADLSESetup.GetSingleton();
        TableExportRunEnded(RunId, State, ADLSESetup.Container, CopyStr(ADLSEUtil.GetDataLakeCompliantTableName(TableId), 1, 250));
    end;

    [ExternalBusinessEvent('ExportOfEntityEnded', 'Entity export ended', 'The export of the entity was registered as ended.', EventCategory::ADLSE)]
    local procedure TableExportRunEnded(RunId: Integer; State: Enum "ADLSE Run State"; ContainerName: Text[250]; EntityName: Text[250])
    begin
    end;
}