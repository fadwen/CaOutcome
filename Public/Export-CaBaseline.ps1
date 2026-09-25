function Export-CaBaseline {
    <#
    .EXTERNALHELP CaOutcome-Help.xml
    .SYNOPSIS
        Records a set of outcomes as a baseline that can be committed and compared against later
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [OutputType('CaOutcome.Baseline')]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [object[]]$Outcome,

        [Parameter()]
        [string]$Path,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [switch]$PassThru
    )

    begin {
        $collected = New-Object System.Collections.Generic.List[object]
    }

    process {
        foreach ($item in $Outcome) {
            if ($null -ne $item) { $collected.Add($item) }
        }
    }

    end {
        $failed = @($collected | Where-Object {
            $_.PSObject.Properties['Failed'] -and $_.Failed
        })

        if ($failed.Count -gt 0) {
            $names = ($failed | ForEach-Object { $_.Scenario }) -join ', '
            if (-not $Force) {
                throw ("$($failed.Count) scenario(s) failed and would be missing from this " +
                    "baseline: $names. A later comparison would report them as removed. Fix " +
                    'the run, or pass -Force if you accept a partial baseline.')
            }
            Write-Warning "Writing a partial baseline; these scenarios failed and are omitted: $names"
        }

        $usable = @($collected | Where-Object {
            -not ($_.PSObject.Properties['Failed'] -and $_.Failed)
        })

        $scenarios = [ordered]@{}
        foreach ($item in ($usable | Sort-Object -Property Scenario)) {
            $name = [string]$item.Scenario
            if ([string]::IsNullOrWhiteSpace($name)) {
                throw ('An outcome has no Scenario name. A baseline is keyed by name, so ' +
                    'every outcome needs one - pass -ScenarioName to ConvertTo-CaOutcome.')
            }
            if ($scenarios.Contains($name)) {
                throw "Two outcomes share the scenario name '$name'. Names must be unique."
            }

            $scenarios[$name] = [ordered]@{
                current            = ConvertTo-CaBaselineEntry -EffectiveControl $item.Current
                projected          = ConvertTo-CaBaselineEntry -EffectiveControl $item.Projected
                reportOnlyApplying = [int]$item.ReportOnlyApplying
            }
        }

        $baseline = [PSCustomObject]@{
            PSTypeName    = 'CaOutcome.Baseline'
            schemaVersion = 1
            scenarios     = $scenarios
        }

        if (-not $Path) {
            return $baseline
        }

        $target = "$($scenarios.Count) scenario(s) to $Path"
        if ($PSCmdlet.ShouldProcess($target, 'Write Conditional Access outcome baseline')) {
            $json = $baseline | Select-Object schemaVersion, scenarios | ConvertTo-Json -Depth 20
            Set-Content -Path $Path -Value $json -Encoding utf8
        }

        if ($PassThru) { return $baseline }
    }
}
