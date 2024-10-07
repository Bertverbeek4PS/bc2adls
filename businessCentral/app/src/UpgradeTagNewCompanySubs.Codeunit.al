// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
codeunit 82575 "ADLSE UpgradeTagNewCompanySubs"
{
    Access = Internal;

    [InherentPermissions(PermissionObjectType::Codeunit, Codeunit::"ADLSE Upgrade", 'X')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure OnGetPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    var
        ADLSEUpgrade: Codeunit "ADLSE Upgrade";
    begin
        PerCompanyUpgradeTags.Add(ADLSEUpgrade.GetRetenPolLogEntryAddedUpgradeTag());
        PerCompanyUpgradeTags.Add(ADLSEUpgrade.GetContainerFieldFromIsolatedStorageToSetupFieldUpgradeTag());
    end;
}