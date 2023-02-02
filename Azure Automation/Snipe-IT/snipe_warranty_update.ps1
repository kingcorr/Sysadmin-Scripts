<#
    This tool will update Snipe-IT with warranty info from Dell's API
    You may need to request a new API key every year from Dell's TechDirect API 

    -Ryan Fannon 8-30-22
#>
 $VerbosePreference = "Continue"
# variables
$dell_api_key = Get-AutomationVariable -Name dell_api_key
$dell_api_secret = Get-AutomationVariable -Name dell_api_secret
$snipe_api = Get-AutomationVariable -Name snipe_api


#gets bearer token from api client and secret
function get_dell_bearer ($client_id, $client_secret){
    Write-Verbose "Getting Dell bearer token" 
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", "application/x-www-form-urlencoded")

    $body = "client_id=$($client_id)&client_secret=$($client_secret)&grant_type=client_credentials"

    $response = Invoke-RestMethod 'https://apigtwb2c.us.dell.com/auth/oauth/v2/token' -Method 'POST' -Headers $headers -Body $body
    return $response
}



# gets difference in months between two days
function get_months($start,$stop){
    $start = Get-Date $start
    $stop = Get-Date $stop
    $daydiff = New-TimeSpan -Start $start -End $stop
    
    $yeardiff = $stop.year - $start.year
    If($yeardiff -gt 0 -And $start.month -gt $stop.month  -And $start.day -gt $stop.day) { 
        $yeardiff = $yeardiff -1 
    }
    
    $monthdiff = $stop.month - $start.month + ($yeardiff * 12)
    If($start.day -gt $stop.day) { $monthdiff = $monthdiff -1 }
    return $monthdiff
}



# updates an asset's warranty info
function update_asset($token, $id, $months, $date){
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", "Bearer")
    $headers.Add("Content-Type", "application/json")
    $body = "{
    `n    `"purchase_date`": `"$($date)`",
    `n    `"warranty_months`": $($months)
    `n}"
    $response = Invoke-RestMethod "{DOMAIN}/api/v1/hardware/$($id)" -Method 'PUT' -Headers $headers -Body $body
    return $response
}



# Gets all Dell snipe hardware (1000 limit)
function snipe_hardware($api){
    Write-Verbose "Getting Snipe-IT asset list" 

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Accept", "application/json")
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Authorization", "Bearer $($api)")
    $headers.Add("Cookie", "intercaplending_snipeitv6_session=fUUnKC1x6sG8ux57Cyb61jV11M7YJ0spy1vgU9k3")
    $response = Invoke-RestMethod '{DOMAIN}/api/v1/hardware?limit=1000&manufacturer_id=1' -Method 'GET' -Headers $headers
    return $response
}



# Gets warranty info from dell (100 limit)
function get_warranty($asset){
    Write-Verbose "Getting Dell Warranty info" 
    $bearer = get_dell_bearer $dell_api_key $dell_api_secret
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Bearer $($bearer.access_token)")
    $response = Invoke-RestMethod "https://apigtwb2c.us.dell.com/PROD/sbil/eapi/v5/asset-entitlements?servicetags=$($asset)" -Method 'GET' -Headers $headers
    $response 
}


#Get tags 
#only returns assets that can be matched wil dell api
function get_snipe_tags{
    Write-Verbose "Getting matching assets" 
    $tags = @()
    foreach ($asset in $hardware_list.rows){
        #Ignores assets with a purchase date 
        if (($asset.purchase_date | measure).Count -lt 1 -and $asset.serial -gt 0)
        {
        $tags += ,$asset.serial
        }
    }
    return $tags
}



# Takes all tags and splits them into chunks of 100 and calls update
function update_warranty_info($tags){
    $count = $tags.Count
    Write-Verbose "Updating warranty info for $($count) tags" 
    $Items = for($i = 0; $i -lt $limit+1; $i++) {
        $warranty_list = $null
        if ($i -eq 0){
        $start = 0
        $stop = 99
        }
        else{
        $start = ((100 * ($i))-1)
        $stop = ((100 * ($i+1))-2)
        }
        $split = $tags[$start..$stop]
        $split_tags = $split -join ","
        $warranty_list = get_warranty $split_tags
        update_asset_chunk $warranty_list
    }
}



#update chunk of assets
function update_asset_chunk($list){
    Write-Verbose "updating chunk" 
    foreach ($result in $list){
        $warranty = $null
        $warranty =  $result.entitlements | Where-Object -Property serviceLevelCode -eq "CC"
        if (!$warranty){$warranty = $result.entitlements | Where-Object -Property serviceLevelCode -eq "TS"}
        #Set extended warranty
        if (($warranty | Measure-Object).Count -gt 1) {
         $warranty = $warranty | Where-Object -Property entitlementType -eq "EXTENDED"
        }
        if ($warranty){
            $matched = $hardware_list.rows | Where-Object -Property serial -eq $result.serviceTag
            $months = get_months $result.shipDate $warranty.endDate
            Write-Verbose "updating asset $($matched.id) tag: $($matched.serial)" 
            $update = update_asset $snipe_api $matched.id $months $result.shipDate
            if ($update.status -eq "error"){
                Write-Verbose $update.status $update.messages 
            }
            else{
                Write-Verbose $update.status 
            }
        }
    }
}

# Run
$hardware_list = snipe_hardware $snipe_api
$tags = get_snipe_tags
update_warranty_info $tags

