// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
page 97000 "ADLSE CurrentSession API"
{
    PageType = API;
    APIPublisher = 'bc2adlsTeamMicrosoft';
    APIGroup = 'bc2adls';
    APIVersion = 'v1.1', 'v1.2';
    EntityName = 'adlseCurrentSession';
    EntitySetName = 'adlseCurrentSessions';
    SourceTable = "ADLSE Current Session";
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(tableId; Rec."Table ID") { }
                field(sessionId; Rec."Session ID") { }
                field(companyName; Rec."Company Name") { }
                field(sessionUniqueId; Rec."Session Unique ID") { }
                field(id; Rec.SystemId)
                {
                    Editable = false;
                }
#pragma warning disable LC0016
                field(systemRowVersion; Rec.SystemRowVersion)
                {
                    Editable = false;
                }
#pragma warning restore
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Editable = false;
                }
            }
        }
    }
}