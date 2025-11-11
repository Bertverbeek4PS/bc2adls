// Licensed under the MIT License. See LICENSE in the project root for license information.
table 82580 "Session Instruction"
{
    Caption = 'Session Instruction';
    DataClassification = CustomerContent;
    ObsoleteState = Pending;
    ObsoleteReason = 'This field will be removed in a future release because readuncommitted will be the default behavior because of performance.';
    fields
    {
        field(1; "Session Id"; Integer)
        {
            Caption = 'Session Id';
        }
        field(2; "Object Type"; Option)
        {
            OptionMembers = ,Table,,Report,,Codeunit,,,,,,;
            OptionCaption = ',Table,,Report,,Codeunit,,,,,,';
            Caption = 'Object Type';
        }
        field(3; "Object ID"; Integer)
        {
            Caption = 'Codeunit ID';
        }
        field(4; Method; Enum "ADLSE Session Method")
        {
            Caption = 'Method';
        }
        field(5; Params; Text[250])
        {
            Caption = 'Params';
        }
        field(6; "Status"; Option)
        {
            OptionMembers = "In Progress",Finished,Failed;
            Caption = 'Status';
            DataClassification = CustomerContent;
            OptionCaption = 'In Progress,Finished,Failed';
        }
        field(7; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PK; "Session Id")
        {
            Clustered = true;
        }
    }
}