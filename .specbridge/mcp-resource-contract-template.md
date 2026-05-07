# MCP Resource Contract Template

## Resource Metadata

- resource_name:
- uri_pattern:
- owner_system:
- version:
- status:
- sensitivity:

## Purpose

Describe what information this resource exposes.

## Resource Type

Examples:

- catalog
- manifest
- schema
- summary
- report
- reference document

## URI Pattern

Define the URI pattern consumers should use.

```text
specbridge://...
```

## Content Type

Define the content type.

Examples:

- text/markdown
- application/json
- text/plain

## Source Of Truth

Define where the information comes from.

## Refresh Behavior

Define whether the resource is static, generated, cached, or live.

## Permission Model

Define who may read the resource.

## Data Sensitivity

Define whether the resource may include:

- public information
- internal information
- confidential information
- secrets

Secrets are not allowed in MCP resources.

## Expected Consumers

Define which agents or workflows may consume this resource.

## Limitations

Define known limitations, staleness risks, or missing coverage.

## Provenance Requirements

Resources should preserve source references where relevant.

## Examples

Provide example URIs and expected output shape.
