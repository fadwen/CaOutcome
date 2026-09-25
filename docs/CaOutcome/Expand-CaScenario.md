---
document type: cmdlet
external help file: CaOutcome-Help.xml
HelpUri: https://github.com/fadwen/CaOutcome/blob/main/docs/CaOutcome/Expand-CaScenario.md
Locale: en-US
Module Name: CaOutcome
ms.date: 09/25/2026
PlatyPS schema version: 2024-05-01
title: Expand-CaScenario
---

# Expand-CaScenario

## SYNOPSIS

Expands a matrix of personas, resources and conditions into the individual sign-ins to evaluate

## SYNTAX

### __AllParameterSets

```
Expand-CaScenario [-Matrix] <Object> [[-MaxScenarioCount] <int>]
```

## DESCRIPTION

Core Functionality:
Takes a matrix definition - a set of personas, a set of resources and a set of sign-in
conditions - and returns every combination of the three as a scenario ready to send to the What
If endpoint.

Business Value:
Conditional Access is not a per-user question, it is a per-population one, and the interesting
failures live in combinations nobody thought to check by hand: the contractor on an unmanaged
Mac, the break glass account from an unusual country, the service desk on a mobile client.
Writing those out one at a time is how they get skipped. Declaring the axes and multiplying
them out is how they get covered.

Keeping the definition as data rather than code matters more than it looks. A matrix in a psd1
next to the tests can be reviewed, diffed and extended by someone who does not write
PowerShell, and it is the same artefact whether it is driving an ad hoc check or a scheduled
run.

Use Cases:
- Building the input for Invoke-CaScenarioMatrix
- Reviewing what a run will actually cover before spending the API calls on it
- Feeding a subset, by filtering the output, when only one persona is in question

Dependencies:
None. This is a pure expansion and touches nothing.

Side Effects:
None.

Important:
The count multiplies. Three personas, four resources and five conditions is sixty API calls,
and the guard exists because that arithmetic is easy to get wrong by a factor of ten.
MaxScenarioCount throws rather than truncating: a silently shortened matrix would report a
clean run over a fraction of what was asked for.

## EXAMPLES

### Example 1: Expands one persona against one resource under two device states

```powershell
$matrix = @{
    Personas   = @(@{ Name = 'standard'; UserId = $userId })
    Resources  = @(@{ Name = 'office365'
                      ApplicationId = '00000003-0000-0ff1-ce00-000000000000' })
    Conditions = @(
        @{ Name = 'managed'; DevicePlatform = 'windows'; ClientAppType = 'browser'
           DeviceInfo = @{ isCompliant = $true } }
        @{ Name = 'unmanaged'; DevicePlatform = 'windows'; ClientAppType = 'browser'
           DeviceInfo = @{ isCompliant = $false } })
}
Expand-CaScenario -Matrix $matrix
```

Output: Two scenarios, named standard/office365/managed and standard/office365/unmanaged

Duration: Instant

Use case: The smallest useful matrix - the same user, managed and not

### Example 2: Reviews the coverage of a matrix held as data, without calling Graph

```powershell
Expand-CaScenario -Matrix (Import-PowerShellDataFile .\ca-matrix.psd1) |
    Select-Object Name
```

Output: One row per scenario the matrix describes

Duration: Instant

Use case: Checking what a scheduled run covers, and what it quietly does not

### Example 3: Runs one persona out of a large matrix

```powershell
Expand-CaScenario -Matrix $matrix |
    Where-Object PersonaName -eq 'breakglass' |
    Invoke-CaScenarioMatrix
```

Output: Outcomes for the break glass account alone

Duration: Instant to expand; the API calls take the time

Use case: Re-checking the account that matters most, without paying for the whole matrix

## PARAMETERS

### -Matrix

[System.Object] (Mandatory, Accepts Pipeline Input)

The matrix definition, a hashtable or object with Personas, Resources and Conditions.

Each Persona needs Name and UserId. Each Resource needs Name plus one of ApplicationId,
UserAction or AuthenticationContext. Each Condition needs Name plus any of the signInConditions
properties, written in PascalCase - DevicePlatform, ClientAppType, SignInRiskLevel,
UserRiskLevel, InsiderRiskLevel, ServicePrincipalRiskLevel, AgentIdRiskLevel, Country,
IpAddress, DeviceInfo, AuthenticationFlow.

Business Context: Unrecognised condition keys are passed through with their first letter
lowercased rather than rejected, so a property Microsoft adds to signInConditions can be used
the day it ships without waiting for this module to learn about it.

```yaml
Type: System.Object
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -MaxScenarioCount

[System.Int32] (Optional, No Pipeline Support)

The most scenarios this matrix may expand to. Defaults to 250. Exceeding it throws.

```yaml
Type: System.Int32
DefaultValue: 250
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Object

A matrix definition, bound to **-Matrix** from the pipeline - a hashtable, an object, or the
result of `Import-PowerShellDataFile` on a matrix held as a `.psd1`.

## OUTPUTS

### CaOutcome.Scenario

One object per persona, resource and condition combination. `Name` is
`persona/resource/condition` and is what a baseline is keyed by, so it must be stable across
runs. `PersonaName`, `UserId`, `ResourceName` and `ConditionName` identify the parts; exactly
one of `ApplicationId`, `UserAction` or `AuthenticationContext` is set, naming the resource
target; `Conditions` is a hashtable already shaped for the `signInConditions` property of an
evaluate request. The objects pipe straight into **Invoke-CaScenarioMatrix**.

## NOTES

Author: Jeffrey Stuhr Blog: https://www.techbyjeff.net LinkedIn:
https://www.linkedin.com/in/jeffrey-stuhr-034214aa/

Expansion is pure - it calls nothing and changes nothing - so it is safe to run just to see
what a matrix covers.

## RELATED LINKS

- [Invoke-CaScenarioMatrix]()
- [about_CaOutcome]()
