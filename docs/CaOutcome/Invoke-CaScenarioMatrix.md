---
document type: cmdlet
external help file: CaOutcome-Help.xml
HelpUri: https://github.com/fadwen/CaOutcome/blob/main/docs/CaOutcome/Invoke-CaScenarioMatrix.md
Locale: en-US
Module Name: CaOutcome
ms.date: 09/25/2026
PlatyPS schema version: 2024-05-01
title: Invoke-CaScenarioMatrix
---

# Invoke-CaScenarioMatrix

## SYNOPSIS

Evaluates a set of scenarios against the tenant and folds each response into an outcome

## SYNTAX

### __AllParameterSets

```
Invoke-CaScenarioMatrix [-Scenario] <Object[]> [[-RequestHandler] <scriptblock>] [[-Uri] <string>]
 [[-MaxRetry] <int>] [[-InitialBackoffSecond] <int>] [[-DelayMillisecond] <int>]
```

## DESCRIPTION

Core Functionality:
Sends one What If evaluation per scenario, folds each response with ConvertTo-CaOutcome, and
returns the outcomes. Throttling and transient failures are retried; a scenario that fails
anyway is returned marked rather than dropped.

Business Value:
This is the step that turns a single what-if check into coverage. The question worth asking is
never "what happens to this user" but "what happens to everybody, and what would promoting the
pilot do to them", and answering it means evaluating a grid rather than a point.

Failures are surfaced, not swallowed, because of what happens downstream. If a scenario that
errored simply vanished from the output, a baseline written from that run would record it as
absent and the next comparison would report it as removed - a real change, invented by a
transient HTTP error. So a failed scenario comes back with Failed set, and Export-CaBaseline
refuses to write a baseline containing one.

Use Cases:
- Running a stored matrix before promoting a report-only policy
- Producing the input for Export-CaBaseline
- A scheduled run whose output feeds Compare-CaBaseline

Dependencies:
- Microsoft.Graph.Authentication, for the default request handler, plus a connection with
  Policy.Read.ConditionalAccess. Checked at run time - supply -RequestHandler and the module
  needs neither.

Side Effects:
None in the tenant. Evaluation is a POST but changes nothing; it is a read that happens to need
a request body.

Important:
One API call per scenario, serially. That is deliberate - the endpoint publishes no throttling
limits, and a matrix run is exactly the traffic shape that finds an unpublished one. Use
-DelayMillisecond to pace a large run.

## EXAMPLES

### Example 1: Runs every scenario in the matrix against the tenant

```powershell
Expand-CaScenario -Matrix $matrix | Invoke-CaScenarioMatrix
```

Output: One outcome per scenario

Duration: About a second per scenario

Use case: The whole grid, before promoting a report-only policy

### Example 2: Paces a large run, then keeps only the personas a promotion would lock out

```powershell
$outcomes = Expand-CaScenario -Matrix $matrix |
    Invoke-CaScenarioMatrix -DelayMillisecond 250
$outcomes | Where-Object { $_.Delta.BecomesEffectivelyBlocked } |
    Select-Object Scenario, @{n='Why';e={$_.Delta.Summary}}
```

Output: One row per persona that stops getting in

Duration: Scenario count times about 1.3 seconds

Use case: The blast radius question, answered before anything is enforced

### Example 3: Replays recorded responses instead of calling Graph

```powershell
Expand-CaScenario -Matrix $matrix |
    Invoke-CaScenarioMatrix -RequestHandler { param($b, $u) $recorded[$b.signInIdentity.userId] }
```

Output: Outcomes folded from the recordings

Duration: Instant

Use case: Testing the matrix and the assertions over it without a tenant

## PARAMETERS

### -DelayMillisecond

[System.Int32] (Optional, No Pipeline Support)

A pause between scenarios. Zero by default; raise it to pace a large matrix rather than
discovering the throttle.

```yaml
Type: System.Int32
DefaultValue: 0
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 5
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -InitialBackoffSecond

[System.Int32] (Optional, No Pipeline Support)

First backoff in seconds, doubling per attempt. A Retry-After from the server wins.

```yaml
Type: System.Int32
DefaultValue: 2
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

### -MaxRetry

[System.Int32] (Optional, No Pipeline Support)

Retries per scenario after a throttle or transient failure. Defaults to 4.

```yaml
Type: System.Int32
DefaultValue: 4
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

### -RequestHandler

[System.Management.Automation.ScriptBlock] (Optional, No Pipeline Support)

A scriptblock taking the request body and the URI and returning the raw response. Defaults to
Invoke-MgGraphRequest.

Business Context: This is the seam that keeps the module dependency-free and testable without a
tenant. It is also how you drive the call through an existing authenticated session, a proxy,
or a recorded fixture.

```yaml
Type: System.Management.Automation.ScriptBlock
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

### -Scenario

[System.Object[]] (Mandatory, Accepts Pipeline Input)

Scenarios from Expand-CaScenario.

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

### -Uri

[System.String] (Optional, No Pipeline Support)

The evaluate endpoint, should a national cloud or a future version need a different one.

```yaml
Type: System.String
DefaultValue: https://graph.microsoft.com/beta/identity/conditionalAccess/evaluate
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Object[]

Scenarios, bound to **-Scenario** from the pipeline - normally the output of
**Expand-CaScenario**, or any object carrying the same `Name`, `UserId`, resource target and
`Conditions` properties.

## OUTPUTS

### CaOutcome.Result

One object per scenario: the **ConvertTo-CaOutcome** result with `Failed` and `Error` added. A
scenario that fails after every retry is returned rather than dropped, with `Failed` set to
`$true`, the message in `Error`, and `Current`, `Projected` and `Delta` null. It is also
written to the error stream so an interactive run is not silent. **Export-CaBaseline** refuses
a run containing a failure unless **-Force** is given, so a transient HTTP error cannot be
recorded as a removed scenario.

## NOTES

Author: Jeffrey Stuhr Blog: https://www.techbyjeff.net LinkedIn:
https://www.linkedin.com/in/jeffrey-stuhr-034214aa/

The default request handler needs Microsoft.Graph.Authentication and a connection with
Policy.Read.ConditionalAccess, and is resolved at run time rather than declared as a module
dependency. Supply **-RequestHandler** and neither is needed.

Scenarios run serially, one API call each. The endpoint publishes no throttling limits, and a
matrix run is the traffic shape that finds an unpublished one.

The Conditional Access What If API is in beta and its shape may change. Everything this module
reads from a response - state, policyApplies, grantControls, sessionControls - is documented
for whatIfAnalysisResult, but a beta response is not a contract.

## RELATED LINKS

- [Conditional Access What If -
  evaluate](https://learn.microsoft.com/en-us/graph/api/conditionalaccessroot-evaluate?view=graph-rest-beta)
- [Expand-CaScenario]()
- [ConvertTo-CaOutcome]()
- [Export-CaBaseline]()
- [about_CaOutcome]()
