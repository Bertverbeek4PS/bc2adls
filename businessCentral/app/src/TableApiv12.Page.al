// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
page 97004 "ADLSE Table API v12"
{
    PageType = API;
    APIPublisher = 'bc2adlsTeamMicrosoft';
    APIGroup = 'bc2adls';
    APIVersion = 'v1.2';
    EntityName = 'adlseTable';
    EntitySetName = 'adlseTables';
    SourceTable = "ADLSE Table";
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    DelayedInsert = true;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(tableId; Rec."Table ID") { }
                field(enabled; Rec.Enabled)
                {
                    Editable = false;
                }
                field(initialLoadStartDate; Rec."Initial Load Start Date")
                {
                }
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
            part(adlseField; "ADLSE Field API v12")
            {
                EntityName = 'adlseField';
                EntitySetName = 'adlseFields';
                SubPageLink = "Table ID" = field("Table ID");
            }
        }
    }

    [ServiceEnabled]
    procedure Reset(var ActionContext: WebServiceActionContext)
    var
        SelectedADLSETable: Record "ADLSE Table";
    begin
        CurrPage.SetSelectionFilter(SelectedADLSETable);
        SelectedADLSETable.ResetSelected();
        SetActionResponse(ActionContext, Rec.SystemId);
    end;

    [ServiceEnabled]
    procedure Enable(var ActionContext: WebServiceActionContext)
    var
        SelectedADLSETable: Record "ADLSE Table";
    begin
        CurrPage.SetSelectionFilter(SelectedADLSETable);
        if SelectedADLSETable.FindSet(true) then
            repeat
                SelectedADLSETable.Validate(Enabled, true);
                SelectedADLSETable.Modify(true);
            until SelectedADLSETable.Next() = 0;
        SetActionResponse(ActionContext, Rec.SystemId);
    end;

    [ServiceEnabled]
    procedure Disable(var ActionContext: WebServiceActionContext)
    var
        SelectedADLSETable: Record "ADLSE Table";
    begin
        CurrPage.SetSelectionFilter(SelectedADLSETable);
        if SelectedADLSETable.FindSet(true) then
            repeat
                SelectedADLSETable.Validate(Enabled, false);
                SelectedADLSETable.Modify(true);
            until SelectedADLSETable.Next() = 0;
        SetActionResponse(ActionContext, Rec.SystemId);
    end;

    [ServiceEnabled]
    procedure AddAllFields(var ActionContext: WebServiceActionContext)
    begin
        Rec.AddAllFields();
        SetActionResponse(ActionContext, Rec.SystemId);
    end;

    [ServiceEnabled]
    procedure Delete(var ActionContext: WebServiceActionContext)
    begin
        Rec.Delete(true);
        SetActionResponse(ActionContext, Rec.SystemId);
    end;

    local procedure SetActionResponse(var ActionContext: WebServiceActionContext; AdlsId: Guid)
    var
    begin
        SetActionResponse(ActionContext, Page::"ADLSE Table API v12", AdlsId);
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