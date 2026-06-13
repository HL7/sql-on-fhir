# Repository Guidelines

## Overview

- Main repository for the SQL on FHIR (v2) specification.
- Published at https://sql-on-fhir.org/ as an HL7 FHIR Implementation Guide.
- Built with the HL7 FHIR IG Publisher and FSH/SUSHI.
- The JavaScript reference implementation, the shared JSON test suite and the
  test report site live in a separate repository:
  https://github.com/FHIR/sql-on-fhir.js.

## Constitution

These principles are non-negotiable. They govern how the specification is
written, changed and reviewed. A pull request that violates one of them must
not be merged.

### Core principles

#### I. Portability across SQL engines

Every normative feature of the specification MUST be implementable on
mainstream SQL engines without relying on engine-specific extensions.
ViewDefinition and operation semantics MUST be defined independently of any
particular SQL dialect. SQL examples in spec pages MUST be checked for
cross-dialect portability before merge. Rationale: the entire value of this
specification is portable, tabular projections of FHIR data; a feature that
only works on one engine defeats its purpose.

#### II. Implementation neutrality

The specification MUST NOT privilege any vendor, product, database or
implementation strategy. Normative text MUST NOT require a specific storage
model, query engine or architecture. Where examples mention concrete products
or implementations, they MUST be clearly marked as informative.

#### III. Testable normative behaviour

Every change to normative behaviour MUST be paired with conformance tests in
the shared test suite at https://github.com/FHIR/sql-on-fhir.js, and the spec
pull request MUST link the companion test change. A normative statement that
cannot be exercised by a conformance test SHOULD be reworded until it can be.

#### IV. Backwards compatibility

Anything released as a published version of the specification (see
https://sql-on-fhir.org/ig/history.html) MUST NOT change in ways that break
existing conforming views or implementations without an explicit deprecation
period and a documented migration path. Breaking changes MUST be identified as
such in the pull request description.

#### V. Edit sources only

All changes MUST be made to source files (`input/`, `sushi-config.yaml`,
templates and scripts). Generated directories (`fsh-generated/`, `output/`,
`temp/`, `input-cache/`) MUST NOT be hand-edited or committed.

#### VI. Clean builds

The IG MUST build with zero errors and zero unsuppressed warnings
(`npm run build:ig`, verified by CI from `output/qa.json`) before merge. Each
new suppression added to `input/ignoreWarnings.txt` MUST be justified in the
pull request that introduces it; suppressions are not a substitute for fixing
the underlying problem.

#### VII. Community consensus for normative change

Normative changes MUST be proposed through a public GitHub issue or pull
request and MUST be reviewed by at least one other contributor before merge.
Substantive changes SHOULD be raised in the weekly project meeting or on the
FHIR chat (Analytics on FHIR stream) before being finalised.

#### VIII. Accessible to both audiences

Specification prose MUST be understandable by both SQL practitioners and FHIR
practitioners. Every normative construct MUST be accompanied by at least one
worked example. Domain-specific terms from either world MUST be defined in the
glossary the first time they are relied upon.

### Quality gates

- CI (`.github/workflows/build.yaml`) fails on any IG Publisher error or any
  warning not suppressed via `input/ignoreWarnings.txt`. Reproduce locally
  with `npm run build:ig` and inspect `output/qa.html` before opening a pull
  request.
- Pull requests state purpose, scope and linked issues; page or documentation
  changes include screenshots or links to the rendered output.
- Changes to normative behaviour are not complete until the companion
  conformance tests in sql-on-fhir.js exist and pass against the reference
  implementation.

## Project Structure & Module Organization

- `input/`: IG content (FSH, markdown). Edit spec pages here.
- `sushi-config.yaml`: SUSHI and menu/config for the IG.
- `template/`, `custom-template/`: IG Publisher templates.
- `scripts/`: IG build/update helpers (`_genonce.sh`, `_updatePublisher.sh`).
- `input/ignoreWarnings.txt`: IG Publisher warnings/info to suppress.
- Generated: `fsh-generated/`, `output/`, `temp/`, `input-cache/`. Do not edit by hand.

## Setting Up the Project for IG Build

### Prerequisites

- **Node.js**: 18+ (for npm and SUSHI)
- **Java**: 11+ (for HL7 FHIR IG Publisher)
- **Ruby**: 2.7+ (for Jekyll, required by IG Publisher)
- **curl**: For downloading IG Publisher and dependencies

### Initial Setup

1. **Install Node dependencies:**

   ```bash
   npm install
   ```

2. **Install SUSHI (FSH compiler) globally:**

   ```bash
   npm install -g fsh-sushi
   ```

3. **Install Ruby and Jekyll:**
   - **macOS (via Homebrew):**
     ```bash
     brew install ruby
     export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/4.0.0/bin:$PATH"
     /opt/homebrew/opt/ruby/bin/gem install jekyll bundler
     ```
   - **Linux/WSL:**
     ```bash
     # Use rbenv or rvm for Ruby version management
     gem install jekyll bundler
     ```
   - **Note**: System Ruby (macOS default 2.6.x) is too old; use Homebrew or a version manager.

4. **Download IG Publisher:**
   ```bash
   npm run update:publisher -- -y
   ```
   The `-y` flag skips interactive prompts.

### Troubleshooting IG Build

- **"Cannot run program 'sushi'"**: Install SUSHI globally with `npm install -g fsh-sushi`
- **"Cannot run program 'jekyll'"**: Install Ruby 2.7+ and Jekyll; ensure Jekyll is in PATH
- **Ruby version too old**: Use Homebrew (`brew install ruby`) or rbenv/rvm for newer Ruby
- **Build errors**: Check `output/qa.html` for validation errors after build completes

## Build, Test, and Development Commands

- `npm install`: Install root dependencies.
- `npm run update:publisher -- -y`: Download/refresh HL7 IG Publisher (requires `curl`, Java).
- `npm run build:ig`: Build the Implementation Guide once.
- `npm run build:ig:continuous`: Rebuild on change.
- `npm run serve:ig` / `npm run open:ig`: Serve or open `output/index.html`.
- Manual IG build helpers: `./_updatePublisher.sh` and `./_genonce.sh` (root entry points).

## Coding Style & Naming Conventions

- Indentation: 2 spaces for FSH/JSON/MD.
- Keep generated folders untracked in changes; edit sources only (`input/`).

## Testing Guidelines

- The CI build (`.github/workflows/build.yaml`) builds the IG and fails if the
  IG Publisher reports any errors or any warnings not suppressed via
  `input/ignoreWarnings.txt`. It reads the `errs` and `warnings` counts from
  `output/qa.json`.
- Reproduce locally with `npm run build:ig`, then inspect `output/qa.html`.
- The specification's conformance test suite and reference implementation are
  in https://github.com/FHIR/sql-on-fhir.js.

## Commit & Pull Request Guidelines

- Commits: concise, imperative summaries (e.g., "Add MSSQL test report").
- PRs: include purpose, scope, linked issues, and impact. For IG page or docs
  changes, add screenshots/links.
- Avoid committing `output/`, `fsh-generated/`, `temp/` or `input-cache/`.

## Security & Configuration Tips

- Prereqs: Node 18+, Java 11+, `curl`. IG build may contact `tx.fhir.org`; offline builds pass `-tx n/a` (handled by scripts).
- Do not embed secrets in pagecontent.
