## loop over csv
``` powershell
Import-CSV users.csv | Foreach-Object{
   Revoke-AzureADUserAllRefreshToken -ObjectId $_.UPN
   Write-Host "Revoking" $_.UPN
   Start-Sleep -s 1
}
```
