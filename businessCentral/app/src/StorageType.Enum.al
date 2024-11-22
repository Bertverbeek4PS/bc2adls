enum 82563 "ADLSE Storage Type" implements "ADLS Integrations"
{
    Access = Internal;
    Extensible = false;

#pragma warning disable LC0045
    value(0; "Azure Data Lake")
    {
        Caption = 'Azure Data Lake';
        Implementation = "ADLS Integrations" = "Azure Communication";
    }
#pragma warning restore LC0045
    value(1; "Microsoft Fabric")
    {
        Caption = 'Microsoft Fabric';
        Implementation = "ADLS Integrations" = "Fabric Communication";
    }
}