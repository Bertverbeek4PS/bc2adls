// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
permissionset 82561 "ADLSE - Execute"
{
    /// <summary>
    /// The permission set to be used when running the Azure Data Lake Storage export tool.
    /// </summary>
    Access = Public;
    Assignable = true;
    Caption = 'Azure Data Lake Storage - Execute';

    Permissions = tabledata "ADLSE Setup" = RM,
                  tabledata "ADLSE Table" = RM,
                  tabledata "ADLSE Field" = R,
                  tabledata "ADLSE Deleted Record" = R,
                  tabledata "ADLSE Current Session" = RIMD,
                  tabledata "ADLSE Table Last Timestamp" = RIMD,
                  tabledata "ADLSE Run" = RIMD;
}