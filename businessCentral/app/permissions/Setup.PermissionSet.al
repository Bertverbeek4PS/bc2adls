// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
permissionset 82560 "ADLSE - Setup"
{
    /// <summary>
    /// The permission set to be used when administering the Azure Data Lake Storage export tool.
    /// </summary>
    Access = Public;
    Assignable = true;
    Caption = 'Azure Data Lake Storage - Setup';

    Permissions = tabledata "ADLSE Setup" = RIMD,
                  tabledata "ADLSE Table" = RIMD,
                  tabledata "ADLSE Field" = RIMD,
                  tabledata "ADLSE Deleted Record" = RD,
                  tabledata "ADLSE Current Session" = R,
                  tabledata "ADLSE Table Last Timestamp" = RID,
                  tabledata "ADLSE Run" = RD;
}