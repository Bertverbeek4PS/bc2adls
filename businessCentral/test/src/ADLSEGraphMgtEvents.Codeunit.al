codeunit 85564 "ADLSE Graph Mgt Events"
{
    SingleInstance = true;

    var
        IdentityManagement: Codeunit "Identity Management";
        WebServicesKey: Text[80];

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Library - Graph Mgt", 'OnAfterInitializeWebRequestWithURL', '', false, false)]
    local procedure OnAfterInitializeWebRequestWithURL(var HttpWebRequestMgt: Codeunit "Http Web Request Mgt.")
    begin
        if WebServicesKey = '' then
            WebServicesKey := IdentityManagement.GetWebServicesKey(UserSecurityId());

        HttpWebRequestMgt.AddBasicAuthentication(UserId(), WebServicesKey);
    end;
}