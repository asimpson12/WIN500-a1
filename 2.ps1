#Get Admin creds from user
#$cred = Get-Credential -UserName Administrator@asimpson12.loc -Message "Please enter administrator credentials (required for remote connections)"

#Fetch all known hosts, store as list of strings
$domainPCS = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name

#Empty old contents of down list
Set-Content C:\Temp\down.txt $null

#Empty old contents of output webpage
$null | Set-Content C:\Temp\SpaceInfo.html

#Init list of storage info
$storageQueries = @()

$domainPCS | % {
    if (!(Test-NetConnection -ComputerName $_ -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).PingSucceeded){
        Add-Content C:\Temp\down.txt -Value "`n<p><b>$_</b></p>"
    } else {
        $pcName = $_
        try{$storageQueries += Invoke-Command -ComputerName $pcName -FilePath C:\Temp\QueryStorage+RAM.ps1 -ErrorAction Stop}
        catch {$storageQueries += Invoke-Command -ComputerName $pcName -Credential ASIMPSON12\Administrator -FilePath C:\Temp\QueryStorage+RAM.ps1}
    }
}

#Format info gathered from script invokations, store in output buffer
$storageQueries | Select-Object  @{L='Disk Space Free (MB)';E={$_.FreeHDD}}, @{L='Total Disk Space (MB)';E={$_.TotalHDD}}, @{L='Total RAM (GB)';E={$_.TotalRAM}}, @{L='Operating System';E={$_.OS}} | ConvertTo-Html -Title "Query Results" -Body $_ | Out-File -FilePath C:\Temp\tmp.html

$tmpPage = Get-Content C:\Temp\tmp.html

#Print hosts that are down (if appropriate)
if ($(gc C:\Temp\down.txt) -ne $null){
    ForEach ($line in $tmpPage) {
        Add-Content -Path C:\Temp\SpaceInfo.html $line
        if ($line -like "</table>"){
            Add-Content -Path C:\Temp\SpaceInfo.html -Value "<p></p>"
            Add-Content -Path C:\Temp\SpaceInfo.html -Value "<p></p>"
            Add-Content -Path C:\Temp\SpaceInfo.html -Value  "<p><u>The following systems are down:</u></p>"
            gc C:\Temp\down.txt | Add-Content -Path C:\Temp\SpaceInfo.html
        }
    }
}else{gc C:\Temp\tmp.html | Set-Content C:\Temp\SpaceInfo.html}

 

Invoke-Item C:\Temp\SpaceInfo.html