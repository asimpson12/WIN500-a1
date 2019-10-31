#Get Admin creds from user
#$cred = Get-Credential -UserName Administrator@asimpson12.loc -Message "Please enter administrator credentials (required for remote connections)"

#Fetch all known hosts, store as list of strings
$domainPCS = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name

#Empty old contents of down list
Set-Content C:\Temp\down.txt $null

#Init list of storage info
$storageQueries = @()

$domainPCS | % {
    if (!(Test-NetConnection -ComputerName $_ -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).PingSucceeded){
        Add-Content C:\Temp\down.txt "`n$_"
    } else {
        $pcName = $_
        try{$storageQueries += Invoke-Command -ComputerName $pcName -FilePath C:\Temp\QueryStorage+RAM.ps1 -ErrorAction Stop}
        catch {$storageQueries += Invoke-Command -ComputerName $pcName -Credential ASIMPSON12\Administrator -FilePath C:\Temp\QueryStorage+RAM.ps1}
    }
}

$storageQueries | Select-Object -Property FreeHDD, TotalHDD, TotalRAM, OS | ft @{L='Disk Space Free (MB)';E={$_.FreeHDD}}, @{L='Total Disk Space (MB)';E={$_.TotalHDD}}, @{L='Total RAM (GB)';E={$_.TotalRAM}}, @{L='Operating System';E={$_.OS}} -AutoSize | sort -Property OS

#Print hosts that are down (if appropriate)
if ($(gc C:\Temp\down.txt) -ne $null){
    Write-Host "The following systems are down:"
    gc C:\Temp\down.txt
}