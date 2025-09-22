#if not CLEAN27
// Licensed under the MIT License. See LICENSE in the project root for license information.
codeunit 82584 "ADLSE Method Imp. SetIsPart." implements "ADLSE Session Method Interface"
{
    var
        UndefinedMethodImp: Codeunit "ADLSE Method Imp. Undefined";
        MethodLbl: Label 'HandleSetIsPartialSync';

    procedure Execute(Params: Text)
    var
        TableLastTimestamp: Record "ADLSE Table Last Timestamp";
        JsonObject: JsonObject;
        TableId: Integer;
        IsPartialSync: Boolean;
    begin
        if not JsonObject.ReadFrom(Params) then
            UndefinedMethodImp.ErrorInvalidParameters(MethodLbl);

        TableId := GetJsonValue(JsonObject, 'TableId').AsValue().AsInteger();
        IsPartialSync := GetJsonValue(JsonObject, 'IsPartialSync').AsValue().AsBoolean();

        TableLastTimestamp.SetIsPartialSync_InCurrSession(TableId, IsPartialSync);
    end;

    local procedure GetJsonValue(JsonObject: JsonObject; TokenName: Text) JsonToken: JsonToken
    begin
        if not JsonObject.Get(TokenName, JsonToken) then
            UndefinedMethodImp.ErrorMissingJsonParameter(TokenName, MethodLbl);
    end;
}
#endif