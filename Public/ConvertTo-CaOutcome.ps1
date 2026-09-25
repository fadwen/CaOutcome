function ConvertTo-CaOutcome {
    <#
    .EXTERNALHELP CaOutcome-Help.xml
    .SYNOPSIS
        Turns a Conditional Access What If response into the effective outcome of the sign-in,
        and into the outcome that would follow from promoting the tenant's report-only policies
    #>

    [CmdletBinding()]
    [OutputType('CaOutcome.Result')]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [object]$WhatIfResult,

        [Parameter()]
        [string]$ScenarioName,

        [Parameter()]
        [AllowNull()]
        [object]$SignInCondition,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]$BaselineState = $script:CurrentStates,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]$CandidateState = $script:ProjectedStates
    )

    process {
        $policies = ConvertFrom-CaWhatIfResponse -InputObject $WhatIfResult

        if ($policies.Count -eq 0) {
            Write-Warning 'The What If response contained no policy results. Nothing to fold.'
        }

        $current = Get-CaEffectiveControl -Policy $policies -State $BaselineState -World 'Current' `
            -SignInCondition $SignInCondition
        $projected = Get-CaEffectiveControl -Policy $policies -State $CandidateState -World 'Projected' `
            -SignInCondition $SignInCondition
        $delta = Compare-CaEffectiveControl -From $current -To $projected

        # Surfaced on its own because it is the number that decides whether the projection means
        # anything: no applying report-only policy and the two worlds are identical by
        # construction, not because the promotion is safe.
        $reportOnlyApplying = @($policies | Where-Object {
            (Get-CaProperty -InputObject $_ -Name 'policyApplies') -eq $true -and
            (Get-CaProperty -InputObject $_ -Name 'state') -eq 'enabledForReportingButNotEnforced'
        }).Count

        [PSCustomObject]@{
            PSTypeName         = 'CaOutcome.Result'
            Scenario           = $ScenarioName
            Current            = $current
            Projected          = $projected
            Delta              = $delta
            PolicyCount        = $policies.Count
            ReportOnlyApplying = $reportOnlyApplying
        }
    }
}
