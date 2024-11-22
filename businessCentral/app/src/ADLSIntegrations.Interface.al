interface "ADLS Integrations"
{
    /// <summary>
    /// Get the base url of the integration
    /// </summary>
    procedure GetBaseUrl(): Text

    /// <summary>
    /// Resets the table inside the external system
    /// </summary>
    procedure ResetTableExport(ltableId: Integer);
}