
$VerbosePreference =  "SilentlyContinue"

#If not logged in to Azure, start login
if ($Null -eq (Get-AzContext).Account) {
    $AzureEnv = Get-AzEnvironment | Select-Object -Property Name  | 
    Out-GridView -Title "Choose your Azure environment.  NOTE: For Azure Commercial choose AzureCloud" -OutputMode Single
    Connect-AzAccount -Environment $AzureEnv.Name }

$SubSelection = Get-AzSubscription | Out-GridView -Title "Select a Subscription" -OutputMode Single

Set-AzContext -Subscription $SubSelection

$RGSelection = Get-AzResourceGroup  | Out-GridView -Title "Select Resource Group" -OutputMode Single

$ResourceSelection =  Get-AzResource -ResourceGroupName $RGSelection.ResourceGroupName  | Out-GridView -Title "Select Resources to Remove" -OutputMode Multiple 

$ResourceSelection =  $ResourceSelection | Out-GridView -Title "Re-Select Resources to Remove" -OutputMode Multiple

If ($ResourceSelection.Count -eq 0) {Break}

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
                        $_ | Remove-AzResource -Force 
                    } 
                        Else 
                        {
                            $_ | Remove-AzResource -Force -WhatIf 
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
                        $_ | Remove-AzResource -Force 
                    }
                        Else
                        {
                            $_ | Remove-AzResource -Force -WhatIf 
                        }
                }
        }

    } #End PROCESS

} #End BulkDeleteResource


Write-Host "Performing Remove-AzResource -WhatIF on all selected resouces to incite fear" -ForegroundColor Cyan
Start-Sleep -Seconds 10

BulkDeleteResource $ResourceSelection

If ($ResourceSelection) {
    Write-Host "Resources selected for deletion:"
    $ResourceSelection | ft -Property Name,ResourceGroupName,Location,ResourceType -AutoSize
}

Write-Host "Number of resources selected for deletion: $($ResourceSelection.Count)"

Write-Host "`nType ""BreakGlass"" to Remove Resources, or Ctrl-C to Exit" -ForegroundColor Green
$HostInput = $Null
$HostInput = Read-Host "Final Answer" 
If ($HostInput -eq "BreakGlass" ) {
    BulkDeleteResource $ResourceSelection -BreakGlass
} Else {
    Write-Host "Existing..."    
    Break
}

