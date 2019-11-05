#Suppress progress bars to tidy up output
$Global:ProgressPreference = 'SilentlyContinue'

#Display Settings to make the menu look cool
$host.ui.RawUI.BackgroundColor = "Black"
$host.UI.RawUI.ForegroundColor = "Cyan"



#Functions
Function Get-ServerInventory{
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
        ForEach ($line in $tmpPage){
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
    Write-Host "Press any key to return to main menu"
    $null = $host.UI.RawUI.ReadKey()
}



Function Reboot-DomainComputers{
    #Store Hostname
    $myHostname = $ENV:COMPUTERNAME

    #Get Admin Creds
    $cred = Get-Credential -UserName ASIMPSON12\Administrator -Message "Please enter admin credentials"

    $hosts = Get-ADComputer -Filter 'Name -notlike $myHostname' | Select-Object -ExpandProperty Name
    $hosts | % {
        if ((Test-NetConnection $_).PingSucceeded) {
            Write-Host "$_ is up, rebooting..."
            Invoke-Command -ComputerName $_ -ScriptBlock {shutdown -r -t 0} -Credential $cred
            Write-Host "Sent shutdown command, waiting for reboot"
            Start-Sleep -Seconds 10
        }
        while (!(Test-NetConnection $_ -WarningAction SilentlyContinue).PingSucceeded){Start-Sleep -Seconds 1}
        Write-Host "Success: $_ is back up"
    }
    Write-Host "Press any key to return to main menu"
    $null = $host.UI.RawUI.ReadKey()
}
























# MAIN PROGRAM
while($true){

cls
Write-Host "========================================================" 
Write-Host "||                                                    ||"
Write-Host "||               WIN500 - Assignment One              ||"
Write-Host "||                                                    ||"
Write-Host "||                                                    ||"
Write-Host "||       Please Choose From The Following Options:    ||"
Write-Host "||                                                    ||"
Write-Host "||                                                    ||"
Write-Host "||     [1]    Server Inventory                        ||"
Write-Host "||                                                    ||"
Write-Host "||     [2]    Reboot Servers                          ||"
Write-Host "||                                                    ||"
Write-Host "||     [3]    Manage Sessions                         ||"
Write-Host "||                                                    ||"
Write-Host "||     [4]    Active Directory User Lookup            ||"
Write-Host "||                                                    ||"
Write-Host "||     [5]    Import Module                           ||"
Write-Host "||                                                    ||"
Write-Host "||     [6]    Set Constrained Endpoint                ||"
Write-Host "||                                                    ||"
Write-Host "||     [7]    JPEG Query                              ||"
Write-Host "||                                                    ||"
Write-Host "||     [8]    Firewall                                ||"
Write-Host "||                                                    ||"
Write-Host "||     [9]    Exit                                    ||"
Write-Host "||                                                    ||"
Write-Host "||                                                    ||"
Write-Host "========================================================"

#Get choice as [string] type
Write-Host "Choice: " -NoNewline
$choice = $host.UI.RawUI.ReadKey()
$choice = [string]$choice.Character
Write-Host $null #Inserts Newline after ReadKey for clean output


#Switch that directs the user to the right function for the given selection
switch($choice)
{
    '1' {cls; Get-ServerInventory > $null; break}
    '2' {cls; Reboot-DomainComputers; break}
    '3' {Write-Host "Call -Manage Sessions- function"; break}
    '4' {Write-Host "Call -AD User Lookup- function"; break}
    '5' {Write-Host "Call -Import Module- function"; break}
    '6' {Write-Host "Call -Set Constrained Endpoint- function"; break}
    '7' {Write-Host "Call -JPEG Query- function"; break}
    '8' {Write-Host "Call -Firewall- function"; break}
    '9' {exit}

}
#Simulate the function taking time to do work, otherwise the screen clears at the top of the loop before I can see the switch output
#Start-Sleep -Seconds 2

}#end loop

Write-Host "Exiting..."