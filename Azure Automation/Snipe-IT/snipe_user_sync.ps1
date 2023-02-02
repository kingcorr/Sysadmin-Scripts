
<# For AzureAutomation #>
Write-Output "Connecting to Azure"
Connect-AzAccount -Identity
Write-Output "Connecting to Graph"
$token = (Get-AzAccessToken -ResourceTypeName MSGraph).token # Get-PnPAccessToken if you are already connected to Sharepoint
Connect-MgGraph -AccessToken $token
Select-MgProfile -Name "beta"
$global:snipe_api = Get-AutomationVariable -Name snipe_api

# Get JSON files
Write-Output "Getting files"
$StorageAccountKey = Get-AutomationVariable -Name Storage_account_key
$Context = New-AzureStorageContext -StorageAccountName '{}' -StorageAccountKey $StorageAccountKey
Get-AzureStorageFileContent -ShareName 'it-automation' -Context $Context -path 'branch_info.json' -Destination 'C:\Temp'
Get-AzureStorageFileContent -ShareName 'it-automation' -Context $Context -path 'department_info.json' -Destination 'C:\Temp'
$branch_info = Get-Content "C:\Temp\branch_info.json" | ConvertFrom-Json
$department_info = Get-Content "C:\Temp\department_info.json" | ConvertFrom-Json


<# For Desktop #>
#Install-Module Microsoft.Graph.Authentication
#Install-Module Microsoft.Graph.Users
#Set-ExecutionPolicy RemoteSigned
#Import-Module Microsoft.Graph.Authentication
#Import-Module Microsoft.Graph.Users
#Connect-MgGraph -Scopes "User.Read.All","Group.ReadWrite.All"
#Select-MgProfile -Name "beta"
#$global:snipe_api = 
#$branch_info = Get-Content "branch_info.json" | ConvertFrom-Json
#$department_info = Get-Content "department_info.json" | ConvertFrom-Json

<# Begin #>

# Gets all snipe users from API
function get-snipe-users($api){

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Accept", "application/json")
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Authorization", "Bearer $api" )

    $global:snipe_users = Invoke-RestMethod '{DOMAIN}/api/v1/users?limit=1000&order=desc&sort=id' -Method 'GET' -Headers $headers -UseBasicParsing 

}

# Deletes snipe user by ID
function delete_snipe_user($api,$id){
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", "Bearer $api" )
    $response = Invoke-RestMethod "{DOMAIN}/api/v1/users/$id" -Method "DELETE" -Headers $headers -UseBasicParsing
    return $response

}


# Decodes html text from snipe
function decode_html($str1){
   return [System.Web.HttpUtility]::HtmlDecode($str1)
}


# Encodes
function encode_html($str1){
   return [System.Web.HttpUtility]::HtmlEncode($str1)
}


# Snipe Update headers
$update_headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$update_headers.Add("Accept", "application/json")
$update_headers.Add("Content-Type", "application/json")
$update_headers.Add("Authorization", "Bearer )

# update a snipe user
function update_snipe_user($api,$body, $id){
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Accept", "application/json")
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Authorization", "Bearer $api" )
    $response = Invoke-RestMethod "{DOMAIN}/api/v1/users/$id" -Method 'PATCH' -headers $headers -Body $body -UseBasicParsing
    return $response
}

# Create Snipe User
function create_snipe_user($api,$body){
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Accept", "application/json")
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Authorization", "Bearer $api" )
    $response = Invoke-RestMethod "{DOMAIN}/api/v1/users" -Method 'POST' -headers $headers -Body $body -UseBasicParsing
    return $response

}

# Gen password
function Get-RandomPassword {
    param (
        [Parameter(Mandatory)]
        [ValidateRange(4,[int]::MaxValue)]
        [int] $length,
        [int] $upper = 1,
        [int] $lower = 1,
        [int] $numeric = 1,
        [int] $special = 1
    )
    if($upper + $lower + $numeric + $special -gt $length) {
        throw "number of upper/lower/numeric/special char must be lower or equal to length"
    }
    $uCharSet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    $lCharSet = "abcdefghijklmnopqrstuvwxyz"
    $nCharSet = "0123456789"
    $sCharSet = "/*-+,!?=()@;:._"
    $charSet = ""
    if($upper -gt 0) { $charSet += $uCharSet }
    if($lower -gt 0) { $charSet += $lCharSet }
    if($numeric -gt 0) { $charSet += $nCharSet }
    if($special -gt 0) { $charSet += $sCharSet }
    
    $charSet = $charSet.ToCharArray()
    $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $bytes = New-Object byte[]($length)
    $rng.GetBytes($bytes)
 
    $result = New-Object char[]($length)
    for ($i = 0 ; $i -lt $length ; $i++) {
        $result[$i] = $charSet[$bytes[$i] % $charSet.Length]
    }
    $password = (-join $result)
    $valid = $true
    if($upper   -gt ($password.ToCharArray() | Where-Object {$_ -cin $uCharSet.ToCharArray() }).Count) { $valid = $false }
    if($lower   -gt ($password.ToCharArray() | Where-Object {$_ -cin $lCharSet.ToCharArray() }).Count) { $valid = $false }
    if($numeric -gt ($password.ToCharArray() | Where-Object {$_ -cin $nCharSet.ToCharArray() }).Count) { $valid = $false }
    if($special -gt ($password.ToCharArray() | Where-Object {$_ -cin $sCharSet.ToCharArray() }).Count) { $valid = $false }
 
    if(!$valid) {
         $password = Get-RandomPassword $length $upper $lower $numeric $special
    }
    return $password
}

function o365_sync{
$changes= @()
# Create missing users
foreach ($o365User in $global:o365users){

    if (($o365user.employeeId) -and $o365user.AccountEnabled){
    $o365result = $null
    $o365result = $global:snipe_users.rows | Where-Object -Property employee_num -eq $o365User.employeeId
    if (-Not $o365result){
        # $minLength = 5 ## characters
        # $maxLength = 10 ## characters
        # $length = Get-Random -Minimum $minLength -Maximum $maxLength
        # $nonAlphaChars = 5
        $password = Get-RandomPassword 8
        $o365hashtable = @{
            first_name = $o365user.GivenName;
            activated = $o365user.AccountEnabled;
            last_name = $o365user.Surname;
            username=$o365user.UserPrincipalName;
            email=$o365user.UserPrincipalName;
            password=$password;
            password_confirmation=$password;
            employee_num=$o365user.employeeId;
            jobtitle=$o365user.JobTitle;
            groups= $null}
            $o365body = $o365hashtable | ConvertTo-Json -Depth 4
        $o365response = create_snipe_user $global:snipe_api $o365body
        $outputhashtable = @{snipe_id = "New"; o365_user = $o365user.DisplayName; FirstName = $o365user.GivenName; LastName=$o365user.Surname; Username=$o365user.UserPrincipalName;Email=$o365user.UserPrincipalName;Title=$o365user.JobTitle;activated=$o365user.AccountEnabled;updated=""}
        $outputhashtable['updated'] = $o365response.status
        $changes += [pscustomobject]$outputhashtable
    }
    Clear-Variable o365result
    }
}
# Update existing users
#users you want to exclude from sync, like admin accounts
$ignored_emails = @("service@snipe-it.io","{EMAIL}")
foreach ($user in $global:snipe_users.rows)
{
    $result = $null
    if (($ignored_emails.Contains($user.email)) -or ($null -eq $user.employee_num)){
        continue
    }
    $result = $global:o365users | Where-Object -Property employeeId -eq $user.employee_num
    if ($result) { 
        if ($null -eq $result.EmployeeId){
            continue
        }
        $global:match = $True
        $matched_location = $null
        $decoded_first = decode_html($user.first_name)
        $decoded_last =  decode_html($user.last_name)
        $decoded_title = decode_html($user.jobtitle)
        $encoded_first = encode_html($result.GivenName)
        $encoded_last = encode_html($result.Surname)
        $encoded_title = encode_html($result.JobTitle)
        $matched_location = $global:snipe_locations | Where-Object -Property name -eq $result.OfficeLocation
        $matched_dept = $global:snipe_departments  | Where-Object -Property name -eq $result.department
        if ($result.AccountEnabled){
            $actived = "true"
        }
        else{
            $actived = "false"
        }
        $hashtable = @{snipe_id = $user.id; o365_user = $result.DisplayName; FirstName = "n\a"; LastName="n\a"; Username="n\a";Email="n\a";Title="n\a";activated="n\a";updated=""}
            $body = "{
            `n     `"first_name`": `"$($result.GivenName)`",
            `n     `"activated`": $($actived),
            `n     `"last_name`": `"$($result.Surname)`",
            `n     `"username`": `"$($result.UserPrincipalName)`",
            `n     `"jobtitle`": `"$($result.JobTitle)`",
            `n     `"email`": `"$($result.UserPrincipalName)`",
            `n     `"location_id`": `"$($matched_location.id)`",
            `n     `"department_id`": `"$($matched_dept.id)`"
            `n}"
            switch ( $true )
            {
                ($result.GivenName -ne $decoded_first)
                {
                    $hashtable['FirstName'] = $encoded_first
                }
                ($result.Surname -ne $decoded_last)
                {
                    $hashtable['LastName'] = $encoded_last
                }
                ($user.username -ne $result.UserPrincipalName)
                {
                    $hashtable['Username'] = $result.UserPrincipalName
                }
                ($user.email -ne $result.UserPrincipalName)
                {
                    $hashtable['Email'] = $result.UserPrincipalName
                }
                ($result.JobTitle -ne $decoded_title)
                {
                    $hashtable['Title'] = $encoded_title
                }
                ($result.AccountEnabled -ne $user.activated)
                {
                    $hashtable['activated'] = $actived
                }
                (( $matched_location.id -ne $user.location.id) -and ($null -ne $matched_location))
                {
                    $hashtable['location_id'] = $matched_location.id
                }
                (( $matched_dept.id -ne $user.department.id) -and ($null -ne $matched_dept))
                {
                    $hashtable['department_id'] = $matched_dept.id
                }
                default 
                {
                    $global:match = $False
                }
            }
            if ($global:match -ne $False){
            if (($result.AccountEnabled -eq $False) -and ($user.assets_count -eq 0)){
                $delete_response = delete_snipe_user $global:snipe_api $user.id
                $hashtable['activated'] = "DELETED" +$delete_response.status + $delete_response.messages
                $changes += [pscustomobject]$hashtable
                continue
            }
            $status = update_snipe_user $global:snipe_api $body $user.id
            $hashtable['updated'] = $status.status
            $changes += [pscustomobject]$hashtable
            Clear-Variable result
            }
        
    }

}
$changes | Format-Table
}

<# gets all snipe locations #>
function get_snipe_locations($api){
    $headers=@{}
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", "Bearer $api" )
    $response = Invoke-WebRequest -Uri '{DOMAIN}/api/v1/locations?limit=50&offset=0&sort=created_at' -Method GET -Headers $headers -UseBasicParsing
    $response = $response | ConvertFrom-Json
    return $response.rows
}

<# creates snipe location #>
function create_snipe_location($hashtable, $api){
    $body = $hashtable | ConvertTo-Json
    $headers=@{}
    $headers.Add("accept", "application/json")
    $headers.Add("Authorization", "Bearer $api" )
    $headers.Add("content-type", "application/json")
    $response = Invoke-WebRequest -Uri '{DOMAIN}/api/v1/locations' -Method POST -Headers $headers -ContentType 'application/json' -Body $body -UseBasicParsing
    return $response
}

<# updates snipe location#>
function update_snipe_location($hashtable, $id, $api){
    $body = $hashtable | ConvertTo-Json
    $headers=@{}
    $headers.Add("accept", "application/json")
    $headers.Add("Authorization", "Bearer $api" )
    $headers.Add("content-type", "application/json")
    $response = Invoke-WebRequest -Uri "{DOMAIN}/api/v1/locations/$id" -Method PUT -Headers $headers -ContentType 'application/json' -Body $body -UseBasicParsing
    return $response
}

<# Makes / Updates missing locations#>
function check_branches(){
    $changes = @()
    foreach ($branch in $branch_info)
    {
        $result = $null
        $result = $global:snipe_locations | Where-Object -Property name -eq $branch.name
        if ($result){
            $global:match = $true
            $decoded_address = decode_html($branch.Street)
            $hashtable = @{matched_name = $branch.name}
            switch ( $true )
            {
                ($result.address -ne $decoded_address)
                {
                    $hashtable['address'] = encode_html($branch.Street)
                }
                ($result.state -ne $branch.State)
                {
                    $hashtable['state'] = $branch.State
                }
                ($result.zip -ne $branch.Zip)
                {
                    $hashtable['zip'] = $branch.Zip
                }
                ($result.city -ne $branch.City)
                {
                    $hashtable['city'] = $branch.City
                }
                default 
                {
                    $global:match = $False
                }
            }
            if ($hashtable.Count -gt 1){
                $hashtable['update'] = $branch.name
                $hashtable['update'] = "updated"
                $status = update_snipe_location $hashtable $result.id $global:snipe_api
                $hashtable['status'] = $status.StatusDescription
                $changes += [pscustomobject]$hashtable
            }
        }
        else{
            $hashtable = @{matched_name = $branch.name}
            $hashtable = @{name = $branch.Name; address = $branch.Street; state = $branch.State; country=$branch.Country; zip=$branch.Zip; city=$branch.City}
            $hashtable['update'] = "Created"
            $status = create_snipe_location $hashtable $global:snipe_api
            $hashtable['status'] = $status.StatusDescription
            $changes += [pscustomobject]$hashtable
            
        }
    }
    return $changes
    }

    
<# gets all snipe departments #>
function get_snipe_departments($api){
    $headers=@{}
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", "Bearer $api" )
    $response = Invoke-WebRequest -Uri '{DOMAIN}/api/v1/departments?limit=50&offset=0&sort=created_at' -Method GET -Headers $headers -UseBasicParsing
    $response = $response | ConvertFrom-Json
    return $response.rows
}

<# creates snipe department #>
function create_snipe_departments($hashtable, $api){
    $body = $hashtable | ConvertTo-Json
    $headers=@{}
    $headers.Add("accept", "application/json")
    $headers.Add("Authorization", "Bearer $api" )
    $headers.Add("content-type", "application/json")
    $response = Invoke-WebRequest -Uri '{DOMAIN}/api/v1/departments' -Method POST -Headers $headers -ContentType 'application/json' -Body $body -UseBasicParsing
    return $response
}

<# checks for missing departments #>
function check_snipe_departments(){
    $changes = @()
    foreach ($department in $department_info){
        $result = $snipe_departments | Where-Object -Property name -eq $department.name
        if (-Not $result){
            $hashtable = @{name=$department.Name;created="true"}
            $body = @{name=$department.Name}
            $response = create_snipe_departments $body $global:snipe_api
            $hashtable['status'] = $response.StatusDescription
            $changes += [pscustomobject]$hashtable
        }
    }
    return $changes
}

# Variables
Write-Output "Setting Variables"
$global:snipe_users = $null
$global:o365users=  $null
$global:snipe_locations = $null
Write-Output "Getting o365 users"
$global:o365users= Get-MgUser -All
Write-Output "Done found $($global:o365users.Count) users"
Write-output "Getting Snipe Users"
get-snipe-users $global:snipe_api
Write-output "Done found $($global:snipe_api.Count) users"
Write-Output "Getting Snipe locations"
$global:snipe_locations = get_snipe_locations $global:snipe_api
Write-Output "Done found $($global:snipe_locations.Count) locations"
Write-Output "Checking Branches"
$output = check_branches
Write-Output $output | Format-Table
Write-Output "Checking Snipe Departments"
$global:snipe_departments = get_snipe_departments $global:snipe_api
Write-Output "Done found $($global:snipe_departments.Count) departments"
Write-Output "Checking Departments"
$output = check_snipe_departments
Write-Output $output | Format-Table
Write-Output "Checking users"
$output = o365_sync
Write-Output $output | Format-Table


