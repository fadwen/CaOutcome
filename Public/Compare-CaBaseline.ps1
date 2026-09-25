function Compare-CaBaseline {
    <#
    .EXTERNALHELP CaOutcome-Help.xml
    .SYNOPSIS
        Compares a fresh set of outcomes against a recorded baseline and reports what moved
    #>

    [CmdletBinding(DefaultParameterSetName = 'Object')]
    [OutputType('CaOutcome.Drift')]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [object[]]$Outcome,

        [Parameter(Mandatory, ParameterSetName = 'Object')]
        [ValidateNotNull()]
        [object]$Baseline,

        [Parameter(Mandatory, ParameterSetName = 'Path')]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    begin {
        if ($PSCmdlet.ParameterSetName -eq 'Path') {
            if (-not (Test-Path -LiteralPath $Path)) {
                throw "No baseline at '$Path'."
            }
            $Baseline = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
        }

        $stored = Get-CaProperty -InputObject $Baseline -Name 'scenarios'
        if ($null -eq $stored) {
            throw 'The baseline has no scenarios property. It may be from a different tool.'
        }

        $storedNames = @()
        if ($stored -is [System.Collections.IDictionary]) {
            $storedNames = @($stored.Keys)
        } elseif ($stored.PSObject) {
            $storedNames = @($stored.PSObject.Properties | Select-Object -ExpandProperty Name)
        }

        $seen = New-Object System.Collections.Generic.List[string]
        $results = New-Object System.Collections.Generic.List[object]
    }

    process {
        foreach ($item in $Outcome) {
            if ($null -eq $item) { continue }

            $name = [string]$item.Scenario
            $seen.Add($name)

            if ($item.PSObject.Properties['Failed'] -and $item.Failed) {
                $results.Add([PSCustomObject]@{
                    PSTypeName     = 'CaOutcome.Drift'
                    Scenario       = $name
                    Status         = 'Failed'
                    HasChange      = $false
                    CurrentDelta   = $null
                    ProjectedDelta = $null
                    Summary        = "Evaluation failed: $($item.Error)"
                })
                continue
            }

            $entry = Get-CaProperty -InputObject $stored -Name $name
            if ($null -eq $entry) {
                $results.Add([PSCustomObject]@{
                    PSTypeName     = 'CaOutcome.Drift'
                    Scenario       = $name
                    Status         = 'Added'
                    HasChange      = $true
                    CurrentDelta   = $null
                    ProjectedDelta = $null
                    Summary        = 'Not in the baseline; new scenario or a renamed one'
                })
                continue
            }

            $currentDelta = Compare-CaEffectiveControl `
                -From (ConvertFrom-CaBaselineEntry -Entry (Get-CaProperty -InputObject $entry -Name 'current')) `
                -To $item.Current
            $projectedDelta = Compare-CaEffectiveControl `
                -From (ConvertFrom-CaBaselineEntry -Entry (Get-CaProperty -InputObject $entry -Name 'projected')) `
                -To $item.Projected

            $hasChange = $currentDelta.HasChange -or $projectedDelta.HasChange

            $parts = New-Object System.Collections.Generic.List[string]
            if ($currentDelta.HasChange) { $parts.Add("enforced now: $($currentDelta.Summary)") }
            if ($projectedDelta.HasChange) { $parts.Add("after promotion: $($projectedDelta.Summary)") }
            $summary = 'No change'
            if ($parts.Count -gt 0) { $summary = $parts -join ' | ' }

            $results.Add([PSCustomObject]@{
                PSTypeName     = 'CaOutcome.Drift'
                Scenario       = $name
                Status         = $(if ($hasChange) { 'Changed' } else { 'Unchanged' })
                HasChange      = $hasChange
                CurrentDelta   = $currentDelta
                ProjectedDelta = $projectedDelta
                Summary        = $summary
            })
        }
    }

    end {
        # Reported last so that a missing scenario reads as a gap in the run rather than as a
        # result of it. The distinction from "removed" is the point: the usual cause is a failed
        # evaluation, and a transient HTTP error must not look like a policy change.
        foreach ($name in ($storedNames | Sort-Object)) {
            if ($seen -contains $name) { continue }

            $results.Add([PSCustomObject]@{
                PSTypeName     = 'CaOutcome.Drift'
                Scenario       = $name
                Status         = 'Missing'
                HasChange      = $true
                CurrentDelta   = $null
                ProjectedDelta = $null
                Summary        = ('In the baseline but not in this run - a failed evaluation, ' +
                    'or the scenario was taken out of the matrix')
            })
        }

        $results.ToArray()
    }
}
