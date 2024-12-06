// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
page 82578 "ADLSE Deleted Record API"
{
    PageType = API;
    APIPublisher = 'bc2adlsTeamMicrosoft';
    APIGroup = 'bc2adls';
    APIVersion = 'v1.0', 'v1.1';
    EntityName = 'adlseDeletedRecord';
    EntitySetName = 'adlseDeletedRecords';
    SourceTable = "ADLSE Deleted Record";
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = true;
    ODataKeyFields = "System ID";

    layout
    {
        area(Content)
        {
            field(id; Rec."System ID")
            {
            }
            field(tableId; Rec."Table ID")
            {
            }
            field(systemId; Rec."System ID")
            {
            }
            field(deletionTimeStamp; Rec."Deletion Timestamp")
            {
            }
            field(lastModifiedDateTime; Rec.SystemModifiedAt)
            {
                Editable = false;
            }
        }
    }    
}