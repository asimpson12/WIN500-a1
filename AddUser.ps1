#UserCreationScript

$cred = Get-Credential ASIMPSON12\Administrator

$newUser = Read-Host("Please enter a username for the new AD user")
$userObj = New-ADUser -Name $newUser -SamAccountName $newUser -Credential $cred
$newGroup = Read-Host("Please enter a name for the new AD group")
$groupObj = New-ADGroup -Name $newGroup -GroupScope DomainLocal -Credential $cred
Add-ADGroupMember -Identity $newGroup -Members $newUser, Administrator -Credential $cred

Write-Host "Success: User $newUser has been created, and has been added to new domain local group $newGroup"
Write-Host "$newGroup members:"

Get-ADGroupMember -Identity $newGroup | select Name