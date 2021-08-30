function Set-AzureLoginSession {
  <#
    .SYNOPSIS
        Login to Azure
    .DESCRIPTION
        Login to Azure using service principal
    .EXAMPLE
        Get-AzureRepository
    .PARAMETER ClientId
        Azure service principal clientId
    .PARAMETER ClientSecret
        Azure service principal client_secret
    .PARAMETER TenantId
        Azure service principal tenantId
  #>
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    param(
        [Parameter(Mandatory)]
        [string]$ClientId,
        [Parameter(Mandatory)]
        [string]$ClientSecret,
        [Parameter(Mandatory)]
        [string]$TenantId
    )
    if ($PSCmdlet.ShouldProcess($ClientId, $ClientSecret, $TenantId)) {
      az login --service-principal -u $ClientId -p $ClientSecret -t $TenantId
    }

}
function Get-AzureContainerRegistry {
  <#
    .SYNOPSIS
        Get Azure container registry
    .DESCRIPTION
        Get Azure container registry based on logged subscription from login session
    .EXAMPLE
        Get-AzureRegistry
  #>
    $registries = az acr list | ConvertFrom-Json
    $registries | ForEach-Object {
    $repositories = Get-AzureRepository -Registry $_.name
    $_ | Add-Member -Name 'repositories' -Type NoteProperty -Value $repositories
    }

    return $registries
}

function Get-AzureRepository {
  <#
    .SYNOPSIS
        Get Azure repositories
    .DESCRIPTION
        Get all repositories for particular subscription
    .EXAMPLE
        Get-AzureRepository
    .PARAMETER RegistryName
        Azure container registry name.
  #>
  [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RegistryName
    )
    $repoList = az acr repository list -n $RegistryName | ConvertFrom-Json
    [System.Collections.ArrayList]$repObjList = New-Object -TypeName "System.Collections.ArrayList"
    $repoObj = New-Object -TypeName psobject -Property @{name= $RegistryName}
    $repoList | ForEach-Object {
        $repoTags = Get-AzureRepositoryTag -RegistryName $RegistryName -RepositoryName $_
        $repoObj | Add-Member -Name 'tags' -Type NoteProperty -Value $repoTags
        $repObjList.Add($repoObj) | Out-Null
    }

    return $repObjList
}
function Get-AzureRepositoryTag {
  <#
    .SYNOPSIS
        Get Azure repositories tags
    .DESCRIPTION
        Get all image tas for particular repository
    .EXAMPLE
        Get-AzureRepositoryTags
    .PARAMETER RegistryName
        Azure container registry name.
    .PARAMETER RepositoryName
        Azure repository name based on chosen container registry.
  #>
  [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RegistryName,
        [Parameter(Mandatory)]
        [string]$RepositoryName

    )
    return az acr repository show-tags --name $registryName --repository $repositoryName | ConvertFrom-Json
}
