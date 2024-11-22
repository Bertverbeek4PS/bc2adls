tableextension 82561 "Azure Setup Ext" extends "ADLSE Setup"
{
    fields
    {
        field(82570; "Account Name"; Text[24])
        {
            Caption = 'Account Name';
            ToolTip = 'Specifies the name of the storage account.';

            trigger OnValidate()
            begin
                // Name constraints based on https://learn.microsoft.com/en-us/azure/storage/common/storage-account-overview#storage-account-name
                if (StrLen(Rec."Account Name") < 3) or (StrLen(Rec."Account Name") > 24) // between 3 and 24 characters long
                    or TextCharactersOtherThan(Rec."Account Name", 'abcdefghijklmnopqrstuvwxyz1234567890') // only made of lower case letters and numerals
                then
                    Error(AccountNameIncorrectFormatErr);
            end;
        }

        field(82571; Container; Text[63])
        {
            Caption = 'Container';
            ToolTip = 'Specifies the name of the container where the data is going to be uploaded. Please refer to constraints on container names at https://docs.microsoft.com/en-us/rest/api/storageservices/naming-and-referencing-containers--blobs--and-metadata.';

            trigger OnValidate()
            begin
                // Name constraints based on https://docs.microsoft.com/en-us/rest/api/storageservices/naming-and-referencing-containers--blobs--and-metadata
                if (StrLen(Container) < 3) or (StrLen(Container) > 63) // between 6 and 63 characters long
                    or TextCharactersOtherThan(Container, 'abcdefghijklmnopqrstuvwxyz1234567890-') // only made of lower case letters, numerals and dashes
                    or (StrPos(Container, '--') <> 0) // no occurence of multiple dashes together
                then
                    Error(ContainerNameIncorrectFormatErr);
            end;
        }

    }

    var
        ContainerNameIncorrectFormatErr: Label 'The container name is in an incorrect format. Please only use abcdefghijklmnopqrstuvwxyz1234567890_';
        AccountNameIncorrectFormatErr: Label 'The account name is in an incorrect format. Please only use abcdefghijklmnopqrstuvwxyz1234567890';

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