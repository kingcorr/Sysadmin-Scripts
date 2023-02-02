$newadminpass = ""

$ErrorActionPreference= 'silentlycontinue'
$admins = ([ADSI]"WinNT://./Administrators").psbase.Invoke('Members') | % {
 ([ADSI]$_).InvokeGet('AdsPath')
}

net user Admin $newadminpass /add
net user Admin $newadminpass
net localgroup administrators Admin /add

<# Remove all admins #>

foreach ($user in $admins) {
    if ($user -notmatch "Admin" -And $entry -notmatch "WHITELISTEDUSER"){
    net localgroup Administrators $user.Substring(8).replace('/','\') /delete
    }
}

$admins = ([ADSI]"WinNT://./Administrators").psbase.Invoke('Members') | % {
 ([ADSI]$_).InvokeGet('AdsPath')
}
foreach ($user in $admins) {
	Write-Host $user
    }
	
	
