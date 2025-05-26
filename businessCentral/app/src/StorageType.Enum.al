enum 82563 "ADLSE Storage Type"
{
    Access = Internal;
    Extensible = false;

#pragma warning disable LC0045
    value(0; "Azure Data Lake")
    {
        Caption = 'Azure Data Lake';
    }
#pragma warning restore LC0045
    value(1; "Microsoft Fabric")
    {
        Caption = 'Microsoft Fabric';
    }
    value(2; "Open Mirroring")
    {
        Caption = 'Microsoft Fabric - Open Mirroring';
    }
}