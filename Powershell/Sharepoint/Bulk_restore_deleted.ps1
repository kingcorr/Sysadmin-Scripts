Connect-PnPOnline https://{url}.sharepoint.com/sites/files/ -Interactive
$today = (Get-Date) 
$date1 = $today.date.addDays(0)
$date2 = $today.date.addDays(-4)
$items = Get-PnPRecycleBinItem | Where-Object { ($_.DeletedDate -gt $date2 -and $_.DeletedDate -lt $date1) -and ($_.DeletedByEmail -eq '{email of user that deleted}') }
$items = $items | Sort-Object -Property @{expression = ’ItemType’; descending = $true }, @{expression = “DirName”; descending = $false } , @{expression = “LeafName”; descending = $false }
$items.Count

($items[0..19003]) | ForEach-Object  -begin { $a = 0 } -Process { Write-Host "$a - $($_.LeafName)" ; $_ | Restore-PnPRecycleBinItem -Force ; $a++ }
