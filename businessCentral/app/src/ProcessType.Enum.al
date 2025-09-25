#if not CLEAN27
// Licensed under the MIT License. See LICENSE in the project root for license information.
enum 82580 "ADLSE Process Type"
{
    Access = Internal;
    Extensible = false;

    value(0; "Standard")
    {
        Caption = 'Standard';
    }
    value(1; "Ignore Read Isolation")
    {
        Caption = 'Ignore Read Isolation';
    }
    value(2; "Commit Externally")
    {
        Caption = 'Commit Externally';
    }
}
#endif