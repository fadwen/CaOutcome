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

    begin {
        # Maester's Test-MtConditionalAccessWhatIf returns the policy results unwrapped, so piped
        # into this command they arrive one policy at a time. Folding each on its own would give
        # one outcome per policy, every one of them wrong, so a lone policy result is held back
        # and the lot folded together in end. Anything that is a whole response - an envelope,
        # a JSON string, a collection - still folds as it arrives, one outcome per response.
        $loosePolicies = [System.Collections.Generic.List[object]]::new()

        $foldParameters = @{
            ScenarioName    = $ScenarioName
            SignInCondition = $SignInCondition
            BaselineState   = $BaselineState
            CandidateState  = $CandidateState
        }
    }

    process {
        $isLonePolicy = $null -ne $WhatIfResult -and $WhatIfResult -isnot [string] -and
            ($WhatIfResult -is [hashtable] -or $WhatIfResult -isnot [System.Collections.IEnumerable])
        # The OData envelope is also a single non-enumerable object, so it is told apart from a
        # policy result by its value property; a policy result never carries one.
        if ($isLonePolicy) {
            if ($WhatIfResult -is [hashtable]) {
                $isLonePolicy = -not $WhatIfResult.ContainsKey('value')
            } else {
                $isLonePolicy = -not $WhatIfResult.PSObject.Properties['value']
            }
        }

        if ($isLonePolicy) {
            $loosePolicies.Add($WhatIfResult)
        } else {
            Get-CaFoldedOutcome -Response $WhatIfResult @foldParameters
        }
    }

    end {
        if ($loosePolicies.Count -gt 0) {
            Get-CaFoldedOutcome -Response $loosePolicies.ToArray() @foldParameters
        }
    }
}
