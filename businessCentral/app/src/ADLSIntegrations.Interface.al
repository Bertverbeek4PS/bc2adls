interface "ADLS Integrations"
{
    /// <summary>
    /// Get the base url of the external system
    /// </summary>
    procedure GetBaseUrl(): Text

    /// <summary>
    /// Checks if the setup of bc2adls is all correct
    /// </summary>
    procedure CheckSetup();

    /// <summary>
    /// Create a block blob in the external system
    /// </summary>
    procedure CreateBlockBlob(BlobPath: Text; ADLSECredentials: Codeunit "ADLSE Credentials"; LeaseID: Text; Body: Text; IsJson: Boolean)

    /// <summary>
    /// Resets the table inside the external system
    /// </summary>
    procedure ResetTableExport(ltableId: Integer);

    procedure Init(TableIDValue: Integer; FieldIdListValue: List of [Integer]; LastFlushedTimeStampValue: BigInteger; EmitTelemetryValue: Boolean)

    procedure CheckEntity(CdmDataFormat: Enum "ADLSE CDM Format"; var EntityJsonNeedsUpdate: Boolean; var ManifestJsonsNeedsUpdate: Boolean; SchemaUpdate: Boolean)

    procedure CreateEntityContent()
    procedure TryCollectAndSendRecord(RecordRef: RecordRef; RecordTimeStamp: BigInteger; var LastTimestampExported: BigInteger)
    procedure TryFinish(var LastTimestampExported: BigInteger)
    procedure UpdateCdmJsons(EntityJsonNeedsUpdate: Boolean; ManifestJsonsNeedsUpdate: Boolean)
}