// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
permissionset 82562 "ADLSE - Track Delete"
{
    /// <summary>
    /// The permission set used to register the deletion of any record, so that the information of it being deleted can be conveyed to the Azure data lake.
    /// </summary>
    Access = Public;
    Assignable = true;
    Caption = 'Azure Data Lake Storage - Track Delete';

    Permissions = tabledata "ADLSE Deleted Record" = I,
                      table "ADLSE Table Last Timestamp" = X,
                  tabledata "ADLSE Table Last Timestamp" = R;
}