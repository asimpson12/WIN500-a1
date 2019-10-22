$storageInfo = New-Object psobject -Property @{
    OS = Get-ComputerInfo -Property OsName | Select-Object -ExpandProperty OsName
    TotalRAM = [math]::Round((([double](Get-ComputerInfo -Property OsTotalVisibleMemorySize | Select-Object -ExpandProperty OsTotalVisibleMemorySize) /1024)/1024), 2) #In GB
    TotalHDD = [math]::Round(((([double](Get-PSDrive C | Select-Object -ExpandProperty Used) + [double](Get-PSDrive C | Select-Object -ExpandProperty Free))/1024)/1024), 2) #In MB
    FreeHDD = [math]::Round((([double](Get-PSDrive C | Select-Object -ExpandProperty Free)/1024)/1024), 2) #In MB
}
$storageInfo