# Azure Ref
## login to Azure AD
``` powershell
connect-azuread
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
