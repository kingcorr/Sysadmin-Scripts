# Variables
$zendesk_api = Get-AutomationVariable -Name zendesk_api_bearer
$snipe_api = Get-AutomationVariable -Name snipe_api
function get_snipe_assets(){
    $check = $false
    $assetlist = @()
    $offset_number = 0
    $offset = ""
    while ($check -ne $true){
        $headers=@{}
        $headers.Add("accept", "application/json")
        $headers.Add("Authorization", "Bearer $($snipe_api)")
        $response = Invoke-WebRequest -Uri "{SNIPE_DOMAIN}/api/v1/hardware?limit=100$offset&sort=created_at&order=desc" -Method GET -Headers $headers -UseBasicParsing
        $response = $response.Content | ConvertFrom-Json
        $total = $response.total
        $count = $assetlist.Count
        Write-Host "($count/$total)"
        foreach ($asset in $response.rows){
            $assetlist += $asset
        }
        $offset_number = $offset_number + 100
        $offset = "&offset=$offset_number"
        if ($offset_number -gt ($total + 100)){
            $check = $true
        }
    }
    return $assetlist
    
}

#Retrieve all Zendesk Users
function get_zendesk_users(){
$zendesk_users = @()
$page = "{SNIPE_DOMAIN}/api/v2/users.json?page=1"
DO
{
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Basic $zendesk_api")

$response = Invoke-RestMethod "$page" -Method 'GET' -Headers $headers -UseBasicParsing
$response = $response 
foreach ($user in $response.users){
    $zendesk_users += $user

}
$page = $response.next_page
} While ($null -ne $page)
return $zendesk_users
}


# Matches snipe assets to zendesk users
function matchAssets(){
$zendesk = get_zendesk_users
$snipe_assets = get_snipe_assets
$report = @()
foreach ($user in $zendesk){
    $matched = $snipe_assets | Where-Object { $_.assigned_to.employee_number -eq $user.user_fields.employee_id}
    $newTags = @()
    $tags = @()
    $snipeIdentified = @()
    $upToDate = $false
    $zendeskID = $user.id
    if ($null -ne $user.user_fields.employee_id){
    $matched = $snipe_assets | Where-Object { $_.assigned_to.employee_number -eq $user.user_fields.employee_id}
    if ($null -ne $matched){
        foreach ($device in $matched){
        $category = $device.category.name.ToLower()
        $assetTag = $device.asset_tag
        $zendeskTag = "$category-$assetTag"
        if (-Not ($category -eq 'tablet')){
            $newTags += $zendeskTag
        }
        $employee = $device.assigned_to.name
        $displayName = $user.name 
        $snipeID = $device.assigned_to.id
        $tags = $user.tags
    }
    $snipeIdentified = $tags | Where-Object {($_ -like "*laptop*") -or ($_ -like "*desktop*")}
    foreach ($tag in $tags){
        if ($null -ne $snipeIdentified){
        if (-Not $snipeIdentified.Contains($tag))
        {
            $newTags += $tag
        }
    }
    else {
        $newTags += $tag
    }
    }
    $compare = Compare-Object $tags $newTags
    if ($null -eq $compare){
        $upToDate = $true
    }
    else{
        $upToDate = $false
    }
    $outputhashtable = @{SnipeUser = $employee; ZendeskUser=$displayName; OldTags = $tags;NewTags = $newTags; ZendeskID = $zendeskID; UpToDate = $upToDate; snipeID = $snipeID}
    $report += [pscustomobject]$outputhashtable
    }  
    
    } 
}
return $report
}



function addTags ($userID , $tagsArray){
$jsonBody = @"
{
    "user": {
        "tags": []
    }
}
"@
$jsonBody = $jsonBody  | ConvertFrom-Json
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Basic $zendesk_api")
$headers.Add("Content-Type", "application/json")
$jsonBody.user.tags = $tagsArray
$body = $jsonBody | ConvertTo-Json
$response = Invoke-RestMethod "{SNIPE_DOMAIN}/api/v2/users/$userID" -Method 'PUT' -Headers $headers -Body $body -UseBasicParsing
}


Write-Output "Starting"
$changes = matchAssets
foreach ($user in $changes){
    if ($user.UpToDate -eq "True"){
        continue 
    }
    else{
    $tags = $user.NewTags
    Write-Output "Updating $($user.SnipeUser) to $($tags)"
    addTags $user.ZendeskID $tags
    }
    Start-Sleep .5
}
