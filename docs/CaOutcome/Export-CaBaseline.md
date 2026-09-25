---
document type: cmdlet
external help file: CaOutcome-Help.xml
HelpUri: https://github.com/fadwen/CaOutcome/blob/main/docs/CaOutcome/Export-CaBaseline.md
Locale: en-US
Module Name: CaOutcome
ms.date: 09/25/2026
PlatyPS schema version: 2024-05-01
title: Export-CaBaseline
---

# Export-CaBaseline

## SYNOPSIS

Records a set of outcomes as a baseline that can be committed and compared against later

## SYNTAX

### __AllParameterSets

```
Export-CaBaseline [-Outcome] <Object[]> [[-Path] <string>] [-Force] [-PassThru] [-WhatIf] [-Confirm]
```

## DESCRIPTION

Core Functionality:
Reduces outcomes to the stable subset a comparison needs and writes them as JSON, keyed by
scenario name and ordered so that the only thing which changes between runs is the outcome
itself.

Business Value:
This is the part that catches what configuration comparison cannot see. Microsoft365DSC and
every policy-export tool watch the policy: they tell you when its JSON changes. But a
Conditional Access outcome depends on far more than the policy document - group membership,
role assignment, named locations, the compliance state of a device. Someone joins a group and a
policy that already required a compliant device now applies to them. No policy changed. No
configuration drifted. A user is nonetheless locked out on Monday who was not on Friday, and
nothing in a config-drift tool will ever mention it.

A committed baseline of outcomes catches exactly that class of change, because it records what
the tenant does rather than what it is configured to do.

Use Cases:
- Committing an approved set of outcomes next to the matrix that produced it
- Failing a scheduled run when any persona's experience changes
- Recording the state before a migration, to prove afterwards what moved

Dependencies:
None.

Side Effects:
Writes the file at Path when one is given. Supports -WhatIf.

Important:
A baseline containing a failed scenario is refused unless -Force. A scenario that errored has
no outcome, so recording it as absent would make the next comparison report it as removed - a
change invented by a transient HTTP error, in the artefact whose whole value is that its
changes are real.

No timestamp is written. The file is meant to be committed, and a generated-on field would
produce a diff on every run whether or not anything moved, which trains everyone to stop
reading the diff. Git already records when the file changed and who changed it.

## EXAMPLES

### Example 1: Records the current outcomes as the approved baseline

```powershell
Expand-CaScenario -Matrix $matrix | Invoke-CaScenarioMatrix |
    Export-CaBaseline -Path .\ca-baseline.json
```

Output: None; the file is written

Duration: Instant once the matrix has run

Use case: The first run, once the outcomes have been reviewed and are considered correct

### Example 2: Reports what would be written without writing it

```powershell
$outcomes | Export-CaBaseline -Path .\ca-baseline.json -WhatIf
```

Output: The WhatIf message naming the file and the scenario count

Duration: Instant

Use case: Checking the scenario count before overwriting an approved baseline

### Example 3: Builds the baseline in memory, without a file

```powershell
$baseline = $outcomes | Export-CaBaseline
$baseline.scenarios.Keys
```

Output: The baseline object, and then its scenario names

Duration: Instant

Use case: Comparing two runs against each other without committing either

## PARAMETERS

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Force

[System.Management.Automation.SwitchParameter] (Optional, No Pipeline Support)

Write the baseline even though a scenario failed. The failed scenario is omitted from the file,
so read the warning before using this on a run you intend to trust.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Outcome

[System.Object[]] (Mandatory, Accepts Pipeline Input)

Outcomes from Invoke-CaScenarioMatrix or ConvertTo-CaOutcome. Each must carry a Scenario name,
which is the key the baseline is stored under.

```yaml
Type: System.Object[]
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

### -PassThru

[System.Management.Automation.SwitchParameter] (Optional, No Pipeline Support)

Return the baseline object as well as writing it.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Path

[System.String] (Optional, No Pipeline Support)

Where to write the JSON. Omit it and the baseline object is returned instead.

```yaml
Type: System.String
DefaultValue: ''
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

### -WhatIf

Runs the command in a mode that only reports what would happen without performing the actions.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
ParameterSets:
- Name: (All)
  Position: Named
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

### System.Object[]

Outcomes, bound to **-Outcome** from the pipeline - the output of **Invoke-CaScenarioMatrix**
or **ConvertTo-CaOutcome**. Every outcome needs a unique `Scenario` name. An outcome marked
`Failed` is refused unless **-Force** is given, and then left out of the baseline.

## OUTPUTS

### CaOutcome.Baseline

Returned when **-Path** is omitted, or with **-PassThru**. Carries `schemaVersion` and
`scenarios`, an ordered map from scenario name to its `current` and `projected` outcome and its
`reportOnlyApplying` count. The same shape is what is written to **-Path** as JSON. Nothing is
returned when **-Path** is given without **-PassThru**.

## NOTES

Author: Jeffrey Stuhr Blog: https://www.techbyjeff.net LinkedIn:
https://www.linkedin.com/in/jeffrey-stuhr-034214aa/

The baseline is deterministic - scenarios, controls and policies are sorted - so that a
committed baseline diffs cleanly and a run that changed nothing rewrites it byte for byte.

A baseline names users, groups, applications and policies from the tenant it was taken in.
Commit it to the repository that holds that tenant's tests, not to a public one.

## RELATED LINKS

- [Compare-CaBaseline]()
- [Invoke-CaScenarioMatrix]()
- [about_CaOutcome]()
