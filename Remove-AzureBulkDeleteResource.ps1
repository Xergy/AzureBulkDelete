
$VerbosePreference =  "SilentlyContinue"

$SubSelection = Get-AzureRmSubscription | Out-GridView -Title "Select a Subscription" -OutputMode Single


Set-AzureRmContext -Subscription $SubSelection


$RGSelection = Get-AzureRmResourceGroup  | Out-GridView -Title "Select Resouce Group" -OutputMode Single

$ResourceSelection =  Get-AzureRmResource -ResourceGroupName $RGSelection.ResourceGroupName  | Out-GridView -Title "Select Resources to Remove" -OutputMode Multiple

$VerbosePreference = "continue"

$ManagedResourceTypes = @(
    "Microsoft.Compute/virtualMachines"
    "Microsoft.Compute/virtualMachines/extensions"
    "Microsoft.Compute/availabilitySets"
    "Microsoft.Network/networkInterfaces"
    "Microsoft.Network/publicIPAddresses"
    "Microsoft.Network/networkSecurityGroups"
    "Microsoft.Compute/disks"
    "Microsoft.Storage/storageAccounts"
    "Microsoft.Network/virtualNetworks"
)

$ResourcesToRemove = $ResourceSelection

foreach ($ManagedResourceType in $ManagedResourceTypes) {
    Write-Verbose "Processing Resource Type $($ManagedResourcetype)"

    $ResourcesToRemove |
        Where-Object { $_.Resourcetype -eq $ManagedResourceType} |
        ForEach-Object {
            Write-Verbose "Deleting $($_.Name)"
            $_ } |
        Remove-AzureRmResource -Force
    
    $ResourcesToRemove = $ResourcesToRemove | Where-Object { $_.Resourcetype -ne $ManagedResourceType}

}

Write-Verbose "Processing the rest"
$ResourcesToRemove | 
    ForEach-Object {
        Write-Verbose "Deleting $($_.Name)"
        $_ |
        Remove-AzureRmResource -Force   
    }
    


