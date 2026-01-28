@{
    RootModule = 'MaskPII.psm1'
    ModuleVersion = '0.2.0'
    GUID = 'D1B04EF8-7F10-4FB7-BDEB-0F15FFA16C54'
    Author = 'Finite Field, K.K.'
    CompanyName = 'Finite Field, K.K.'
    Copyright = '(c) 2026 Finite Field, K.K.'
    Description = 'Lightweight, customizable PII masking for emails and phone numbers.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('New-Masker')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('pii', 'masking', 'email', 'phone', 'privacy')
            LicenseUri = 'https://github.com/finitefield-org/mask-pii/blob/main/LICENSE.md'
            ProjectUri = 'https://finitefield.org/en/oss/mask-pii'
            ReleaseNotes = 'See CHANGELOG.md in the repository.'
            Repository = 'https://github.com/finitefield-org/mask-pii'
            Issues = 'https://github.com/finitefield-org/mask-pii/issues'
            License = 'MIT'
        }
    }
}
