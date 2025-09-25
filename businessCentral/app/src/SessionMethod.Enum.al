#if not CLEAN27
// Licensed under the MIT License. See LICENSE in the project root for license information.
enum 82581 "ADLSE Session Method" implements "ADLSE Session Method Interface"
{
    Caption = 'ADLSE Session Method';
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ';
        Implementation = "ADLSE Session Method Interface" = "ADLSE Method Imp. Undefined";
    }
    value(1; "Handle Export File Number Increase")
    {
        Caption = 'Handle Increase Export File Number';
        Implementation = "ADLSE Session Method Interface" = "ADLSE Method Imp. IncFileName";
    }
    value(2; "Handle Last Timestamp Update")
    {
        Caption = 'Handle Record Last Timestamp';
        Implementation = "ADLSE Session Method Interface" = "ADLSE Method Imp. RecLastTime";
    }
}
#endif