# CaOutcome

Folds a Conditional Access What If response into the outcome a sign-in actually meets - today, and
after the tenant's report-only policies are promoted - runs that across a persona matrix, and diffs
a run against a committed baseline. Published to the PowerShell Gallery.

## Where the conventions live

General PowerShell conventions - module structure, help, Pester, PlatyPS, error handling - come
from [ai-powershell-standards](https://github.com/fadwen/ai-powershell-standards) and are mirrored
into this repository by `.github/workflows/sync-copilot-standards.yml`:

- `.github/copilot-instructions.md`
- `.github/instructions/`
- `.github/prompts/`
- `.claude/rules/powershell-standards/`
- `powershell-standards/`

**Those paths are mirrored with `rm -rf` + `cp`.** A local edit there is silently reverted on the
next sync. Changes belong upstream in the standards repository.

This file is outside the mirror, so it is the right place for anything specific to this module.
What follows is *not* general convention - it is the set of local invariants that look wrong or
arbitrary until you know why, and that are cheap to break by accident.

## Invariants

### `RequiredModules` is empty, and a contract test enforces it

`Invoke-CaScenarioMatrix` does call Graph, but only through its default request handler, which
looks for `Invoke-MgGraphRequest` at run time and says so if it is missing. Every other command is
a pure transform. Declaring the Graph SDK would make the whole module unimportable - and the suite
unrunnable - on a host that only ever needed the fold. `-RequestHandler` is the seam: tests replay
recorded responses through it, and callers can route through their own transport.

### Windows PowerShell 5.1 is a real target

The manifest declares `CompatiblePSEditions = Desktop, Core` and the root module carries
`#Requires -Version 5.1`. A ternary, `??`, `ForEach-Object -Parallel` or `Join-Path` with more than
one child path parses fine on 7 and breaks every command on 5.1. The `desktop` job in
`quality-gates.yml` runs the suite under 5.1 to catch exactly that.

### Every read of a response goes through `Get-CaProperty`

Graph hands back hashtables or PSObjects depending on the caller's `-OutputType`, and they are not
interchangeable: indexing a PSObject with a key silently returns nothing. A direct `.property` or
`['key']` read on response data computes an outcome from nulls without any error. Use
`Get-CaProperty` for anything that came from Graph or from a baseline file.

### The two worlds are defined once, in the root module

`$script:CurrentStates` and `$script:ProjectedStates` in `CaOutcome.psm1` are the policy states that
make up each world, and `ConvertTo-CaOutcome` uses them as parameter defaults. They are assigned
after the functions are dot-sourced, which is fine because defaults are evaluated at call time.

### Baselines are deterministic and carry no timestamp

Everything written by `Export-CaBaseline` is sorted, and no generated-on field exists, so a run that
changed nothing rewrites the file byte for byte and the only thing that ever appears in its diff is
a changed outcome. Adding a timestamp, or an unsorted collection, makes every run a diff and teaches
people to stop reading it.

### A failed scenario is never recorded as absent

`Invoke-CaScenarioMatrix` returns a failed scenario marked `Failed` rather than dropping it,
`Export-CaBaseline` refuses a run containing one unless `-Force`, and `Compare-CaBaseline` reports a
scenario missing from a run as `Missing`, not removed. All three exist so a transient HTTP error can
never read as a policy change.

### Satisfiability rules need a documented Microsoft constraint

`Get-CaControlSatisfiability` only marks a control unsatisfiable when a Microsoft document says the
simulated sign-in cannot produce it. Anything inferred stays `Unknown`. There is a test pinning that
a `windowsHelloForBusiness`-only strength is *not* ruled out on iOS, because that combination also
covers platform credentials. A missed lockout is a finding not made; an invented one teaches the
reader to ignore the field.

### The fixtures are real responses

`Tests/Fixtures/*.json` are genuine What If responses with directory object ids rewritten to
synthetic ones. Microsoft's well-known ids are preserved, because rewriting them would describe a
tenant that cannot exist. Keep new fixtures real in the same way: every defect found during
development came from a shape the API returned, not one anybody imagined.

### The Maester template stays a `.template`

`Examples/ContosoCaOutcome.Tests.ps1.template` uses Pester 5 assertions because that is what
Maester runs, and needs a connected tenant. The extension keeps it out of `Invoke-Pester ./Tests`
and out of PSScriptAnalyzer.

### The MAML filename carries a capital H

`en-US/CaOutcome-Help.xml`, matching every `.EXTERNALHELP CaOutcome-Help.xml` keyword in `Public/`.
`Export-MamlCommandHelp` produces that name while most documentation writes `-help.xml`. On Windows
the mismatch is invisible; on a case-sensitive filesystem `Get-Help` silently falls back to a
reflected stub and every command loses its help. The `help` job in `quality-gates.yml` runs on
Linux for this reason, and `Build-Help.ps1` asserts the produced name rather than assuming it.

### Help is compiled, and stale help beats correct help

`docs/CaOutcome/*.md` is the source; `en-US/CaOutcome-Help.xml` is the artifact. After editing
anything under `docs/`, run `./Build/Build-Help.ps1` and commit the rebuilt MAML in the same change.
CI compares a fresh build against the committed file byte for byte, with PlatyPS pinned to 1.0.3 so
that comparison is stable.

After changing a public function's signature, refresh the Markdown with
`Update-MarkdownCommandHelp` rather than editing the syntax or parameter blocks by hand. Put detail
in the Markdown, not the function's comment block: `.EXTERNALHELP` makes `Get-Help` ignore
everything in that block but the keyword.

### Never `Publish-PSResource -Path .`

This repository *is* the module root, so packaging it directly ships the whole working tree,
including `.git`, the tests and their tenant-derived fixtures. Gallery versions can never be
deleted, only unlisted, and the `.nupkg` stays downloadable afterwards.

Always publish through `Build/Publish-Module.ps1`, which stages an **allowlist** into a git-ignored
`out/`. A new folder does not ship until it is named in `$shipFiles` or `$shipFolders`. It then
imports the staged copy in a fresh process, folds a recorded fixture, and checks every command
serves its help before anything is uploaded.

### `$WhatIfPreference` is inherited by child scopes

Under `Publish-Module.ps1 -WhatIf`, the preference reaches the staging cmdlets and `Build-Help.ps1`.
Staging cmdlets are pinned `-WhatIf:$false` and the help build runs with the preference cleared,
or the rehearsal copies and compiles nothing and stops verifying what it exists to verify. Only the
publish itself is gated by `ShouldProcess`.

### Empty manifest URI keys break the pack

`IconUri = ''` is not "no icon" - NuGet aborts with `IconUrl cannot be empty`, naming neither the
manifest nor the key. Same for `HelpInfoURI`. Omit the key entirely. `Publish-Module.ps1` checks.

### Releases are tag-driven and the tag must match the manifest

Bump `ModuleVersion`, update `CHANGELOG.md` and the manifest's `ReleaseNotes`, then
`git tag v<ModuleVersion> && git push origin v<ModuleVersion>`. `.github/workflows/release.yml`
re-runs every gate, rejects a tag that disagrees with the manifest, stages, verifies and publishes.
The API key is the `PSGALLERY_API_KEY` repository secret, passed as an environment variable.
Locally the script resolves `-ApiKey`, then `$env:PSGALLERY_API_KEY`, then a SecretManagement
secret named `PSGallery-ApiKey`.

## Checks

```powershell
Invoke-Pester ./Tests                   # 204 pass, 6 skip without a Graph connection
Invoke-ScriptAnalyzer -Path . -Recurse -Severity Error, Warning
./Build/Build-Help.ps1                  # rebuild MAML after editing docs/
./Build/Publish-Module.ps1 -WhatIf      # full release rehearsal, publishes nothing
```
