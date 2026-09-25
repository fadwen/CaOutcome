---
document type: cmdlet
external help file: CaOutcome-Help.xml
HelpUri: https://github.com/fadwen/CaOutcome/blob/main/docs/CaOutcome/Compare-CaBaseline.md
Locale: en-US
Module Name: CaOutcome
ms.date: 09/25/2026
PlatyPS schema version: 2024-05-01
title: Compare-CaBaseline
---

# Compare-CaBaseline

## SYNOPSIS

Compares a fresh set of outcomes against a recorded baseline and reports what moved

## SYNTAX

### Object (Default)

```
Compare-CaBaseline -Outcome <Object[]> -Baseline <Object>
```

### Path

```
Compare-CaBaseline -Outcome <Object[]> -Path <string>
```

## DESCRIPTION

Core Functionality:
Matches fresh outcomes to a stored baseline by scenario name and diffs each pair, in both
worlds, using the same comparison that produces a promotion diff. Scenarios present on only one
side are reported as added or missing.

Business Value:
This is the assertion a scheduled run is for. Everything else in this module answers "what
happens"; this answers "what changed since it was approved", which is the question that belongs
in a nightly job rather than in somebody's head.

It sees a class of change that policy comparison cannot. A group membership change, a role
assignment, an edit to a named location, a device falling out of compliance - each moves who a
policy hits while the policy document sits untouched. Microsoft365DSC finds nothing, because
nothing it watches drifted. The outcome for a persona nonetheless changed, and that shows up
here.

Both worlds are compared, and the distinction matters. Current drift means what the tenant
enforces has moved. Projected drift means the pilot's blast radius has moved - which happens
without anyone touching the pilot, because the population it would hit is not fixed.

Use Cases:
- A nightly run that fails when any persona's experience changes
- Proving that a migration or a group restructure changed nothing users can feel
- Reviewing a diff before re-approving a baseline

Dependencies:
None.

Side Effects:
None. Nothing is written; re-approving a baseline is Export-CaBaseline's job.

Important:
A scenario in the baseline with no fresh outcome is reported as Missing, not as removed. The
usual cause is a failed evaluation rather than a deliberate change to the matrix, and those two
need to look different or a transient HTTP error reads as a policy change.

## EXAMPLES

### Example 1: Runs the matrix and reports only the scenarios that have moved

```powershell
Expand-CaScenario -Matrix $matrix | Invoke-CaScenarioMatrix |
    Compare-CaBaseline -Path .\ca-baseline.json |
    Where-Object HasChange
```

Output: One row per changed scenario

Duration: The matrix run, plus milliseconds

Use case: The nightly job

### Example 2: Finds scenarios the run did not produce, usually a failed evaluation

```powershell
$drift = $outcomes | Compare-CaBaseline -Path .\ca-baseline.json
$drift | Where-Object { $_.Status -eq 'Missing' }
```

Output: One row per scenario in the baseline with no fresh outcome

Duration: Instant

Use case: Telling a broken run apart from a real change before acting on the diff

### Example 3: The severe case - a persona that used to get in and now does not

```powershell
$outcomes | Compare-CaBaseline -Path .\ca-baseline.json |
    Where-Object { $_.CurrentDelta.BecomesEffectivelyBlocked } |
    Select-Object Scenario, Summary
```

Output: One row per newly locked out persona

Duration: Instant

Use case: The alert worth waking somebody for, as opposed to the report worth reading

## PARAMETERS

### -Baseline

[System.Object] (Mandatory in the Object set, No Pipeline Support)

The baseline object from Export-CaBaseline.

```yaml
Type: System.Object
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Object
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Outcome

[System.Object[]] (Mandatory, Accepts Pipeline Input)

The fresh outcomes, from Invoke-CaScenarioMatrix.

```yaml
Type: System.Object[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Path

[System.String] (Mandatory in the Path set, No Pipeline Support)

A baseline JSON file to read.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Path
  Position: Named
  IsRequired: true
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

### System.Object[]

Outcomes, bound to **-Outcome** from the pipeline - normally a fresh run of
**Invoke-CaScenarioMatrix** over the same matrix the baseline was taken from.

## OUTPUTS

### CaOutcome.Drift

One object per scenario in either the run or the baseline. `Status` is `Unchanged`, `Changed`,
`Added` (in the run only), `Missing` (in the baseline only - usually a failed evaluation rather
than a removed scenario) or `Failed`. `HasChange` is the property to gate on. `CurrentDelta`
and `ProjectedDelta` hold the change in what is enforced now and in what would be enforced
after promotion, and `Summary` states both in one line.

## NOTES

Author: Jeffrey Stuhr Blog: https://www.techbyjeff.net LinkedIn:
https://www.linkedin.com/in/jeffrey-stuhr-034214aa/

Both worlds are compared, not just the enforced one, so that a change to a report-only policy
under pilot is caught before it is promoted.

## RELATED LINKS

- [Export-CaBaseline]()
- [Invoke-CaScenarioMatrix]()
- [about_CaOutcome]()
