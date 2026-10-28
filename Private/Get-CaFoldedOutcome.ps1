function Get-CaFoldedOutcome {
    <#
    .SYNOPSIS
        Folds one What If response into a CaOutcome.Result

    .DESCRIPTION
        The fold behind ConvertTo-CaOutcome, held apart from it because that command folds in
        two places: in process for each whole response that arrives, and in end for policy
        results that arrived one at a time and were collected first. Both must produce the same
        object, so there is one definition of it.

    .PARAMETER Response
        The response in any form ConvertFrom-CaWhatIfResponse accepts.

    .PARAMETER ScenarioName
        Carried onto the result as Scenario.

    .PARAMETER SignInCondition
        The simulated sign-in, passed to Get-CaEffectiveControl for satisfiability.

    .PARAMETER BaselineState
        The policy states that make up the Current world.

    .PARAMETER CandidateState
        The policy states that make up the Projected world.

    .OUTPUTS
        CaOutcome.Result

    .EXAMPLE
        Get-CaFoldedOutcome -Response $whatIf -BaselineState 'enabled' -CandidateState 'enabled', 'enabledForReportingButNotEnforced'

    .NOTES
        Author: Jeffrey Stuhr
    #>

    [CmdletBinding()]
    [OutputType('CaOutcome.Result')]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object]$Response,

        [Parameter()]
        [string]$ScenarioName,

        [Parameter()]
        [AllowNull()]
        [object]$SignInCondition,

        [Parameter(Mandatory)]
        [string[]]$BaselineState,

        [Parameter(Mandatory)]
        [string[]]$CandidateState
    )

    $policies = ConvertFrom-CaWhatIfResponse -InputObject $Response

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
