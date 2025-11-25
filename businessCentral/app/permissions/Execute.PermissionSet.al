// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
permissionset 82561 "ADLSE - Execute"
{
    /// <summary>
    /// The permission set to be used when running the Azure Data Lake Storage export tool.
    /// </summary>
    Access = Public;
    Assignable = true;
    Caption = 'ADLS - Execute', MaxLength = 30;

    Permissions = table "ADLSE Setup" = x,
                  tabledata "ADLSE Setup" = RM,
                  tabledata "ADLSE Table" = RM,
                  tabledata "ADLSE Field" = R,
                  tabledata "ADLSE Deleted Record" = R,
                  tabledata "ADLSE Current Session" = RIMD,
                  tabledata "ADLSE Table Last Timestamp" = RIMD,
                  tabledata "ADLSE Run" = RIMD,
                  tabledata "ADLSE Enum Translation" = RIMD,
                  tabledata "ADLSE Enum Translation Lang" = RIMD,
                  tabledata "Deleted Tables Not to Sync" = R,
#pragma warning disable AL0432
                  tabledata "ADLSE Export Category" = R,
#pragma warning restore AL0432
                  tabledata "ADLSE Export Category Table" = R,
#if not CLEAN27
                  tabledata "Session Instruction" = RIMD,
#endif
                  codeunit "ADLSE UpgradeTagNewCompanySubs" = X,
                  codeunit "ADLSE Upgrade" = X,
                  codeunit "ADLSE Util" = X,
                  codeunit ADLSE = X,
                  codeunit "ADLSE CDM Util" = X,
                  codeunit "ADLSE Communication" = X,
                  codeunit "ADLSE Session Manager" = X,
                  codeunit "ADLSE Http" = X,
                  codeunit "ADLSE Gen 2 Util" = X,
                  codeunit "ADLSE Execute" = X,
                  codeunit "ADLSE Execution" = X,
                  codeunit "ADLSE Wrapper Execute" = X,
                  report "ADLSE Seek Data" = X,
                  xmlport "BC2ADLS Export" = X;
}