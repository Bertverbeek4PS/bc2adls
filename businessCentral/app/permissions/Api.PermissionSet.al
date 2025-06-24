// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
permissionset 82563 "ADLSE - API"
{
    /// <summary>
    /// The permission set to be used when using the API.
    /// </summary>
    Access = Public;
    Assignable = true;
    Caption = 'ADLS - Api', MaxLength = 30;

    Permissions = table "ADLSE Setup" = x,
                  tabledata "ADLSE Table" = RMI,
                  tabledata "ADLSE Setup" = R,
                  tabledata "ADLSE Current Session" = R,
                  tabledata "ADLSE Run" = R,
                  tabledata "ADLSE Field" = RI,
                  page "ADLSE Table API v12" = X,
                  page "ADLSE Setup API v12" = X,
                  page "ADLSE Field API v12" = X,
                  page "ADLSE CurrentSession API" = X,
                  page "ADLSE Run API v12" = X,
                  codeunit "ADLSE External Events Helper" = X,
                  codeunit "ADLSE External Events" = X;
}