The `$viewdefinition-run` operation applies a ViewDefinition to transform FHIR resources into a tabular format and returns the results synchronously.

**Use Cases:**

- Interactive development and debugging of ViewDefinitions
- Real-time data streaming and transformation

**FHIR Versions:**

Operation may work in FHIR R4 compatibility mode or in R6 mode.
In R4 mode, operation can only be on system level ( `{BaseURl}/$viewdefinition-run` ),
for R6 mode operation can appear on type and instance level
(`{BaseURl}/ViewDefinition/$viewdefinition-run` and `{BaseURl}/ViewDefinition/{id}/$viewdefinition-run`).

**Endpoints:**

| Level    | Endpoint                                         | View Source                                        |
| -------- | ------------------------------------------------ | -------------------------------------------------- |
| System   | `[base]/$viewdefinition-run`                     | `viewCanonical`, `viewReference` or `viewResource` |
| Type     | `[base]/ViewDefinition/$viewdefinition-run`      | `viewCanonical`, `viewReference` or `viewResource` |
| Instance | `[base]/ViewDefinition/[id]/$viewdefinition-run` | The ViewDefinition instance named by the path      |

Both `GET` and `POST` are supported; `viewResource` and `resource` require
`POST`.
