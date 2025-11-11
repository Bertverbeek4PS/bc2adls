// Licensed under the MIT License. See LICENSE in the project root for license information.
enum 82580 "ADLSE Process Type"
{
    Access = Internal;
    Extensible = false;
    ObsoleteState = Pending;
    ObsoleteReason = 'This field will be removed in a future release because readuncommitted will be the default behavior because of performance.';

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