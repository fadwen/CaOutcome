---
document type: cmdlet
external help file: CaOutcome-Help.xml
HelpUri: https://github.com/fadwen/CaOutcome/blob/main/docs/CaOutcome/ConvertTo-CaOutcome.md
Locale: en-US
Module Name: CaOutcome
ms.date: 09/25/2026
PlatyPS schema version: 2024-05-01
title: ConvertTo-CaOutcome
---

# ConvertTo-CaOutcome

## SYNOPSIS

Turns a Conditional Access What If response into the effective outcome of the sign-in, and into
the outcome that would follow from promoting the tenant's report-only policies

## SYNTAX

### __AllParameterSets

```
ConvertTo-CaOutcome [-WhatIfResult] <Object> [[-ScenarioName] <string>]
 [[-SignInCondition] <Object>] [[-BaselineState] <string[]>] [[-CandidateState] <string[]>]
```

## DESCRIPTION

Core Functionality:
Takes the whatIfAnalysisResult collection Graph returns from POST
/beta/identity/conditionalAccess/evaluate and folds it twice. Current is the outcome the tenant
enforces today, from the policies whose state is enabled. Projected is the outcome it would
enforce if every report-only policy were switched on. Delta is the difference between them.

Business Value:
The What If API answers a question nobody asks. It reports, policy by policy, whether each one
matches - so a tenant with thirteen policies returns thirteen verdicts, and working out what
the user actually experiences is left to the reader. What an administrator wants to know is
whether the sign-in succeeds, what the user has to do to make it succeed, and what changes if
the policy being piloted goes live. All three come out of one response, because that response
carries each policy's state alongside its verdict: filter to enabled and you have today, add
the report-only ones and you have the promotion.

That second fold is the reason this exists. There is no way to ask Graph to evaluate a
hypothetical policy - the request body takes a sign-in to simulate, not a policy set, so the
evaluation is always against what is really in the tenant. Staging a candidate as report-only
and reading both worlds out of one response is the way to simulate a promotion without
enforcing anything, and it costs no extra API calls.

Use Cases:
- Checking what a report-only policy will do before promoting it, per persona
- Asserting in Maester that a given sign-in is blocked, or requires a given control
- Storing an outcome as a baseline and failing a later run when a cell flips, which catches
  group membership changes that leave the policy JSON untouched

Dependencies:
None. This transforms a response somebody else fetched, so it needs no Graph module and no
connection. Feed it Maester's Test-MtConditionalAccessWhatIf -AllResults, an
Invoke-MgGraphRequest result, or a saved file.

Side Effects:
None. Nothing is fetched and nothing is changed.

Important:
The response must include every policy, not just the applying ones. Graph's appliedPoliciesOnly
defaults to returning all of them, and Maester exposes the same thing as -AllResults. Without
the non-applying policies the fold still works, but a report-only policy that does not apply is
indistinguishable from one that was never returned, and the projection quietly loses its
meaning.

## EXAMPLES

### Example 1: Folds a live evaluation into both worlds

```powershell
$response = Invoke-MgGraphRequest -Method POST -OutputType Json `
    -Uri 'https://graph.microsoft.com/beta/identity/conditionalAccess/evaluate' -Body $body
ConvertTo-CaOutcome -WhatIfResult $response
```

Output: One outcome object, with Current, Projected and Delta

Duration: Milliseconds; the API call is the slow part

Use case: Checking a single sign-in by hand

### Example 2: Reports only what promoting the report-only policies would change

```powershell
$outcome = ConvertTo-CaOutcome -WhatIfResult $response -ScenarioName 'jeff/ios'
if ($outcome.Delta.HasChange) { $outcome.Delta.Summary }
```

Output: A sentence such as 'LOCKS OUT this sign-in; cannot satisfy GRANT - Compliant Windows
Devices (compliantDevice)'

Duration: Milliseconds

Use case: Deciding whether a piloted policy is safe to switch on

### Example 3: Runs a stored matrix of scenarios and keeps the ones a promotion changes

```powershell
Get-ChildItem .\fixtures\*.json | ForEach-Object {
    ConvertTo-CaOutcome -WhatIfResult (Get-Content $_ -Raw) -ScenarioName $_.BaseName
} |
    Where-Object { $_.Delta.HasChange } |
    Select-Object Scenario, @{n='Change';e={$_.Delta.Summary}}
```

Output: One row per scenario whose outcome changes

Duration: Milliseconds per scenario

Use case: The blast radius of a promotion, across every persona at once

## PARAMETERS

### -BaselineState

[System.String[]] (Optional, No Pipeline Support)

The policy states that make up the Current world. Defaults to enabled alone, which is what the
tenant enforces.

```yaml
Type: System.String[]
DefaultValue: $script:CurrentStates
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 3
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -CandidateState

[System.String[]] (Optional, No Pipeline Support)

The policy states that make up the Projected world. Defaults to enabled plus
enabledForReportingButNotEnforced, which is the promotion simulation.

Business Context: Overridable because the same fold answers a different question when the
states are chosen differently - passing the same value as BaselineState turns the delta off and
leaves you with a plain outcome, which is what you want when the response came from a tenant
with no report-only policies at all.

```yaml
Type: System.String[]
DefaultValue: $script:ProjectedStates
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 4
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ScenarioName

[System.String] (Optional, No Pipeline Support)

A label for the sign-in this response describes, carried onto the output so a batch of outcomes
stays readable. Something like 'jeff/office365/ios/noncompliant'.

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

### -SignInCondition

[System.Object] (Optional, No Pipeline Support)

The signInConditions object that was sent to the evaluate endpoint, if you still have it.
Supplying it turns "this promotion adds a requirement" into "this promotion locks this persona
out", by checking each requirement against the device state that was simulated.

Business Context: The API reports that a policy requiring a compliant device applies, whether
or not the simulated device is compliant, so an outcome read from the response alone
understates a lockout as a mild extra requirement.

Each rule rests on a documented Microsoft constraint: legacy authentication clients support
neither MFA nor device state, device code flow cannot pass device state, approved client app is
iOS and Android only, hybrid join is Windows only. What the request cannot decide - whether a
user has registered a method or accepted terms of use
- is reported as unknown rather than guessed at, because an invented lockout costs more than a
  missed one.

```yaml
Type: System.Object
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WhatIfResult

[System.Object] (Mandatory, Accepts Pipeline Input)

The What If response, in any shape it arrives in: a JSON string, the OData envelope with its
value property, or the already-unwrapped collection of policy results.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Object

A What If response, bound to **-WhatIfResult** from the pipeline. Accepts the raw JSON string
`Invoke-MgGraphRequest -OutputType Json` returns, the hashtable `-OutputType Hashtable`
returns, a deserialized object, the `{ value = [...] }` envelope or the bare collection Maester
hands back already unwrapped. A response fetched with `appliedPoliciesOnly = $true` is folded,
but the projection is only as complete as the policies it contains.

## OUTPUTS

### CaOutcome.Result

One object per response. `Scenario` carries **-ScenarioName**. `Current` is the outcome the
tenant enforces today and `Projected` the outcome after every report-only policy is promoted;
each carries `Access` (`Granted`, `GrantedWithControls` or `Blocked`), `BlockedBy`,
`RequiredControls`, `OptionalChoices`, `UnsatisfiableRequirements`, `AuthenticationStrengths`,
`IsEffectivelyBlocked`, `SessionControls`, `SessionConflicts` and `AppliedPolicies`. `Delta`
compares the two, with `HasChange`, `BecomesEffectivelyBlocked`, the added and removed
controls, strengths and session controls, and a one-line `Summary`. `PolicyCount` is the number
of policies in the response and `ReportOnlyApplying` the number of report-only policies that
applied - when it is 0 the two worlds are identical by construction, not because the promotion
is safe.

## NOTES

Author: Jeffrey Stuhr Blog: https://www.techbyjeff.net LinkedIn:
https://www.linkedin.com/in/jeffrey-stuhr-034214aa/

The Conditional Access What If API is in beta and its shape may change. Everything this module
reads from a response - state, policyApplies, grantControls, sessionControls - is documented
for whatIfAnalysisResult, but a beta response is not a contract.

## RELATED LINKS

- [Conditional Access What If -
  evaluate](https://learn.microsoft.com/en-us/graph/api/conditionalaccessroot-evaluate?view=graph-rest-beta)
- [Invoke-CaScenarioMatrix]()
- [Compare-CaBaseline]()
- [about_CaOutcome]()
