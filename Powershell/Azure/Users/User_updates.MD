# Updating Users
## login to Azure AD
``` powershell
connect-azuread
```  

## Remove user from o365 group  

``` powershell
Remove-AzureADGroupMember -ObjectId "id" -MemberId "id"
```  

## Get group ID
https://aad.portal.azure.com/#view/Microsoft_AAD_IAM/GroupsManagementMenuBl  

## Get list of o365 group users
``` powershell 
$users = Get-AzureADGroupMember -ObjectId "id" -All $true
```  

##  Loop through AzureAD by group
``` powershell
foreach ($i in ($users)){
    Write-Host $i.UserPrincipalName
    Set-AzureADUser -ObjectId $i.ObjectId -FacsimileTelephoneNumber "(555) 123-4567"
}
```  

## Loop through user by csv  

``` powershell
#change csv name
Import-CSV 123.csv | Foreach-Object{
    $email =  $_.prefix
    $current_user = Get-AzureADUser -ObjectId $email
    Write-Host $current_user.UserPrincipalName $current_user.ObjectId
}
```  
## Loop through user by attribute 
``` powershell
# -eq Equals
# -ne NOt Equals
# -like Equals but not case sensitive
$users = Get-AzureADUser -All $True
$users | Foreach-Object{
    if ($users.PhysicalDeliveryOfficeName -eq "office"){

    Write-Host $_.DisplayName
    }
}
```  
## Log user out
``` powershell
Revoke-AzureADUserAllRefreshToken -ObjectId $_.UPN
```

## Grant graph permissions
``` powershell
# display name of the automation account
$automationAccountDisplayName = "it-automation"
# ObjectID of the System assigned (Managed identity)
$MSIObjectID = "{}" 
# AppID of the Enterprise application that represents System assigned (Managed identity) 
$MSIAppId = "{}"

# '00000003-0000-0000-c000-000000000000' is Graph application
$resourceAppId = '00000003-0000-0000-c000-000000000000'
# list of all Graph permissions + description https://graphpermissions.merill.net/index.html
$permissionList = 'Group.ReadWrite.All', 'User.ReadWrite.All'

$MSI = (Get-AzureADServicePrincipal -Filter "displayName eq '$automationAccountDisplayName'")
if (!$MSI) { throw "Automation account '$automationAccountDisplayName' doesn't exist" }
$resourceSP = Get-AzureADServicePrincipal -Filter "appId eq '$resourceAppId'"
if (!$resourceSP) { throw "Resource '$resourceAppId' doesn't exist" }
foreach ($permission in $permissionList) {
    $AppRole = $resourceSP.AppRoles | Where-Object { $_.Value -eq $permission -and $_.AllowedMemberTypes -contains "Application" }
    if (!$AppRole) {
        Write-Warning "Application permission '$permission' wasn't found in '$resourceAppId' application. Therefore it cannot be added."
        continue
    }

    New-AzureADServiceAppRoleAssignment -ObjectId $MSI.ObjectId -PrincipalId $MSI.ObjectId -ResourceId $resourceSP.ObjectId -Id $AppRole.Id
}
```
