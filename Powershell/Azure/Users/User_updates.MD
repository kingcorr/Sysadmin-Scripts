# Updating Users  

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
