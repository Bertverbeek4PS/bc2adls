// PowerShell script to remove all ToolTip lines from table files
Get-Content "c:\Users\sup.avanamersfoort\Repos\AL-bc2adls-OnPrem\businessCentral\app\src\Setup.Table.al" | 
Where-Object { $_ -notmatch "^\s*ToolTip\s*=" } | 
Set-Content "c:\Users\sup.avanamersfoort\Repos\AL-bc2adls-OnPrem\businessCentral\app\src\Setup.Table.al"