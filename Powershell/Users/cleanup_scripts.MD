# User cleanup scripts  

A list of commands to cleanup an o365 environment 
## Login and setup  

```powershell
Install-Module Microsoft.Graph.Authentication
Install-Module Microsoft.Graph.Users
Set-ExecutionPolicy RemoteSigned
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Users
Connect-MgGraph -Scopes "User.Read.All","Group.ReadWrite.All"
Select-MgProfile -Name "beta"
$global:o365users= Get-MgUser -All
$enabled_users = $global:o365users | Where-Object -Property AccountEnabled -eq True
$disabled_users = $global:o365users | Where-Object -Property AccountEnabled -ne True
```  
## Check for users without employee id  

```powershell
$users= @()
foreach ($User in $enabled_users){
    Write-Host $User.employeeId
    if ($User.employeeId -eq $null){
    $outputhashtable = @{o365_user = $User.DisplayName; Email=$User.UserPrincipalName; employee_id = $User.EmployeeId}
    $users += [pscustomobject]$outputhashtable
    }
}
$users | Format-Table
```  

## Check for non blocked SMB users  

```powershell
$users= @()
foreach ($User in $enabled_users){
    if ($User.DisplayName -like "*SMB*"){
    $outputhashtable = @{o365_user = $User.DisplayName; Email=$User.UserPrincipalName; employee_id = $User.EmployeeId}
    $users += [pscustomobject]$outputhashtable
    }
}
$users | Format-Table
```  

## Check for disabled users with licenses  

```powershell
$users= @()
foreach ($User in $disabled_users){
    if ($User.AssignedLicenses.Count -gt 0){
    $outputhashtable = @{o365_user = $User.DisplayName; Email=$User.UserPrincipalName; licenses = $User.AssignedLicenses.Count; enabled = $User.AccountEnabled}
    $users += [pscustomobject]$outputhashtable
    }
}
$users | Format-Table
```  

## list unique offices  

```powershell
$users= @()
foreach ($User in $enabled_users){
    if (-Not ($users -clike $User.OfficeLocation)){
        $users += $User.OfficeLocation
    }

}
$users | Format-Table
```  

## list unique States  

``` powershell
$users= @()
foreach ($User in $enabled_users){
    if (-Not ($users -contains $User.State)){
        $users += $User.State
    }

}
$users | Format-Table
```  

## list unique Street address  

```powershell
$users= @()
foreach ($User in $enabled_users){
    if (-Not ($users -contains $User.StreetAddress)){
        $users += $User.StreetAddress
    }

}
$users | Format-Table
```  

## list unique departments
```powershell
$users= @()
foreach ($User in $enabled_users){
    if (-Not ($users -contains $User.Department)){
        $users += $User.Department
    }

}
$users | Format-Table
```  

# #Department and title check  

```powershell
$report= @()
foreach ($User in $enabled_users){
    if ($user.Department -notmatch $user.JobTitle){
    $hashtable = @{user= $user.displayname; title=$user.JobTitle;department=$user.department}
    $report += [pscustomobject]$hashtable
    }

}
$report | Format-Table
```  

