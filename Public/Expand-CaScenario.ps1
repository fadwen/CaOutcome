function Expand-CaScenario {
    <#
    .EXTERNALHELP CaOutcome-Help.xml
    .SYNOPSIS
        Expands a matrix of personas, resources and conditions into the individual sign-ins to
        evaluate
    #>

    [CmdletBinding()]
    [OutputType('CaOutcome.Scenario')]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [object]$Matrix,

        [Parameter()]
        [ValidateRange(1, 100000)]
        [int]$MaxScenarioCount = 250
    )

    process {
        # The Where-Object is not decoration. A missing property reads as $null, and @($null)
        # has a count of one, so without it an absent axis passes the check below and then
        # fails much later with a confusing message about a nameless resource.
        $personas = @(Get-CaProperty -InputObject $Matrix -Name 'Personas' |
            Where-Object { $null -ne $_ })
        $resources = @(Get-CaProperty -InputObject $Matrix -Name 'Resources' |
            Where-Object { $null -ne $_ })
        $conditions = @(Get-CaProperty -InputObject $Matrix -Name 'Conditions' |
            Where-Object { $null -ne $_ })

        foreach ($axis in @(
            @{ Name = 'Personas'; Value = $personas }
            @{ Name = 'Resources'; Value = $resources }
            @{ Name = 'Conditions'; Value = $conditions }
        )) {
            if ($axis.Value.Count -eq 0) {
                throw "The matrix has no $($axis.Name). All three axes are required."
            }
        }

        $total = $personas.Count * $resources.Count * $conditions.Count
        if ($total -gt $MaxScenarioCount) {
            throw ("This matrix expands to $total scenarios, over the limit of " +
                "$MaxScenarioCount. Each one is an API call. Raise -MaxScenarioCount if that " +
                'is really what you want.')
        }

        foreach ($persona in $personas) {
            $personaName = [string](Get-CaProperty -InputObject $persona -Name 'Name')
            $userId = [string](Get-CaProperty -InputObject $persona -Name 'UserId')

            if ([string]::IsNullOrWhiteSpace($userId)) {
                throw "Persona '$personaName' has no UserId."
            }

            foreach ($resource in $resources) {
                $resourceName = [string](Get-CaProperty -InputObject $resource -Name 'Name')
                $applicationId = Get-CaProperty -InputObject $resource -Name 'ApplicationId'
                $userAction = Get-CaProperty -InputObject $resource -Name 'UserAction'
                $authContext = Get-CaProperty -InputObject $resource -Name 'AuthenticationContext'

                $targets = @($applicationId, $userAction, $authContext | Where-Object {
                    -not [string]::IsNullOrWhiteSpace([string]$_)
                })
                if ($targets.Count -ne 1) {
                    throw ("Resource '$resourceName' must set exactly one of ApplicationId, " +
                        "UserAction or AuthenticationContext; it sets $($targets.Count).")
                }

                foreach ($condition in $conditions) {
                    $conditionName = [string](Get-CaProperty -InputObject $condition -Name 'Name')

                    [PSCustomObject]@{
                        PSTypeName            = 'CaOutcome.Scenario'
                        Name                  = "$personaName/$resourceName/$conditionName"
                        PersonaName           = $personaName
                        UserId                = $userId
                        ResourceName          = $resourceName
                        ApplicationId         = $applicationId
                        UserAction            = $userAction
                        AuthenticationContext = $authContext
                        ConditionName         = $conditionName
                        Conditions            = ConvertTo-CaSignInCondition -Condition $condition
                    }
                }
            }
        }
    }
}
