
$VerbosePreference =  "SilentlyContinue"

$SubSelection = Get-AzureRmSubscription | Out-GridView -Title "Select a Subscription" -OutputMode Single

Set-AzureRmContext -Subscription $SubSelection

$RGSelection = Get-AzureRmResourceGroup  | Out-GridView -Title "Select Resource Group" -OutputMode Single

$ResourceSelection =  Get-AzureRmResource -ResourceGroupName $RGSelection.ResourceGroupName  | Out-GridView -Title "Select Resources to Remove" -OutputMode Multiple

$ResourceSelection =  $ResourceSelection | Out-GridView -Title "Re-Select Resources to Remove" -OutputMode Multiple

If ($ResourceSelection.Count -eq 0) {Break}

#$VerbosePreference = "continue"

Function BulkDeleteResource {
[CmdletBinding()]

Param(
    [Parameter(Mandatory=$True)]
    [object[]]$ResourcesToRemove,
    [Parameter(Mandatory=$False)]
    [switch]$BreakGlass = $False
    )

BEGIN {
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
    
    $VerbosePreference = "continue"

}

    PROCESS 
    {

        foreach ($ManagedResourceType in $ManagedResourceTypes)
        {
            Write-Verbose "Processing Resource Type $($ManagedResourcetype)"

            $ResourcesToRemove |
                Where-Object { $_.Resourcetype -eq $ManagedResourceType} |
                ForEach-Object {
                    Write-Verbose "Deleting $($_.Name)"
                    If ($BreakGlass -eq $True) 
                    {
                        $_ | Remove-AzureRmResource -Force 
                    } 
                        Else 
                        {
                            $_ | Remove-AzureRmResource -Force -WhatIf 
                        }
                }

            $ResourcesToRemove = $ResourcesToRemove | Where-Object { $_.Resourcetype -ne $ManagedResourceType}
        }

        If ($ResourcesToRemove.Count -gt 0)
        {
            Write-Verbose "Processing Resource Type OTHER"
            $ResourcesToRemove | 
                ForEach-Object {
                    Write-Verbose "Deleting $($_.Name)"
    
                    If ($BreakGlass -eq $True) 
                    {
                        $_ | Remove-AzureRmResource -Force 
                    }
                        Else
                        {
                            $_ | Remove-AzureRmResource -Force -WhatIf 
                        }
                }
    
            $ResourcesToRemove = $null
    
        }

    } #End PROCESS

} #End BulkDeleteResource


Write-Host "Performing Remove-AzureRmResource -WhatIF on all selected resouces" -ForegroundColor Cyan
Start-Sleep -Seconds 10

BulkDeleteResource $ResourceSelection

Write-Host "Type ""BreakGlass"" to Remove Resources, or Ctrl-C to Exit" -ForegroundColor Green
Read-Host "Final Answer" $HostInput
If ($HostInput = "BreakGlass" ) {
    BulkDeleteResource $ResourceSelection -BreakGlass
}




