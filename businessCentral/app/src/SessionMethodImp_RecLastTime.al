#if not CLEAN27
// Licensed under the MIT License. See LICENSE in the project root for license information.
codeunit 80033 "ADLSE Method Imp. RecLastTime" implements "ADLSE Session Method Interface"
{

    var
        UndefinedMethodImp: Codeunit "ADLSE Method Imp. Undefined";
        MethodLbl: Label 'HandleRecordLastTimestamp';

    procedure Execute(Params: Text)
    var
        TableLastTimestamp: Record "ADLSE Table Last Timestamp";
        JsonObject: JsonObject;
        TableId: Integer;
        Timestamp: BigInteger;
        Upsert: Boolean;
    begin
        if not JsonObject.ReadFrom(Params) then
            UndefinedMethodImp.ErrorInvalidParameters(MethodLbl);

        TableId := GetJsonValue(JsonObject, 'TableId').AsValue().AsInteger();
        Timestamp := GetJsonValue(JsonObject, 'Timestamp').AsValue().AsBigInteger();
        Upsert := GetJsonValue(JsonObject, 'Upsert').AsValue().AsBoolean();

        TableLastTimestamp.RecordLastTimestamp_InCurrSession(TableId, Timestamp, Upsert);
    end;

    local procedure GetJsonValue(JsonObject: JsonObject; TokenName: Text) JsonToken: JsonToken
    begin
        if not JsonObject.Get(TokenName, JsonToken) then
            UndefinedMethodImp.ErrorMissingJsonParameter(TokenName, MethodLbl);
    end;
}
#endif