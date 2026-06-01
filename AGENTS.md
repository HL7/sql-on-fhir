# Repository Guidelines

## Overview

- Main repository for the SQL on FHIR (v2) specification.
- Published at https://sql-on-fhir.org/ as an HL7 FHIR Implementation Guide.
- Built with the HL7 FHIR IG Publisher and FSH/SUSHI.
- The JavaScript reference implementation, the shared JSON test suite and the
  test report site live in a separate repository:
  https://github.com/FHIR/sql-on-fhir.js.

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
