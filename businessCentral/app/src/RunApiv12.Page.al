// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
page 82574 "ADLSE Run API v12"
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

    [ServiceEnabled]
    procedure PutOnFailed(var ActionContext: WebServiceActionContext)
    var
        SelectedADLSERun: Record "ADLSE Run";
    begin
        CurrPage.SetSelectionFilter(SelectedADLSERun);
        if SelectedADLSERun.FindSet(true) then
            repeat
                SelectedADLSERun.PutOnFailed(SelectedADLSERun);
            until SelectedADLSERun.Next() = 0;
        SetActionResponse(ActionContext, Rec.SystemId);
    end;

    local procedure SetActionResponse(var ActionContext: WebServiceActionContext; AdlsId: Guid)
    var
    begin
        SetActionResponse(ActionContext, Page::"ADLSE Run API v12", AdlsId);
    end;

    local procedure SetActionResponse(var ActionContext: WebServiceActionContext; PageId: Integer; DocumentId: Guid)
    var
    begin
        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(PageId);
        ActionContext.AddEntityKey(Rec.FieldNo(SystemId), DocumentId);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}