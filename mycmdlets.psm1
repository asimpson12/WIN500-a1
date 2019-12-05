$Global:ProgressPreference = 'SilentlyContinue'
Function Get-ActiveComputers {

<#
.Synopsis
Queries Active Directory for online computers, fetches computer name, OS, and up time for each

.Description
Queries Active Directory for online computers, fetches computer name, OS, and up time for each


.Example
PS>Get-ActiveComputers

.Link
about_functions
about_functions_advanced

.Notes
NAME: Get-ActiveComputers
AUTHOR: asimpson12
    DATELASTMODIFIED: 11/21/2019

#>


    Get-ADComputer -Filter *  -Properties CN | Select-Object -ExpandProperty CN  | % {
        if ((Test-NetConnection $_ -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).PingSucceeded){
            $bootuptime = [DateTime](Get-CimInstance -ComputerName $_ -ClassName Win32_OperatingSystem -Property LastBootUpTime | Select-Object -ExpandProperty LastBootUpTime)
            $OS = Get-CimInstance -ComputerName $_ -ClassName Win32_OperatingSystem -Property Caption | Select-Object -ExpandProperty Caption
            Write-Host "Hostname: $_"
            Write-Host "Operating System: $OS"
            Write-Host "Uptime: $([Math]::Round((New-TimeSpan -Start $bootuptime -End (Get-Date) | Select-Object -ExpandProperty TotalSeconds),0)) seconds."
            Write-Host
        }
    }





}

Function Add-DomainUser{

<#
.Synopsis
Creates a new user in Active Directory with the specified given name, surname, and department

.Description
Creates a new user in Active Directory with the specified given name, surname, and department


.Example
PS>Add-DomainUser

.Link
about_functions
about_functions_advanced

.Notes
NAME: Add-DomainUser
AUTHOR: asimpson12
    DATELASTMODIFIED: 11/21/2019

#>


    $givenName = Read-Host -Prompt "What is the first name of the new user?"
    $surName = Read-Host -Prompt "What is the last name of the new user?"
    $department = Read-Host -Prompt "To which department does this user belong?"
    $username = "$($givenName.ToLower()).$($surname.ToLower())"
    New-ADUser -Name $username -GivenName $givenName -Surname $surName -Department $department -Credential (Get-Credential -Username ASIMPSON12\Administrator -Message "Please enter credentials of the domain administrator to continue creating a user")

}

Function Get-Login{
<#
.Synopsis
Retrieves a list of the name, date, and all users last logged into the network

.Description
Retrieves a list of the name, date, and all users last logged into the network


.Example
PS>Get-Login

.Link
about_functions
about_functions_advanced

.Notes
NAME: Get-Login
AUTHOR: asimpson12
    DATELASTMODIFIED: 11/21/2019

#>


    

    Get-LocalUser | ? {$_.lastlogon -ne $null} | select Name, LastLogon | ConvertTo-Html -Title "Login Times of Local Users - $ENV:COMPUTERNAME" > C:\Temp\LoginTimes.html
    Invoke-Item C:\Temp\LoginTimes.html

}

Function Set-RestrictedHours{
<#
.Synopsis
Sets the permitted logon hours of a given domain user to 9am to 6pm, and weekdays only

.Description
Sets the permitted logon hours of a given domain user to 9am to 6pm, and weekdays only


.Example
PS>Set-RestrictedHours

.Link
about_functions
about_functions_advanced

.Notes
NAME: Set-RestrictedHours
AUTHOR: asimpson12
    DATELASTMODIFIED: 11/21/2019

#>



    $User = Read-Host -Prompt "Please enter the username of the user whose logon hours you wish to constrain"
    [byte[]]$9to6 = @(0, 0, 0, 0, 0, 254, 3, 0, 254, 3, 0, 254, 3, 0, 254, 3, 0, 254, 3, 0, 0)
    Set-ADUser -Identity $User -Replace @{logonhours=$9to6}

}