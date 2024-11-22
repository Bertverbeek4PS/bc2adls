codeunit 82580 "Fabric Subscribers"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ADLSE Http", 'OnBeforeAddContent', '', true, true)]
    local procedure OnBeforeAddContent(var HttpContent: HttpContent; ContentTypeJson: Boolean; body: Text)
    var
        ADLSESetup: Record "ADLSE Setup";
        Headers: HttpHeaders;
    begin
        ADLSESetup.GetSingleton();
        if ADLSESetup."Storage Type" <> ADLSESetup."Storage Type"::"Microsoft Fabric" then
            exit;

        if not ContentTypeJson then
            HttpContent.WriteFrom(Body);

        HttpContent.GetHeaders(Headers);

        if ContentTypeJson then begin
            Headers.Remove('Content-Type');
            Headers.Add('Content-Type', 'application/json');
            Headers.Remove('Content-Length');
            Headers.Add('Content-Length', '0');
        end else
            Headers.Remove('Content-Length');
    end;
}