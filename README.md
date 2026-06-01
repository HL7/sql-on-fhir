# SQL on FHIR®

## Introduction

This project provides the source for the SQL on FHIR Implementation Guide.

SQL on FHIR is a specification that defines a standard way to define portable,
tabular projections of FHIR data.

The [FHIR®](https://hl7.org/fhir) standard is a great fit for RESTful and
JSON-based systems, helping make healthcare data liquidity real. This spec aims
to take FHIR usage a step further, making FHIR work well with familiar and
efficient SQL engines and surrounding ecosystems.

We do this by creating simple, tabular _views_ of the underlying FHIR data that
are tailored to specific needs. Views are defined
with [FHIRPath](https://hl7.org/fhirpath/) expressions in a logical structure to
specify things like column names and unnested items.

[**Read the specification &rarr;**](https://sql-on-fhir.org/ig/latest/)

Check the existing [implementations page][] or register your own (see the
[sql-on-fhir.js](https://github.com/FHIR/sql-on-fhir.js) repository).

Check out the [interactive playground][].

[//]: # "Links used in this document"
[interactive playground]: https://sql-on-fhir.org/extra/playground.html
[implementations page]: https://sql-on-fhir.org/extra/impls.html

## Content

Content as markdown is now found in [input/pagecontent](input/pagecontent).
Also see [sushi-config.yaml](sushi-config.yaml) for additional settings,
including configuration for the menu.

## Local Build

This is a Sushi project and can use HL7 IG Publisher to build locally:

### Using npm scripts (recommended)

1. Clone this repository
1. Install dependencies: `npm install`
1. Update the IG publisher: `npm run update:publisher`
1. Build the IG: `npm run build:ig`
1. View the IG: `npm run open:ig`

**Available npm scripts:**

- `npm run update:publisher` - Downloads the latest IG publisher
- `npm run build:ig` - Generates the IG once
- `npm run build:ig:continuous` - Generates the IG continuously (watches for changes)
- `npm run serve:ig` - Serves the built IG using http-server
- `npm run open:ig` - Opens the built IG in your browser

### Manual build process

1. Clone this respository
1. Run `./scripts/_updatePublisher.sh` to get the latest IG publisher
1. Install `sushi` if you don't have it already with: `npm i fsh-sushi`
1. Run `./scripts/_genonce.sh` to generate the IG
1. Run `open output/index.html` to view the IG website
   <details>
     <summary>Instructions for viewing the IG in a local <code>http-server</code>...</summary>

   ```sh
   npm i http-server
   cd output
   http-server  # Will launch the content in a new browser tab.
   ```

</details>

## Reference implementation, tests and tooling

The JavaScript reference implementation, the shared JSON test suite and the test
report site (including the interactive playground) live in a separate
repository:

[**FHIR/sql-on-fhir.js &rarr;**](https://github.com/FHIR/sql-on-fhir.js)

That repository documents how to run the test suite, build a test runner,
publish a test report and register an implementation on the
[implementations page][].
