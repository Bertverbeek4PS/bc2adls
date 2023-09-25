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
    ObsoleteState = Pending;
    ObsoleteReason = 'With the InherentPermissions attribute set on the method this permissionset has become obsolete.';
    ObsoleteTag = 'v1.5.0.0';

    Permissions = tabledata "ADLSE Deleted Record" = I,
                      table "ADLSE Table Last Timestamp" = X,
                  tabledata "ADLSE Table Last Timestamp" = R;
}