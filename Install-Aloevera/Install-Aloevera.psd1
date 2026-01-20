@{
    # Script module or binary module file associated with this manifest
    RootModule = 'Install-Aloevera.psm1'

    # Version number of this module
    ModuleVersion = '1.0.0'

    # ID used to uniquely identify this module
    GUID = 'a7f3e8d1-4b2c-4f9a-8e5d-1a3c5b7d9e2f'

    # Author of this module
    Author = 'Your Name'

    # Company or vendor of this module
    CompanyName = 'Unknown'

    # Copyright statement for this module
    Copyright = '(c) 2026. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Automated Windows 11 workstation setup using WinGet DSC. Handles WSL installation, Ubuntu configuration, and application provisioning.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.5'

    # Supported PSEditions
    CompatiblePSEditions = @('Core')

    # Functions to export from this module
    FunctionsToExport = @(
        'Install-Aloevera'
    )

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @(
        'Aloe'
    )

    # List of all files packaged with this module
    FileList = @(
        'Install-Aloevera.psd1',
        'Install-Aloevera.psm1'
    )

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Windows', 'WSL', 'Setup', 'Provisioning', 'WinGet', 'DSC', 'Ubuntu')

            # A URL to the license for this module.
            # LicenseUri = ''

            # A URL to the main website for this project.
            # ProjectUri = ''

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of Install-Aloevera module'
        }
    }
}
