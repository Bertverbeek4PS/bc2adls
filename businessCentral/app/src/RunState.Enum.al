// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
enum 82560 "ADLSE Run State"
{
    Access = Internal;
    Extensible = false;

#pragma warning disable LC0045
    value(0; None)
    {
        Caption = 'Never run';
    }
#pragma warning restore LC0045

    value(1; InProcess)
    {
        Caption = 'In process';
    }

    value(2; Success)
    {
        Caption = 'Success';
    }

    value(3; Failed)
    {
        Caption = 'Failed';
    }
}