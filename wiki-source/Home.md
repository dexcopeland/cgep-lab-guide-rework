# CGEP Lab Guides

Welcome to the **GRC Engineering Club** Capstone GRC Engineering Pathway (CGEP) lab guides.

These labs teach you to express controls in infrastructure-as-code, enforce them with policy-as-code, produce machine-readable evidence in CI, and describe the result in OSCAL — so an assessor can follow the chain without screenshots.

## Recommended path

1. Start with [[Getting-Started]] (tools + `cgep-labs` repo shape)
2. Work the labs in order below
3. Finish with [[Lab-7.1-Capstone-Companion]]
4. Use the [[Glossary]] when a term is unfamiliar
5. Browse [[Additional-Resources]] for deeper learning videos and docs

## Labs

| Lab | Topic |
|---|---|
| [[Lab-2.3-First-Compliant-Resource]] | First compliant AWS S3 resource in Terraform |
| [[Lab-2.4-Terraform-Modules-for-Compliance]] | Reusable GCP compliance modules |
| [[Lab-2.5-IaC-as-Compliance-Evidence]] | Evidence vault and IaC-as-evidence |
| [[Lab-3.3-Writing-Compliance-Policies-Rego]] | Rego policies with OPA (GCP) |
| [[Lab-3.4-Integrating-PaC-with-Terraform]] | Conftest gate on Terraform plans (AWS) |
| [[Lab-4.3-GRC-Evidence-Pipeline]] | GitHub Actions GRC evidence pipeline |
| [[Lab-4.4-Evidence-Chain-of-Custody]] | Cosign signing and chain of custody |
| [[Lab-5.2-AWS-Security-Services]] | CloudTrail, Config, Security Hub baseline |
| [[Lab-5.4-GCP-Security-Services]] | GCP org policy, WIF, audit logs |
| [[Lab-6.1-Introduction-to-OSCAL]] | OSCAL component + profile with trestle |
| [[Lab-7.1-Capstone-Companion]] | Capstone assembly companion |

## Appendix

- [[Glossary]] — terms used across the labs
- [[Additional-Resources]] — YouTube and official docs for key tools

> Lab pages are generated from the `*_rework.md` files in the main repository. Edit those sources (or `wiki-source/` for shared pages), not the Wiki UI — Wiki UI edits are overwritten on the next publish.
