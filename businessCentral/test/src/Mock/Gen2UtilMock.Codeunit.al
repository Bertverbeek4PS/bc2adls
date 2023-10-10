codeunit 85567 "ADLSE Gen 2 Util Mock"
{
    EventSubscriberInstance = Manual;

    var
        _blobExists: Boolean;
        _contents: Dictionary of [Text, Text];
        _body: Text;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ADLSE Gen 2 Util", OnBeforeGetBlobContent, '', false, false)]
    local procedure OnBeforeGetBlobContentOnGen2Util(BlobPath: Text; ADLSECredentials: Codeunit "ADLSE Credentials"; var BlobExists: Boolean; var Content: JsonObject; var IsHandled: Boolean)
    var
        StringifiedJson: Text;
    begin
        BlobExists := _blobExists;
        if _contents.ContainsKey(BlobPath) then begin
            _contents.Get(BlobPath, StringifiedJson);
            Content.ReadFrom(StringifiedJson);
        end;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ADLSE Gen 2 Util", OnBeforeCreateBlockBlob, '', false, false)]
    local procedure OnBeforeCreateBlockBlobOnGen2Util(var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ADLSE Gen 2 Util", OnBeforeGetBlobContentLength, '', false, false)]
    local procedure OnBeforeGetBlobContentLengthOnGen2Util(var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ADLSE Gen 2 Util", OnBeforeAddBlockToDataBlob, '', false, false)]
    local procedure OnBeforeAddBlockToDataBlobOnGen2Util(Body: Text; var IsHandled: Boolean)
    begin
        _body := Body;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ADLSE Gen 2 Util", OnBeforeCommitAllBlocksOnDataBlob, '', false, false)]
    local procedure OnBeforeCommitAllBlocksOnDataBlobOnGen2Util(var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;

    procedure GetBlobExists(): Boolean
    begin
        exit(_blobExists);
    end;

    procedure SetBlobExists(BlobExists: Boolean)
    begin
        _blobExists := BlobExists;
    end;

    procedure AddContent(BlobPath: Text; StringifiedJson: Text)
    begin
        _contents.Add(BlobPath, StringifiedJson);
    end;

    procedure GetBody(): Text
    begin
        exit(_body);
    end;
}