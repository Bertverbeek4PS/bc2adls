tableextension 82560 "FL Setup Ext" extends "ADLSE Setup"
{
    fields
    {
        field(82560; Workspace; Text[100])
        {
            Caption = 'Workspace';
            ToolTip = 'Specifies the name of the Workspace where the data is going to be uploaded. This can be a name or a GUID.';
            trigger OnValidate()
            var
                ValidGuid: Guid;
            begin
                if not Evaluate(ValidGuid, Rec.Workspace) then
                    if (StrLen(Rec.Workspace) < 3) or (StrLen(Rec.Workspace) > 24)
                        or TextCharactersOtherThan(Rec.Workspace, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_')
                    then
                        Error(WorkspaceIncorrectFormatErr);
            end;
        }
        field(82561; Lakehouse; Text[100])
        {
            Caption = 'Lakehouse';
            ToolTip = 'Specifies the name of the Lakehouse where the data is going to be uploaded. This can be a name or a GUID.';
            trigger OnValidate()
            var
                ValidGuid: Guid;
            begin
                if not Evaluate(ValidGuid, Rec.Lakehouse) then
                    if (StrLen(Rec.Lakehouse) < 3) or (StrLen(Rec.Lakehouse) > 24)
                        or TextCharactersOtherThan(Rec.Lakehouse, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_')
                    then
                        Error(LakehouseIncorrectFormatErr);
            end;
        }
    }

    var
        WorkspaceIncorrectFormatErr: Label 'The workspace is in an incorrect format. Please only use abcdefghijklmnopqrstuvwxyz1234567890_ or a valid GUID';
        LakehouseIncorrectFormatErr: Label 'The lakehouse is in an incorrect format. Please only use abcdefghijklmnopqrstuvwxyz1234567890_ or a valid GUID';

    local procedure TextCharactersOtherThan(String: Text; CharString: Text): Boolean
    var
        Index: Integer;
        Letter: Text;
    begin
        for Index := 1 to StrLen(String) do begin
            Letter := CopyStr(String, Index, 1);
            if StrPos(CharString, Letter) = 0 then
                exit(true);
        end;
    end;
}