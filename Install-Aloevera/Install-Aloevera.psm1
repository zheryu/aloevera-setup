#Requires -Version 7.5

# Get the module base path
$ModuleBase = $PSScriptRoot

# Import private functions
$PrivatePath = Join-Path -Path $ModuleBase -ChildPath 'Private'
if (Test-Path $PrivatePath) {
    Get-ChildItem -Path $PrivatePath -Filter '*.ps1' -Recurse | ForEach-Object {
        . $_.FullName
    }
}

# Import public functions
$PublicPath = Join-Path -Path $ModuleBase -ChildPath 'Public'
if (Test-Path $PublicPath) {
    Get-ChildItem -Path $PublicPath -Filter '*.ps1' -Recurse | ForEach-Object {
        . $_.FullName
    }
}

# Create aliases
New-Alias -Name 'Aloe' -Value 'Install-Aloevera' -Force

# Export module members
Export-ModuleMember -Function @(
    'Install-Aloevera',
    'Install-AloeVeraApps',
    'Install-AloeVeraWSL'
) -Alias @(
    'Aloe'
)
