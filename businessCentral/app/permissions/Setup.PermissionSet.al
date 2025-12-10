// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
namespace bc2adls;

permissionset 11344439 "ADLSE - Setup"
{
    /// <summary>
    /// The permission set to be used when administering the Azure Data Lake Storage export tool.
    /// </summary>
    Access = Public;
    Assignable = true;
    Caption = 'ADLS - Setup', MaxLength = 30;

    Permissions = table "ADLSE Deleted Table Filter" = x,
                  table "ADLSE Export Category Table" = x,
                  table "ADLSE Setup" = x,
                  table "ADLSE Table Last Timestamp" = x,
                  tabledata "ADLSE Setup" = RIMD,
                  tabledata "ADLSE Table" = RIMD,
                  tabledata "ADLSE Field" = RIMD,
                  tabledata "ADLSE Deleted Record" = RD,
                  tabledata "ADLSE Current Session" = R,
                  tabledata "ADLSE Table Last Timestamp" = RID,
                  tabledata "ADLSE Run" = RD,
                  tabledata "ADLSE Enum Translation" = RIMD,
                  tabledata "ADLSE Enum Translation Lang" = RIMD,
                  tabledata "ADLSE Deleted Table Filter" = RIMD,
                  tabledata "ADLSE Export Category Table" = RIMD,
                  codeunit "ADLSE Clear Tracked Deletions" = X,
                  codeunit "ADLSE Credentials" = X,
                  codeunit "ADLSE Setup" = X,
                  codeunit "ADLSE Installer" = X,
                  page "ADLSE Setup Tables" = X,
                  page "ADLSE Setup Fields" = X,
                  page "ADLSE Setup" = X,
                  page "ADLSE Run" = X,
                  page "ADLSE Enum Translations" = X,
                  page "ADLSE Enum Translations Lang" = X,
                  page "ADLSE Export Categories" = X,
                  page "ADLSE Assign Export Category" = X,
                  page "ADLSE Deleted Table Filter" = X,
                  report "ADLSE Schedule Task Assignment" = X,
                  xmlport "ADLSE BC2ADLS Import" = X;
}