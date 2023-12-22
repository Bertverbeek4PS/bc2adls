// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
page 82568 "ADLSE Setup API v11"
{
    PageType = API;
    APIPublisher = 'bc2adlsTeamMicrosoft';
    APIGroup = 'bc2adls';
    APIVersion = 'v1.1';
    EntityName = 'adlseSetup';
    EntitySetName = 'adlseSetup';
    SourceTable = "ADLSE Setup";
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
                field(primaryKey; Rec."Primary Key") { }
                field(container; Rec.Container) { }
                field(emitTelemetry; Rec."Emit telemetry") { }
                field(dataFormat; Rec.DataFormat) { }
                field(maxPayloadSizeMiB; Rec.MaxPayloadSizeMiB) { }
                field(multiCompanyExport; Rec."Schema Exported On")
                {
                    Editable = false;
                }
                field(exportEnumasInteger; Rec."Export Enum as Integer") { }
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

    local procedure SetActionResponse(var ActionContext: WebServiceActionContext; AdlsId: Guid)
    var
    begin
        SetActionResponse(ActionContext, Page::"ADLSE Setup API v11", AdlsId);
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