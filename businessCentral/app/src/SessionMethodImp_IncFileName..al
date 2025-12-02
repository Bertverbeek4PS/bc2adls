#if not CLEAN27
codeunit 80040 "ADLSE Method Imp. IncFileName" implements "ADLSE Session Method Interface"
{
    var
        UndefinedMethodImp: Codeunit "ADLSE Method Imp. Undefined";
        MethodLbl: Label 'HandleIncreaseExportFileNumber';

    procedure Execute(Params: Text)
    var
        ADLSECommunication: Codeunit "ADLSE Communication";
        TableIdAsInt: Integer;
    begin
        Evaluate(TableIdAsInt, Params);
        if TableIdAsInt = 0 then
            UndefinedMethodImp.ErrorInvalidParameters(MethodLbl);
        ADLSECommunication.IncreaseExportFileNumber_InCurrSession(TableIdAsInt);
    end;
}
#endif