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
  [System.Collections.ArrayList]$registryList = New-Object -TypeName 'System.Collections.ArrayList'
  $registries = az acr list | ConvertFrom-Json
  $registries | ForEach-Object {
    $registry = New-Object -TypeName psobject -Property @{name = $_.name; creationDate = $_.creationDate; id = $_.id; location = $_.location; loginServer = $_.loginServer; provisioningState = $_.provisioningState; resourceGroup = $_.resourceGroup; sku = $_.sku}
    $repositories = Get-AzureRepository -RegistryName $_.name
    if($_.adminUserEnabled) {
      $credential = Get-AzureRegistryCredential -RegistryName $_.name
    } else {
      $credential = $null
    }
    $registry | Add-Member -Name 'repositories' -Type NoteProperty -Value $repositories
    $registry | Add-Member -Name 'credential' -Type NoteProperty -Value $credential
    $registryList.Add($registry) | Out-Null
  }
  return $registryList
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
  [OutputType([System.Collections.ArrayList])]
  param(
    [Parameter(Mandatory)]
    [string]$RegistryName
  )
  $repositories = az acr repository list -n $RegistryName | ConvertFrom-Json
  [System.Collections.ArrayList]$repositoryList = New-Object -TypeName "System.Collections.ArrayList"
  if ($repositories.Count -gt 0) {
    $repositories | ForEach-Object {
      $repositoryTags = Get-AzureRepositoryTag -RegistryName $RegistryName -RepositoryName $_
      $repository = New-Object -TypeName PSObject -Property @{'name' = $_;'tags' = $repositoryTags}
      $repositoryList.Add($repository) | Out-Null
    }
  }
  else {
    return $repositoryList
  }
  return $repositoryList
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
  [OutputType([System.Collections.ArrayList])]
  param(
    [Parameter(Mandatory)]
    [string]$RegistryName,
    [Parameter(Mandatory)]
    [string]$RepositoryName

  )
  $tags = az acr repository show-tags --name $RegistryName --repository $RepositoryName | ConvertFrom-Json
  [System.Collections.ArrayList]$tagList = New-Object -TypeName 'System.Collections.ArrayList'

  $tags | ForEach-Object {
    $tagList.Add($_) | Out-Null
  }
  return $tagList
}

function Get-AzureRegistryCredential {
  <#
    .SYNOPSIS
        Get registry credentials
    .DESCRIPTION
        Get registry credentials if admin enabled
    .EXAMPLE
        Get-AzureRegistryCredentials
    .PARAMETER RegistryName
        Azure container registry name.
  #>
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param(
    [Parameter(Mandatory)]
    [string]$RegistryName
  )

  $credentials = az acr credential show -n $RegistryName | ConvertFrom-Json
  $credentialObj = New-Object -TypeName psobject -Property @{'username' = $credentials.username;'password' = $credentials.passwords[0].value}
  return $credentialObj
}
