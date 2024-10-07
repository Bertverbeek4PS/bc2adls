// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
enum 82561 "ADLSE Http Method"
{
    Access = Internal;
    Extensible = false;

#pragma warning disable LC0016, LC0045
    value(0; Get) { }
    value(1; Put) { }
    value(2; Delete) { }
    value(3; Patch) { }
    value(4; Head) { }
#pragma warning restore
}