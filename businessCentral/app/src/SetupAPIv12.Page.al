// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
page 97001 "ADLSE Setup API v12"
{
    PageType = API;
    APIPublisher = 'bc2adlsTeamMicrosoft';
    APIGroup = 'bc2adls';
    APIVersion = 'v1.2';
    EntityName = 'adlseSetup';
    EntitySetName = 'adlseSetup';
    SourceTable = "ADLSE Setup";
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = true;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(primaryKey; Rec."Primary Key")
                {
                    Editable = false;
                }
                field(container; Rec.Container) { }
                field(emitTelemetry; Rec."Emit telemetry") { }
                field(dataFormat; Rec.DataFormat) { }
                field(maxPayloadSizeMiB; Rec.MaxPayloadSizeMiB) { }
                field(multiCompanyExport; Rec."Schema Exported On")
                {
                    Editable = false;
                }
                field(skipTimestampSorting; Rec."Skip Timestamp Sorting On Recs") { }
                field(exportEnumasInteger; Rec."Export Enum as Integer") { }
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
    procedure StartExport(var ActionContext: WebServiceActionContext)
    var
        ADLSEExecution: Codeunit "ADLSE Execution";
    begin
        ADLSEExecution.StartExport();
        SetActionResponse(ActionContext, Rec."SystemId");
    end;

    [ServiceEnabled]
    procedure StopExport(var ActionContext: WebServiceActionContext)
    var
        ADLSEExecution: Codeunit "ADLSE Execution";
    begin
        ADLSEExecution.StopExport();
        SetActionResponse(ActionContext, Rec."SystemId");
    end;

    [ServiceEnabled]
    procedure SchemaExport(var ActionContext: WebServiceActionContext)
    var
        ADLSEExecution: Codeunit "ADLSE Execution";
    begin
        ADLSEExecution.SchemaExport();
        SetActionResponse(ActionContext, Rec."SystemId");
    end;

    [ServiceEnabled]
    procedure ClearSchemaExportedOn(var ActionContext: WebServiceActionContext)
    var
        ADLSEExecution: Codeunit "ADLSE Execution";
    begin
        ADLSEExecution.ClearSchemaExportedOn();
        SetActionResponse(ActionContext, Rec."SystemId");
    end;

    [ServiceEnabled]
    procedure RefreshOptions(var ActionContext: WebServiceActionContext)
    var
        ADLSEEnumTranslation: Record "ADLSE Enum Translation";
    begin
        ADLSEEnumTranslation.RefreshOptions();
        SetActionResponse(ActionContext, Rec."SystemId");
    end;

    local procedure SetActionResponse(var ActionContext: WebServiceActionContext; AdlsId: Guid)
    var
    begin
        SetActionResponse(ActionContext, Page::"ADLSE Setup API v12", AdlsId);
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