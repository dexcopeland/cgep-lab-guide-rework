# Glossary

Alphabetical terms used across the CGEP labs. Lab pages are the source of deeper walkthroughs.

## AWS CLI

Command-line interface for AWS APIs. Terraform borrows credentials from a configured CLI profile (labs use `--profile default` unless you renamed it).

See: [[Getting-Started]], [[Lab-2.3-First-Compliant-Resource]]

## AWS Config

AWS service that records resource configuration over time and can evaluate rules continuously.

See: [[Lab-5.2-AWS-Security-Services]]

## CMEK

Customer-managed encryption key — a key you control (for example in Cloud KMS) used to encrypt data at rest instead of a provider-managed default.

See: [[Lab-2.4-Terraform-Modules-for-Compliance]], [[Lab-3.3-Writing-Compliance-Policies-Rego]]

## Catalog

In OSCAL, a library of controls (for example NIST SP 800-53). Profiles select controls from catalogs.

See: [[Lab-6.1-Introduction-to-OSCAL]]

## Chain of custody

Properties that keep evidence trustworthy over time: integrity, authenticity/timestamp, and preservation (for example Object Lock retention).

See: [[Lab-4.4-Evidence-Chain-of-Custody]]

## CloudTrail

AWS account activity log of API calls and related events; foundation for continuous monitoring evidence.

See: [[Lab-5.2-AWS-Security-Services]]

## Component Definition

OSCAL model describing how a software/infrastructure component implements specific controls, often with links to evidence.

See: [[Lab-6.1-Introduction-to-OSCAL]]

## compliance-trestle

NIST's Python toolkit for authoring and validating OSCAL content (`pip install compliance-trestle`).

See: [[Lab-6.1-Introduction-to-OSCAL]]

## Conftest

Policy runner that evaluates Rego against structured inputs such as `terraform show -json` plans; used as the local/CI gate.

See: [[Lab-3.4-Integrating-PaC-with-Terraform]], [[Lab-4.3-GRC-Evidence-Pipeline]]

## Cosign / Sigstore

Keyless (or keyed) signing tooling used to sign evidence bundles so authenticity can be verified later.

See: [[Lab-2.5-IaC-as-Compliance-Evidence]], [[Lab-4.4-Evidence-Chain-of-Custody]]

## Evidence vault

S3 bucket (with Object Lock in these labs) that stores signed compliance evidence artifacts outside day-to-day scratch space.

See: [[Lab-2.5-IaC-as-Compliance-Evidence]], [[Lab-4.4-Evidence-Chain-of-Custody]]

## GitHub Actions

GitHub-hosted CI that runs workflows from `.github/workflows/` on events such as pull requests.

See: [[Lab-4.3-GRC-Evidence-Pipeline]]

## Google Cloud CLI (`gcloud`)

Command-line interface for GCP; used in GCP labs for verify/cleanup commands.

See: [[Getting-Started]], [[Lab-2.4-Terraform-Modules-for-Compliance]]

## IaC evidence

Machine-readable proof captured from infrastructure tooling (plans, state snapshots, scanner outputs) instead of screenshots.

See: [[Lab-2.3-First-Compliant-Resource]], [[Lab-2.5-IaC-as-Compliance-Evidence]]

## NIST 800-53

NIST SP 800-53 control catalog commonly referenced by the labs (for example SC-28, AC-3, AU-3, CM-6).

See: [[Lab-2.3-First-Compliant-Resource]], [[Lab-3.3-Writing-Compliance-Policies-Rego]]

## Object Lock

S3 feature that enforces WORM retention (COMPLIANCE or GOVERNANCE mode) so evidence objects cannot be quietly altered or deleted early.

See: [[Lab-2.5-IaC-as-Compliance-Evidence]], [[Lab-4.4-Evidence-Chain-of-Custody]]

## OIDC (GitHub → AWS)

OpenID Connect trust so GitHub Actions can assume an AWS IAM role without long-lived access keys.

See: [[Lab-4.3-GRC-Evidence-Pipeline]]

## OPA (Open Policy Agent)

Policy engine that evaluates Rego. Local `opa test` / `opa eval` and Conftest both sit in this ecosystem.

See: [[Lab-3.3-Writing-Compliance-Policies-Rego]]

## OSCAL

NIST's machine-readable format for catalogs, profiles, components, and assessment artifacts — documentation that can be traversed and validated.

See: [[Lab-6.1-Introduction-to-OSCAL]]

## Policy as Code

Expressing compliance/security rules as executable policies checked automatically against infrastructure definitions or plans.

See: [[Lab-3.3-Writing-Compliance-Policies-Rego]], [[Lab-3.4-Integrating-PaC-with-Terraform]]

## Profile

OSCAL model that selects and tailors a subset of controls from one or more catalogs.

See: [[Lab-6.1-Introduction-to-OSCAL]]

## Rego

OPA's policy language. Labs write `deny` rules that fail non-compliant Terraform plans.

See: [[Lab-3.3-Writing-Compliance-Policies-Rego]]

## Security Hub

AWS service that aggregates findings and maps them to standards/controls (including NIST).

See: [[Lab-5.2-AWS-Security-Services]]

## Terraform

HashiCorp tool that declares cloud resources as code (`.tf`) and applies them through providers.

See: [[Getting-Started]], [[Lab-2.3-First-Compliant-Resource]]

## tfsec / Trivy

Static scanners for Terraform misconfigurations. The pipeline lab uses tfsec; Trivy (`trivy config`) is the supported successor with overlapping checks.

See: [[Lab-4.3-GRC-Evidence-Pipeline]]
