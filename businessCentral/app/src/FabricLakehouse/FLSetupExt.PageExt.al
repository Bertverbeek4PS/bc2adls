pageextension 82561 "FL Setup Ext" extends "ADLSE Setup"
{
    layout
    {
        addafter("Tenant ID")
        {
            group(MSFabric)
            {
                Caption = 'Microsoft Fabric';
                Editable = MSFabric;
                field(Workspace; Rec.Workspace)
                {
                    ApplicationArea = All;
                }
                field(Lakehouse; Rec.Lakehouse)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    var
        MSFabric: Boolean;

    trigger OnAfterGetRecord()
    begin
        MSFabric := Rec."Storage Type" = Rec."Storage Type"::"Microsoft Fabric";
    end;
}