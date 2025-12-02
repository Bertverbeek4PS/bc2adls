// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
page 97003 "ADLSE Run API v12"
{
    PageType = API;
    APIPublisher = 'bc2adlsTeamMicrosoft';
    APIGroup = 'bc2adls';
    APIVersion = 'v1.2';
    EntityName = 'adlseRun';
    EntitySetName = 'adlseRun';
    SourceTable = "ADLSE Run";
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
                field(no; Rec.ID) { }
                field(tableId; Rec."Table ID") { }
                field(companyName; Rec."Company Name") { }
                field(state; Rec.State) { }
                field("error"; Rec.Error) { }
                field(started; Rec.Started) { }
                field(ended; Rec.Ended) { }
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