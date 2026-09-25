function Invoke-CaScenarioMatrix {
    <#
    .EXTERNALHELP CaOutcome-Help.xml
    .SYNOPSIS
        Evaluates a set of scenarios against the tenant and folds each response into an outcome
    #>

    [CmdletBinding()]
    [OutputType('CaOutcome.Result')]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [object[]]$Scenario,

        [Parameter()]
        [scriptblock]$RequestHandler,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Uri = 'https://graph.microsoft.com/beta/identity/conditionalAccess/evaluate',

        [Parameter()]
        [ValidateRange(0, 20)]
        [int]$MaxRetry = 4,

        [Parameter()]
        [ValidateRange(0, 300)]
        [int]$InitialBackoffSecond = 2,

        [Parameter()]
        [ValidateRange(0, 60000)]
        [int]$DelayMillisecond = 0
    )

    begin {
        $index = 0
    }

    process {
        foreach ($item in $Scenario) {
            if ($null -eq $item) { continue }

            $name = [string](Get-CaProperty -InputObject $item -Name 'Name')
            $index++

            if ($DelayMillisecond -gt 0 -and $index -gt 1) {
                Start-Sleep -Milliseconds $DelayMillisecond
            }

            Write-Verbose "Evaluating scenario $index : $name"

            try {
                $body = ConvertTo-CaEvaluateBody -Scenario $item
                $response = Invoke-CaEvaluateRequest -Body $body -Uri $Uri `
                    -RequestHandler $RequestHandler -MaxRetry $MaxRetry `
                    -InitialBackoffSecond $InitialBackoffSecond

                $outcome = ConvertTo-CaOutcome -WhatIfResult $response -ScenarioName $name `
                    -SignInCondition (Get-CaProperty -InputObject $item -Name 'Conditions')

                $outcome | Add-Member -NotePropertyName 'Failed' -NotePropertyValue $false
                $outcome | Add-Member -NotePropertyName 'Error' -NotePropertyValue $null
                $outcome
            } catch {
                # Reported twice on purpose: as an error so an interactive run is not silent,
                # and as an object so a pipeline can see which scenario is missing and why
                Write-Error "Scenario '$name' failed: $($_.Exception.Message)"

                [PSCustomObject]@{
                    PSTypeName         = 'CaOutcome.Result'
                    Scenario           = $name
                    Current            = $null
                    Projected          = $null
                    Delta              = $null
                    PolicyCount        = 0
                    ReportOnlyApplying = 0
                    Failed             = $true
                    Error              = $_.Exception.Message
                }
            }
        }
    }
}
