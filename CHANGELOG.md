# Changelog

All notable changes to this module are recorded here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Nothing yet.

## [0.6.0] - 2026-09-25

The first release from this repository, and the first published to the PowerShell Gallery.
Nothing any command does has changed.

### Added

- **Compiled help.** Every exported command's help is written in PlatyPS Markdown under
  `docs/CaOutcome/` and shipped as `en-US/CaOutcome-Help.xml`, and each function carries
  `.EXTERNALHELP CaOutcome-Help.xml`. `Get-Help <command> -Online` opens the Markdown on GitHub.
  Inputs, outputs and related links, which the comment-based help did not have, are now
  documented for every command.
- **`about_CaOutcome`**, covering the two worlds, the fold, satisfiability, baselines and the
  permissions the default request handler needs.
- **Gallery metadata** - project and license URIs, tags, and release notes in the manifest.
- **Build and release tooling.** `Build/Build-Help.ps1` validates the help Markdown and compiles
  the MAML; `Build/Publish-Module.ps1` stages an allowlist of shipping files, proves the staged
  copy imports, folds a recorded response and serves its help, and publishes. Releases run from
  a `v*` tag through `.github/workflows/release.yml`.
- **CI** runs the suite shuffled on PowerShell 7 on Windows and Linux and on Windows PowerShell
  5.1, gates coverage at 80%, runs PSScriptAnalyzer, and fails when the committed MAML is stale
  or is not served on a case-sensitive filesystem.

### Changed

- **`[OutputType()]` names the type each command returns** - `CaOutcome.Result` from
  `ConvertTo-CaOutcome` and `Invoke-CaScenarioMatrix`, `CaOutcome.Scenario` from
  `Expand-CaScenario`, `CaOutcome.Baseline` from `Export-CaBaseline` and `CaOutcome.Drift` from
  `Compare-CaBaseline` - rather than `[PSCustomObject]`. The objects already carried these type
  names; the attribute now agrees with them, so tab completion works on the output.
- The comment-based help on exported functions is reduced to `.EXTERNALHELP` and a one-line
  synopsis. The full text moved to the Markdown, where it is maintained.

## [0.5.1] - 2026-08-18

### Fixed

- An unresolved session conflict now picks a deterministic winner, so a baseline stays stable
  across runs.

## [0.5.0]

### Added

- Authentication strength combinations are carried through the fold, so a silently edited
  custom strength is caught as drift.

## [0.4.0]

### Added

- Satisfiability widened to legacy authentication, device code flow and platform limits, each
  finding carrying its reason.

## [0.3.0]

### Added

- Scenario matrix runner (`Invoke-CaScenarioMatrix`) and outcome baselining
  (`Export-CaBaseline`, `Compare-CaBaseline`).

## [0.2.0]

### Added

- Matrix expansion (`Expand-CaScenario`) and the request-handler seam.

## [0.1.0]

### Added

- Effective control folding, the promotion diff, and satisfiability (`ConvertTo-CaOutcome`).

[Unreleased]: https://github.com/fadwen/CaOutcome/compare/v0.6.0...HEAD
[0.6.0]: https://github.com/fadwen/CaOutcome/releases/tag/v0.6.0
