#Suppress progress bars to tidy up output
$Global:ProgressPreference = 'SilentlyContinue'


#Display Settings to make the menu look cool
$host.ui.RawUI.BackgroundColor = "Black"
$host.UI.RawUI.ForegroundColor = "Cyan"



#Functions
Function Get-ServerInventory{
    #Fetch all known hosts, store as list of strings
    $domainPCS = Get-ADComputer -Filter 'DNSHostName -like "*.loc"' | Select-Object -ExpandProperty Name

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
            Start-Sleep 2
            Clear-Host
            Write-Host "Querying host $pcName ........        " -NoNewline
            try{$storageQueries += Invoke-Command -ComputerName $pcName -FilePath C:\Temp\QueryStorage+RAM.ps1 -ErrorAction Stop}
            catch {$storageQueries += Invoke-Command -ComputerName $pcName -Credential ASIMPSON12\Administrator -FilePath C:\Temp\QueryStorage+RAM.ps1}
            Write-Host "[OK]"
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

    $hosts = Get-ADComputer -Filter '(Name -notlike $myHostname) -and (DNSHostName -like "*.loc")' | Select-Object -ExpandProperty Name
    $hosts | % {
        if ((Test-NetConnection $_).PingSucceeded) {
            Clear-Host
            Write-Host "$_ is up, rebooting..."
            Invoke-Command -ComputerName $_ -ScriptBlock {shutdown -r -t 0} -Credential $cred
            Write-Host "Sent shutdown command, waiting for reboot"
            Start-Sleep -Seconds 10
        }
        while (!(Test-NetConnection $_ -WarningAction SilentlyContinue).PingSucceeded){Start-Sleep -Seconds 1}
        Write-Host "Success: $_ is back up"
        Start-Sleep 2
    }
    Write-Host "Press any key to return to main menu"
    $null = $host.UI.RawUI.ReadKey()
}


Function Manage-PSSessions{
    Write-Host "Welcome to the PSSession management utility"
    $sessionTarget = Read-Host "Please supply the hostname of the computer with which to initiate a session (-ComputerName)"
    $sessionName = Read-Host "Please supply a name for the session (-Name)"
    Write-Host "Please supply a credential with which to initiate the connection:"
    New-PSSession -ComputerName $sessionTarget -Name $sessionName -Credential $(Get-Credential ASIMPSON12\Administrator)
    Clear-Host
    Write-Host "Remote Powershell Sessions:"
    Get-PSSession
    Write-Host "Press any key to return to menu"
    $null = $host.UI.RawUI.ReadKey()
    
    Clear-Host
    Write-Host "Exit menu to enter session $sessionName"
    Start-Sleep 2
    Clear-Host

    Enter-PSSession -Name $sessionName

}


Function Get-ADActiveAccounts(){
    
    #Get argument string, store in $isActiveUser
    Param(
        [parameter(Mandatory=$true)]
        [String]
        $isActiveUser
    )
    $filter = 'SamAccountName -like "'
    $filter += $isActiveUser
    $filter += '"' 
    $isActive = Get-ADUser -Filter $filter | Select-Object -ExpandProperty Enabled
    $hasLoggedIn = Get-ADUser -Filter $filter -Properties lastlogon| Select-Object -ExpandProperty lastlogon

    if($isActive -like "True"){
        Write-Host "User $isActiveUser's account is active"
    }else{
        Write-Host "User $isActiveUser's account is inactive"
    }

    if($hasLoggedIn -like "0"){
        Write-Host "User $isActiveUser has not yet logged in"
    }else{
        Write-Host "User $isActiveUser has logged into their account"
    }


    Write-Host "Press any key to return to main menu..."
    $choice = $host.UI.RawUI.ReadKey()
}

Function Import-MyCmdlets(){
    $yn = Read-Host("Would you like to import the module <mycmdlets>?[y/n]")
    if($yn -notlike "n" -and $yn -notlike "N"){
        Import-Module mycmdlets -Force
        Write-Host "Module <mycmdlets> has been imported successfully"
        Write-Host "The following functions have since been made available:"
        Get-Command -Module mycmdlets
        Write-Host "Press any key to return to main menu...."
        $choice = $host.UI.RawUI.ReadKey()
        Clear-Host
    }else{
        Write-Host "Aborting at user's request"
        Write-Host "Press any key to return to main menu...."
        $choice = $host.UI.RawUI.ReadKey()
        Clear-Host
    }
}

Function Find-Jpeg{
    Write-Host "Connected to $env:COMPUTERNAME"
    
    New-Item C:\Temp\picture\ -ErrorAction SilentlyContinue

    Write-Host "Copying .jpg files to folder C:\Temp\picture..."
    Get-ChildItem *.jpg -Path C:\ -Recurse | Copy-Item -Destination C:\Temp\picture -ErrorAction SilentlyContinue
    Write-Host "Copying complete"
}

Function Sort-ADJpeg{
    $cred = Get-Credential ASIMPSON12\Administrator
    $myHostname = $env:COMPUTERNAME
    Get-ADComputer -Filter '(Name -notlike $myHostname) -and (DNSHostName -like "*.loc")' | Select-Object -ExpandProperty Name | % {
        Invoke-Command -ComputerName $_ -ScriptBlock ${function:Find-Jpeg} -Credential $cred
    }
    Write-Host "Press any key to return to main menu..."
    $choice = $host.UI.RawUI.ReadKey()
}

Function Get-Hostnames{
    if (Test-Path C:\temp\hostnames.txt){rm C:\temp\hostnames.txt}
    New-Item -Path C:\temp\hostnames.txt > $null
    Get-ADComputer -Filter 'DNSHostName -like "*.loc"' | Select-Object -ExpandProperty Name | % {
        Add-Content -Path C:\temp\hostnames.txt -Value $_
    }
    
}

Function Set-FirewallStatus{
    Write-Host "Enabling Domain firewall on $env:COMPUTERNAME..."
    if($(Get-NetFirewallProfile -Name Domain | Select-Object -ExpandProperty Enabled) -like "True"){
        Write-Host "Domain firewall is already enabled"
    }else{
        try{Set-NetFirewallProfile -Name Domain -Enabled True -ErrorAction Stop; Write-Host "Domain firewall has been enabled successfully"}
        catch{Write-Host "Unable to set firewall on host $env:HOSTNAME, firewall still set to $(Get-NetFirewallProfile -Name Domain | Select-Object -ExpandProperty Enabled)"}
    }


}


Function Get-FirewallStatus{
    Get-Hostnames
    $cred = Get-Credential ASIMPSON12\Administrator
    Get-Content -Path C:\temp\hostnames.txt | % {
        Invoke-Command -ComputerName $_ -Credential $cred -ScriptBlock ${function:Set-FirewallStatus}
    }
    Write-Host "Press any key to return to main menu...."
    $choice = $host.UI.RawUI.ReadKey()
}








# MAIN PROGRAM
while($true){

cls
Write-Host "========================================================" 
Write-Host "||                                                    ||"
Write-Host "||                 WIN500 - Assignment                ||"
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
Write-Host "||     [5]    Create Users and Groups                 ||"
Write-Host "||                                                    ||"
Write-Host "||     [6]    Import Module                           ||"
Write-Host "||                                                    ||"
Write-Host "||     [7]    Set Constrained Endpoint                ||"
Write-Host "||                                                    ||"
Write-Host "||     [8]    JPEG Query                              ||"
Write-Host "||                                                    ||"
Write-Host "||     [9]    Firewall                                ||"
Write-Host "||                                                    ||"
Write-Host "||     [x]   Exit                                     ||"
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
    '3' {cls; Manage-PSSessions; break}
    '4' {cls; Get-ADActiveAccounts($(Read-Host "Please enter the name of the user to query")); break}
    '5' {cls; Invoke-Expression 'C:\Users\asimpson12\assignment\AddUser.ps1'} #-Credential $(Get-Credential ASIMPSON12\Administrator); break}
    '6' {cls; Import-MyCmdlets; break}
    '7' {cls; $choice = $host.UI.RawUI.ReadKey(); break}
    '8' {cls; Sort-ADJpeg; break}
    '9' {cls; Get-FirewallStatus; break}
    'x' {exit}

}
#Simulate the function taking time to do work, otherwise the screen clears at the top of the loop before I can see the switch output
#Start-Sleep -Seconds 2

}#end loop

Write-Host "Exiting..."