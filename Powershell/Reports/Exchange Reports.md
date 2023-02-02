## List all shared mailboxes
``` powershell
Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize:Unlimited | Get-MailboxPermission |Select-Object Identity,User,AccessRights | Where-Object {($_.user -like '*@*')}|Export-Csv C:\Temp\sharedfolders.csv  -NoTypeInformation 
```
## Get user count
``` powershell
$mailboxes = Get-mailbox -ResultSize Unlimited
$users = Get-Mailbox -RecipientTypeDetails UserMailbox -ResultSize:Unlimited | select UserPrincipalName, DisplayName, Office | Where-Object {($_.Office -ne "App") -and ($_.Office -ne "N/A")}  | measure
$users.Count
```
## User level mail forwarding
``` powershell
foreach ($i in (Get-Mailbox -ResultSize unlimited)) { Get-InboxRule -Mailbox $i.DistinguishedName | where {$_.RedirectTo -or $_.ForwardTo -and -not ($_.description -match "If the message") } | fl MailboxOwnerId,Description >> rules.txt }
```
## Admin level mail forwarding
``` powershell
Get-Mailbox | select UserPrincipalName,ForwardingSmtpAddress,DeliverToMailboxAndForward | Export-csv c:\Office365Forwards.csv -NoTypeInformation
```
## Mailbox size report
``` powershell
Get-Mailbox -ResultSize Unlimited | Get-MailboxStatistics | Select DisplayName, ` @{name="TotalItemSize (MB)"; expres
sion={[math]::Round( ` ($_.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",","")/1MB),2)}}, ` ItemCount |
 Sort "TotalItemSize (MB)" -Descending | Export-CSV c:\mailboxsize.csv
```
## Last login date
``` powershell
(Get-Mailbox) | Foreach {Get-MailboxStatistics $_.Identity | Select DisplayName, LastLogonTime} | Export-CSV $Home\Desktop\LastLogonDate.csv
Remove-PSSession $Session
```
