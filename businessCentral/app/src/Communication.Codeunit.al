// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
codeunit 82562 "ADLSE Communication"
{
    Access = Internal;

    var
        ADLSE: Codeunit "ADLSE";
        AdlsIntegrations: Interface "ADLS Integrations";

    procedure Init(TableIDValue: Integer; FieldIdListValue: List of [Integer]; LastFlushedTimeStampValue: BigInteger; EmitTelemetryValue: Boolean)
    var
    begin
        ADLSE.selectbc2adlsIntegrations(AdlsIntegrations);
        AdlsIntegrations.Init(TableIDValue, FieldIdListValue, LastFlushedTimeStampValue, EmitTelemetryValue);
    end;

    procedure CheckEntity(CdmDataFormat: Enum "ADLSE CDM Format"; var EntityJsonNeedsUpdate: Boolean; var ManifestJsonsNeedsUpdate: Boolean; SchemaUpdate: Boolean)
    begin
        AdlsIntegrations.CheckEntity(CdmDataFormat, EntityJsonNeedsUpdate, ManifestJsonsNeedsUpdate, SchemaUpdate);
    end;

    procedure CreateEntityContent()
    begin
        AdlsIntegrations.CreateEntityContent();
    end;

    [TryFunction]
    procedure TryCollectAndSendRecord(RecordRef: RecordRef; RecordTimeStamp: BigInteger; var LastTimestampExported: BigInteger)
    begin
        AdlsIntegrations.TryCollectAndSendRecord(RecordRef, RecordTimeStamp, LastTimestampExported);
    end;

    [TryFunction]
    procedure TryFinish(var LastTimestampExported: BigInteger)
    begin
        AdlsIntegrations.TryFinish(LastTimestampExported);
    end;

    procedure UpdateCdmJsons(EntityJsonNeedsUpdate: Boolean; ManifestJsonsNeedsUpdate: Boolean)
    begin
        AdlsIntegrations.UpdateCdmJsons(EntityJsonNeedsUpdate, ManifestJsonsNeedsUpdate);
    end;
}
