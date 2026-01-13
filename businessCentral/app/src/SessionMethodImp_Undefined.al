#if not CLEAN27
// Licensed under the MIT License. See LICENSE in the project root for license information.
namespace bc2adls;
codeunit 82581 "ADLSE Method Imp. Undefined" implements "ADLSE Session Method Interface"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This field will be removed in a future release because readuncommitted will be the default behavior because of performance.';

    var
        UndefinedMethodErr: Label 'Method not defined';
        InvalidParametersErr: Label 'Invalid or missing parameters for method %1', Comment = '%1 = Method name';
        MissingJsonParameterErr: Label 'Missing parameter ''%1'' for method %2', Comment = '%1 = Parameter name, %2 = Method name';

    procedure Execute(Params: Text)
    begin
        Error(UndefinedMethodErr);
    end;

    procedure ErrorInvalidParameters(MethodName: Text)
    begin
        Error(InvalidParametersErr, MethodName);
    end;

    procedure ErrorMissingJsonParameter(ParameterName: Text; MethodName: Text)
    begin
        Error(MissingJsonParameterErr, ParameterName, MethodName);
    end;
}
#endif