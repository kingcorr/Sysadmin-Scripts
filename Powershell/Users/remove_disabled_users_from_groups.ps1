Install-Module MSOnline
Install-Module AzureAD
Install-Module -Name ExchangeOnlineManagement
Import-Module ExchangeOnlineManagement

Connect-ExchangeOnline -UserPrincipalName {EMAIL}
Connect-AzureAD
Connect-MsolService



#Remove all disabled users fomr O365 groups

Get-AzureADUser -All $true -Filter "AccountEnabled eq false" | ForEach-Object {
$usergroups = Get-AzureADUserMembership -ObjectID "$($_.ObjectId)"
foreach($group in $usergroups){
if ( $group.DisplayName -ne 'All Users')
{
    Write-Host "Removing $($_.DisplayName) from  $($group.DisplayName)"
    Remove-AzureADGroupMember -ObjectId "$($group.ObjectID)" -MemberId "$($_.ObjectId)"
    Remove-MsoLGroupMember -GroupObjectId "$($group.ObjectID)" -GroupMemberType User -GroupmemberObjectId "$($_.ObjectId)"
    Remove-DistributionGroupMember -Identity "$($group.DisplayName)" -Member "$($_.DisplayName)"
}
}


