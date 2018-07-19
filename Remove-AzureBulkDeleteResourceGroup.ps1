
$ResourceGroupsToRemove =  Get-AzureRmResourceGroup | Out-GridView -Title "Select Resource Groups to Remove"

$ResourceGroupsToRemove | Remove-AzureRmResourceGroup -Force




