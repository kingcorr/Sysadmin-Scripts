## Looping over csv / Foreach-Object loop  

``` powershell
Import-CSV data.csv | Foreach-Object{
	task
}
```  

## For loop  

``` powershell
foreach ($item in $object){
	# Get value from item
	$item.property 
	
}
```  

## Reference variable inside string  

``` powershell
"$($variable)" 
```  

## If else  

``` powershell

if (condition){
	task
}
else{
	task
}
```  

## Object tipes  

| Type  | create | update |
| --- | --- | --- |
| array | `$array = @()` | `$arry +=$value` |
| string | `$string = ""` | `$string += "other string"`|
| hashtable |`$hashtable = @{property = value;}`|`$hashtable['property'] = value`  

## Find value in object by property   

``` powershell
$object | Where-Object -Property propertyname -like $match
```  

## Output data as table  

``` powershell
$data |  Format-Table
```  

## Function  

``` powershell
function functionName($inputVariable){
	task
	return $returned result
}
```  

## Call function  

``` powershell
functionName $inputVariable
```
