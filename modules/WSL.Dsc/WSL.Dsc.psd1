@{
    RootModule           = 'WSL.Dsc.psm1'
    ModuleVersion        = '0.1.0'
    GUID                 = '8f3a9b5c-7e2d-4a6f-9c1b-3e5d7a9f2b4c'
    Author               = 'aloevera-setup'
    CompanyName          = 'Personal'
    Copyright            = '(c) 2026. All rights reserved.'
    Description          = 'DSC Resources for WSL Configuration'
    PowerShellVersion    = '7.2'
    DscResourcesToExport = @(
        'WSLConfig'
        'WSLFstab'
    )
    PrivateData          = @{
        PSData = @{
            Tags       = @('DSC', 'WSL', 'Configuration')
            Prerelease = 'alpha'
        }
    }
}
