
$groups = Get-MsolGroup -all
$errorReport = ""

foreach ($group in ($groups)){
$currentGroup = Get-MsolGroupMember -all -GroupObjectId $Group.ObjectId


 foreach ($item in ($currentGroup))
  {if ($item.DisplayName -match "SMB"){
try{
 Write-Host "Removing " $item.DisplayName " from " $group.DisplayName
 Remove-AzureADGroupMember -ObjectId $group.ObjectID  -MemberId $item.ObjectID
 }
 catch{
 $errorReport += "Unable to Remove "+$item.DisplayName+" from "+$group.DisplayName+"`r`n"
 }
 }
}

}
Write-Host $errorReport
