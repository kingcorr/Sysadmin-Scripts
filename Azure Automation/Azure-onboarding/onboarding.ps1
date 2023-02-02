Param
(
	[Parameter (Mandatory = $true)]
	[String] $First_name,

	[Parameter (Mandatory = $true)]
	[String] $Last_name,

	[Parameter (Mandatory = $true)]
	[String] $Display_name,

	[Parameter (Mandatory = $true)]
	[String] $Title,

	[Parameter (Mandatory = $true)]
	[String] $Department,

	[Parameter (Mandatory = $true)]
	[String] $Branch,

	[Parameter (Mandatory = $true)]
	[String] $Email_Prefix,

	[Parameter (Mandatory = $true)]
	[String] $Hidden,

	[Parameter (Mandatory = $true)]
	[String] $groups

)

# Set variables


# Get JSON files

$StorageAccountKey = Get-AutomationVariable -Name Storage_account_key
$Context = New-AzureStorageContext -StorageAccountName '{}' -StorageAccountKey $StorageAccountKey
Get-AzureStorageFileContent -ShareName '{}' -Context $Context -path 'branch_info.json' -Destination 'C:\Temp'
Get-AzureStorageFileContent -ShareName '{}' -Context $Context -path 'department_info.json' -Destination 'C:\Temp'
$branch_info = Get-Content "C:\Temp\branch_info.json" | ConvertFrom-Json
$department_info = Get-Content "C:\Temp\department_info.json" | ConvertFrom-Json
	
# Connect to MsGraph

Connect-AzAccount -Identity
$token = (Get-AzAccessToken -ResourceTypeName MSGraph).token # Get-PnPAccessToken if you are already connected to Sharepoint
Connect-MgGraph -AccessToken $token

# Get Graph Data

Write-Output "Getting users"
$global:o365users= Get-MgUser -All
Write-Output "Getting groups"
$global:o365groups = Get-MgGroup -All



# Connect to Exchange

$tenantDomain = "intercaplending.com" # Domain of the tenant the managed identity belongs to
function makeMSIOAuthCred () {
	$accessToken = Get-AzAccessToken -ResourceUrl "https://outlook.office365.com/"
	$authorization = "Bearer {0}" -f $accessToken.Token
	$Password = ConvertTo-SecureString -AsPlainText $authorization -Force
	$tenantID = (Get-AzTenant).Id
	$MSIcred = New-Object System.Management.Automation.PSCredential -ArgumentList ("OAuthUser@$tenantID", $Password)
	return $MSICred
}

function connectEXOAsMSI ($OAuthCredential) {
	#Function to connect to Exchange Online using OAuth credentials from the MSI
	$psSessions = Get-PSSession | Select-Object -Property State, Name
	If (((@($psSessions) -like '@{State=Opened; Name=RunSpace*').Count -gt 0) -ne $true) {
		Write-Verbose "Creating new EXOPSSession..." -Verbose
		try {
			$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/PowerShell-LiveId?BasicAuthToOAuthConversion=true&email=SystemMailbox%7bbb558c35-97f1-4cb9-8ff7-d53741dc928c%7d%40$tenantDomain" -Credential $OAuthCredential -Authentication Basic -AllowRedirection
			$null = Import-PSSession $Session -DisableNameChecking -CommandName * -AllowClobber
			Write-Verbose "New EXOPSSession established!" -Verbose
		} catch {
			Write-Error $_
		}
	} else {
		Write-Verbose "Found existing EXOPSSession! Skipping connection." -Verbose
	}
}

$null = Connect-AzAccount -Identity
# connect using Managed Identity (but using basic auth!)
connectEXOAsMSI -OAuthCredential (makeMSIOAuthCred)



<# 
============
BEGIN SCRIPT 
============
#>


function verify_mailbox($upn){
    $success = $false
	$startDate = Get-Date
	# Check for give minutes max
    while (-not $success -and $startDate.AddMinutes(5) -gt (Get-Date)) {
        try{
            $success = Get-Mailbox $upn
            Start-Sleep 5
        }
        Catch [ManagementObjectNotFoundException]{
            $attempt += 1
        }
    }
    return $success
}



function add_o365_group($user_id,$group_email){
    $user_id = $user['user_id']
    $current_group =  $global:o365groups | Where-Object -Property Mail -eq $group_email
    $params = @{
	    "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$user_id"
    }
    $params
    return New-MgGroupMemberByRef -GroupId $current_group.Id -BodyParameter $params

}

function assign_license($skuid,$user_id){
    $added_licenses = @()
    $params = @{
	    AddLicenses = @(
		    @{
			    DisabledPlans = @()
			    SkuId = $skuid
		    }
	    )
	    RemoveLicenses = @()
    }

    # A UPN can also be used as -UserId.
    $user = Set-MgUserLicense -UserId $user_id -BodyParameter $params
    foreach ($license in $user.AssignedLicenses){
        $added_licenses += $license.SkuId
    }
    return $added_licenses
}

function get_groups($user,$groups){
    $branch = $branch_info | Where-Object -Property Name -eq $user["Branch"]
    $adding_emails = @()
    foreach ($email in $branch.Emails){
        $adding_emails += $email
    }
	$groupsArray =$groups.Split(",")
	foreach ($selection in $groupsArray){
		$department = $department_info | Where-Object -Property Name -eq $selection
		foreach ($email in $department.required_groups){
		#Write-Host $email
		if ($email.Requirement -eq "Default"){
		$adding_emails += $email.Email
		}
		elseif(($email.Requirement -eq "State") -and $user["State"] -eq $email.State){
		$adding_emails += $email.Email
		}
		elseif(($email.Requirement -eq "Branch") -and $user["Branch"] -eq $email.Branch){
		$adding_emails += $email.Email
		}
	}
	}

    
    foreach ($email in $adding_emails){
        $current_group = $global:o365groups | Where-Object -Property Mail -eq $email
        if ($current_group){
        # Check if email is o365 group
        if ($current_group.GroupTypes -eq "Unified"){
        $added_group = add_o365_group $user["user_id"] $email 
        continue
        }
        # Condition on DL
        else{
        $added_dl = Add-DistributionGroupMember -Identity $email -Member $user["Email"] -ErrorAction SilentlyContinue
        continue
        }
        }
        else{
        # Condition on Shared Mailbox
        $added_smb = Add-MailboxPermission -Identity $email -User $user["Email"] -AccessRights FullAccess -InheritanceType All
        }
    }
    
    return $adding_emails

}

function make_user($first,$last,$display,$title,$department,$branch,$email_prefix,$groups){
    #licenses 
    $AAD_Premium_sku = "078d2b04-f1bd-4111-bbd4-b4b1b354cef4"
    $ENTERPRISEPACK = "6fd2c87f-b296-42f0-b197-1e91e994b900"

    $branch = $branch_info | Where-Object -Property Name -eq $branch
    $PasswordProfile = @{
      Password = 'SuperSecurePassword1!'
      }
    $user_info = @{
    "First_Name" = $first;
    "Last_Name" = $last;
    "Display_Name" = $display;
    "Department" = $department;
    "Branch" = $branch.Name;
    "Title" = $title
    "MailNickName" = $email_prefix;
    "Email" =$email_prefix+"{DOMAIN}"
    "address"= $branch.Street;
    "City"= $branch.City;
    "State" = $branch.State;
    "Zip" = $branch.Zip;
    "Country" = $branch.Country;
    "Password" = $PasswordProfile;
    "user_id" = $null;
    "added_groups" = $null;
    "added_licenses" = $null
    }
    
    # Create User
	#-EmployeeId $user_info["EmployeeNum"]
    Write-Output "Creating User"
    $created_user = New-MgUser -DisplayName $user_info["Display_Name"] -GivenName $user_info["First_Name"] -Surname $user_info["Last_Name"] -PasswordProfile $user_info["Password"] -AccountEnabled -MailNickName $user_info["MailNickName"] -UserPrincipalName $user_info["Email"] -OfficeLocation $user_info["Branch"] -City $user_info["City"] -State $user_info["State"] -StreetAddress $user_info["address"] -PostalCode $user_info["Zip"] -Department $user_info["Department"] -JobTitle $user_info["Title"] -Country $user_info["Country"] -UsageLocation "US"
    Start-Sleep 20 # Waiting for user to be created
    $user_info["user_id"] = $created_user.Id
    Write-Output "Created user " $created_user.Id

    # Assign Licenses
    Write-Output "Assigning Licenses"
    assign_license $ENTERPRISEPACK $user_info["user_id"]
    assign_license $AAD_Premium_sku $user_info["user_id"]
    #Start-Sleep 60 # Needs to wait for licenses

    $Measure = Measure-Command {verify_mailbox $user_info["Email"] -ErrorAction SilentlyContinue}
    Write-Output "Found mailbox after "$measure.Minutes " minutes"
    # Add groups
    Write-Output "Adding Groups"
    $user_info["added_groups"] = get_groups $user_info $groups
	if ($Hidden -eq "True"){
		Write-Output "Hiding Mailbox"
		Set-Mailbox -HiddenFromAddressListsEnabled $true -Identity $user_info["Email"]
	}
    return [pscustomobject]$user_info

}

# Write outputs

Write-Output $First_name
Write-Output $Last_name
Write-Output $Display_name
Write-Output $Title
Write-Output $Department
Write-Output $Branch
Write-Output $Email_Prefix
Write-Output $Hidden
Write-Output $groups

make_user $First_name $Last_name $Display_name $Title $Department $Branch $Email_Prefix $groups



Get-PSSession | Remove-PSSession

<# END SCRIPT #>

	
