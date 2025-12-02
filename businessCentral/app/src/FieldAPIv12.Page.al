// Create an API page for table and field

page 97002 "ADLSE Field API v12"
{
    PageType = API;
    APIPublisher = 'bc2adlsTeamMicrosoft';
    APIGroup = 'bc2adls';
    APIVersion = 'v1.2';
    EntityName = 'adlseField';
    EntitySetName = 'adlseFields';
    SourceTable = "ADLSE Field";
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
                field(fieldId; Rec."Field ID") { }
                field(enabled; Rec.Enabled) { }
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
    procedure Disable(var ActionContext: WebServiceActionContext)
    var
        SelectedADLSEField: Record "ADLSE Field";
    begin
        CurrPage.SetSelectionFilter(SelectedADLSEField);
        if SelectedADLSEField.FindSet(true) then
            repeat
                SelectedADLSEField.Validate(Enabled, false);
                SelectedADLSEField.Modify(true);
            until SelectedADLSEField.Next() = 0;
        SetActionResponse(ActionContext, Rec.SystemId);
    end;

    [ServiceEnabled]
    procedure Enable(var ActionContext: WebServiceActionContext)
    var
        SelectedADLSEField: Record "ADLSE Field";
    begin
        CurrPage.SetSelectionFilter(SelectedADLSEField);
        if SelectedADLSEField.FindSet(true) then
            repeat
                SelectedADLSEField.Validate(Enabled, true);
                SelectedADLSEField.Modify(true);
            until SelectedADLSEField.Next() = 0;
        SetActionResponse(ActionContext, Rec.SystemId);
    end;


    local procedure SetActionResponse(var ActionContext: WebServiceActionContext; AdlsId: Guid)
    var
    begin
        SetActionResponse(ActionContext, Page::"ADLSE Field API v12", AdlsId);
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