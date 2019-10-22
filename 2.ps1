$domainPCS = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name
Set-Content C:\Temp\down.txt $null
$domainPCS | % {
    if (!(Test-NetConnection -ComputerName $_ -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).PingSucceeded){Add-Content C:\Temp\down.txt "`n$_"}
}