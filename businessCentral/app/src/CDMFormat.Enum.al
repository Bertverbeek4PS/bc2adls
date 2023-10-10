// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.

/// <summary>
/// The formats in which data is stored on the data lake
/// </summary>
enum 82562 "ADLSE CDM Format"
{
    Access = Internal;
    Extensible = false;

    value(0; Csv)
    {
        Caption = 'CSV';
    }

    value(1; Parquet)
    {
        Caption = 'Parquet';
    }
}