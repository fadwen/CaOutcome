@{
    # Module manifest for CaOutcome
    RootModule = 'CaOutcome.psm1'
    ModuleVersion = '0.6.0'
    GUID = '4c1e8a76-9b23-4f5d-8e10-6d7a2f3b95c8'
    Author = 'Jeffrey Stuhr'
    CompanyName = 'Jeffrey Stuhr'
    Copyright = '(c) 2026 Jeffrey Stuhr. All rights reserved.'
    # Kept to one line for the repository's 115-character limit. The README carries the
    # full explanation of what "promotion" means here.
    Description = 'Predicts Entra Conditional Access sign-in outcomes before report-only policies go live'

    # PowerShell Version Requirements
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')

    # Required Modules
    # Deliberately none, even though Invoke-CaScenarioMatrix does send requests. Its default
    # request handler looks for Invoke-MgGraphRequest at run time and says so if it is absent,
    # and every other function is a pure transform. Declaring the Graph SDK here would make the
    # whole module unimportable - and its tests unrunnable - on a host that only ever needed the
    # folding. Supply -RequestHandler and the SDK is not involved at all.
    RequiredModules = @()

    # Functions to Export
    FunctionsToExport = @(
        'ConvertTo-CaOutcome',
        'Expand-CaScenario',
        'Invoke-CaScenarioMatrix',
        'Export-CaBaseline',
        'Compare-CaBaseline'
    )

    # Cmdlets to Export
    CmdletsToExport = @()

    # Variables to Export
    VariablesToExport = @()

    # Aliases to Export
    AliasesToExport = @()

    # Private Data
    PrivateData = @{
        PSData = @{
            Tags = @(
                'Entra', 'EntraID', 'MicrosoftEntra', 'AzureAD', 'ConditionalAccess', 'WhatIf',
                'ReportOnly', 'MFA', 'ZeroTrust', 'Maester', 'MicrosoftGraph', 'Identity',
                'Security', 'Baseline', 'Drift',
                'PSEdition_Desktop', 'PSEdition_Core', 'Windows', 'Linux', 'MacOS'
            )
            LicenseUri = 'https://github.com/fadwen/CaOutcome/blob/main/LICENSE'
            ProjectUri = 'https://github.com/fadwen/CaOutcome'

            # IconUri is omitted rather than set to ''. An empty string is not "no icon":
            # the nuspec writer emits an empty <iconUrl> element and NuGet rejects the pack
            # with 'IconUrl cannot be empty', so Publish-PSResource fails before it ever
            # reaches the Gallery. The same applies to HelpInfoURI below.
            ReleaseNotes = @'
0.6.0 - First release from its own repository, and first on the PowerShell Gallery.

Command help is now compiled MAML built from PlatyPS Markdown, and every command carries
[OutputType()] naming the type it actually returns - CaOutcome.Result, CaOutcome.Scenario,
CaOutcome.Baseline or CaOutcome.Drift - so tab completion works on the output. No change to
what any command does.

See CHANGELOG.md for the detail.
'@
            RequireLicenseAcceptance = $false
        }
    }

    # HelpInfoURI is omitted for the same reason as IconUri, and because there is nothing to
    # point it at: help ships in en-US/ with the module rather than as updatable help served
    # over the wire.
}
