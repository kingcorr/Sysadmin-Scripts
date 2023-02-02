## Login
``` powershell
Install-Module -Name ExchangeOnlineManagement
"Import-Module ExchangeOnlineManagement"
Set-ExecutionPolicy RemoteSigned
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -UserPrincipalName {email}
Connect-IPPSSession -UserPrincipalName {email}
```
## Delete emails from compliance search
``` powershell
New-ComplianceSearchAction -SearchName "10-29 Phish Attempt" -Purge -PurgeType SoftDelete
```
## Convert to shared mailbox
``` powershell
Set-Mailbox -Identity FinalDocs -Type Shared
```
## Grant delagate access to calendar
``` powershell
Add-MailboxFolderPermission -Identity {email}:\Calendar -User vblackmer@intercaplending.com -AccessRights Editor -SharingPermissionFlags Delegate
```
## Hide all shared mailboxes
``` powershell
Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize:Unlimited | ForEach-Object {Set-Mailbox -Identity "$($_.alias){domain}" -HiddenFromAddressListsEnabled $true}
```
## Show all non-hidden shared mailboxes
``` powershell
Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize:Unlimited | ForEach-Object {Get-AzureADUser -ObjectId "$($_.alias){domain}" | select UserPrincipalName, ShowInAddressList |Where {$_.ShowInAddressList -eq $Null}}
```
## Get inbox rules
``` powershell
Get-InboxRule -Mailbox (user)
```
## Remove Inbox rules
``` powershell
Remove-InboxRule -Mailbox (mailboxame) -Identity (rule identity)
```
