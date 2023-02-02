$StreetAddress = ""
$State = ""
$City = ""
$PostalCode = ""
$lookup_branch = ""
Connect-AzureAD
$user_list = Get-AzureADUser -all $true | where-object -property PhysicalDeliveryOfficeName -eq $lookup_branch
$user_list

$report = @()
foreach ($user in $user_list){
    Write-Host "Updating $($user.UserPrincipalName)"
    Set-AzureADUser -ObjectId $user.UserPrincipalName -StreetAddress $StreetAddress
    Set-AzureADUser -ObjectId $user.UserPrincipalName -State $State
    Set-AzureADUser -ObjectId $user.UserPrincipalName -City $City
    Set-AzureADUser -ObjectId $user.UserPrincipalName -PostalCode $PostalCode
    #Write-Host "Waiting to check"
    #Start-Sleep 20
    $update = Get-AzureADUser -ObjectId $user.UserPrincipalName | Select-Object -Property UserPrincipalName, StreetAddress, State, City, PostalCode
    $report += $update
}

$report | Format-Table
