# This script will allow you to setup an admin poliy on Chrome via registry edits
# Computer will need to be domain managed in some way, AzureAD/local

#paths for chrome policy keys used in the scripts
$policyexists = Test-Path HKLM:\SOFTWARE\Policies\Google\Chrome
$policyexistshome = Test-Path HKLM:\SOFTWARE\Policies\Google\Chrome\RestoreOnStartupURLs

# Set Homepage
$regKeysetup = "HKLM:\SOFTWARE\Policies\Google\Chrome"
$regKeyhome = "HKLM:\SOFTWARE\Policies\Google\Chrome\RestoreOnStartupURLs"
$url = "{HOMEPAGE_URL}" #setup policy dirs in registry if needed and set pwd manager

#else sets them to the correct values if they exist
if ($policyexists -eq $false){
New-Item -path HKLM:\SOFTWARE\Policies\Google
New-Item -path HKLM:\SOFTWARE\Policies\Google\Chrome
New-ItemProperty -path $regKeysetup -Name PasswordManagerEnabled -PropertyType DWord -Value 0
New-ItemProperty -path $regKeysetup -Name RestoreOnStartup -PropertyType Dword -Value 4
New-ItemProperty -path $regKeysetup -Name HomepageLocation -PropertyType String -Value $url
New-ItemProperty -path $regKeysetup -Name HomepageIsNewTabPage -PropertyType DWord -Value 0
} Else {
Set-ItemProperty -Path $regKeysetup -Name PasswordManagerEnabled -Value 0
Set-ItemProperty -Path $regKeysetup -Name RestoreOnStartup -Value 4
Set-ItemProperty -Path $regKeysetup -Name HomepageLocation -Value $url
Set-ItemProperty -Path $regKeysetup -Name HomepageIsNewTabPage -Value 0
} #This entry requires a subfolder in the registry
#For more then one page create another new-item and set-item line with the name -2 and the new url
if ($policyexistshome -eq $false){
New-Item -path HKLM:\SOFTWARE\Policies\Google\Chrome\RestoreOnStartupURLs
New-ItemProperty -path $regKeyhome -Name 1 -PropertyType String -Value $url
}
Else {
Set-ItemProperty -Path $regKeyhome -Name 1 -Value $url
} New-ItemProperty -path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name PasswordManagerEnabled -PropertyType DWord -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name PasswordManagerEnabled -Value 1
