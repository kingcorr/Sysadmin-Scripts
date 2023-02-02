Set-ExecutionPolicy RemoteSigned
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -UserPrincipalName {EMAIL}
$measure = $null
$measure = Measure-Command {$mailboxes = Get-Mailbox -resultsize unlimited -RecipientTypeDetails UserMailbox | Get-MailboxPermission | Select Identity, User, Deny, AccessRights, IsInherited| Where {($_.user -ne "NT AUTHORITY\SELF")}}
$report= @() 
$mailboxes | Foreach-Object {
#    $access_rights
#    foreach ($rights in $_.AccessRights){
#        $access_rights+=(" "+$rights)
#    }
    $hashtable = @{user= $_.User; Identity=$_.Identity;Deny=$_.Deny;Access=$_.AccessRights}
    $report += [pscustomobject]$hashtable


}
$report | Format-Table


$measure = Measure-Command {$mailboxes}
$time = "Report ran in "+$measure.Hours+":"+$measure.Minutes+":"+$measure.Seconds



