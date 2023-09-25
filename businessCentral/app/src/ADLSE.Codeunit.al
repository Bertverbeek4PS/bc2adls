// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
codeunit 82567 ADLSE
{
    /// <summary>
    /// This is the main facade of Azure Data Lake Storage Export (ADLSE).
    /// </summary>

    Access = Public;

    /// <summary>
    /// This is the event which represents a successful export of a batch of 
    /// records for a single table to the data lake.
    /// </summary>
    /// <param name="TableID">
    /// The table number whose data was exported.
    /// </param>
    /// <param name="LastTimeStampExported">
    /// The value for the TimeStamp field for the last record that was synced.
    /// </param>
    [IntegrationEvent(false, false)]
    internal procedure OnTableExported(TableID: Integer; LastTimeStampExported: BigInteger)
    begin
    end;
}