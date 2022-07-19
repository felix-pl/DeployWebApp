Param(
    [parameter(Mandatory = $true)]
    [string]$app_name,
    [parameter(Mandatory = $true)]
    [string]$app_pool_name,
    [parameter(Mandatory = $true)]
    [string]$app_pool_username,
    [parameter(Mandatory = $true)]
    [string]$app_pool_password,
    [parameter(Mandatory = $true)]
    [string]$physical_path,
    [parameter(Mandatory = $true)]
    [string]$virtual_path,
    [parameter(Mandatory = $true)]
    [string]$website_name,
    [parameter(Mandatory = $true)]
    [string]$package_path,
    [string]$dotnet_version = "v4.0"
)

Import-Module WebAdministration

$app_pool

if( !(Test-Path IIS:\AppPools\$app_pool_name) )
{
    Write-Output "Create new app pool"
    $app_pool = New-WebAppPool -Name $app_pool_name
}
else 
{
    Write-Output "$app_pool_name is available"

    $app_pool_state = Get-WebAppPoolState -Name $app_pool_name
    
    if ("Stopped" -ne $app_pool_state.Value)
    {
        Write-Output "Stop app pool"
        Stop-WebAppPool -Name $app_pool_name
    }
    
    $app_pool = Get-Item IIS:\AppPools\$app_pool_name
}
    $app_pool.autoStart = $true
    $app_pool.startMode = "OnDemand"
    $app_pool.managedPipelineMode = "Integrated"
    $app_pool.enable32BitAppOnWin64 = $false
    $app_pool.managedRuntimeVersion = $dotnet_version
    $app_pool.processModel.userName = $app_pool_username
    $app_pool.processModel.password = $app_pool_password
    $app_pool.processModel.identityType = 3     #SpecificUser
    $app_pool | Set-Item

if (Test-Path $physical_path -pathType container)
{
    Remove-Item $physical_path -Force -Recurse
}

New-Item -ItemType Directory -Path $physical_path -Force

Write-Output "$physical_path is created"

Copy-Item $package_path\** -Destination $physical_path -Recurse

Write-Output "Date is copied from $package_path to $physical_path"

New-WebApplication $app_name -Site $website_name -ApplicationPool $app_pool_name -PhysicalPath $physical_path -Force

Write-Output "$app_name is created under $website_name"

Start-WebAppPool -Name $app_pool_name

Write-Output "$app_pool_name is started"
