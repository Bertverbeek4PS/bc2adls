// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
page 82566 "ADLSE Run API"
{
    PageType = API;
    APIPublisher = 'bc2adlsTeamMicrosoft';
    APIGroup = 'bc2adls';
    APIVersion = 'v1.0', 'v1.1';
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
                field(id; Rec.ID) { }
                field(tableId; Rec."Table ID") { }
                field(companyName; Rec."Company Name") { }
                field(state; Rec.State) { }
                field("error"; Rec.Error) { }
                field(started; Rec.Started) { }
                field(ended; Rec.Ended) { }
                field(systemId; Rec.SystemId)
                {
                    Editable = false;
                }
                field(systemRowVersion; Rec.SystemRowVersion)
                {
                    Editable = false;
                }
            }
        }
    }
}