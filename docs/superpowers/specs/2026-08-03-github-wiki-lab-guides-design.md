# GitHub Wiki Lab Guides — Design Spec

**Date:** 2026-08-03  
**Repo:** `dexcopeland/cgep-lab-guide-rework`  
**Status:** Approved for planning (pending final user review of this document)

## Goal

Publish the CGEP lab guides as a native GitHub Wiki with:

- A **Getting Started** section
- Lab pages derived from the existing `*_rework.md` sources
- An **Appendix / Glossary** with hyperlinks to relevant wiki content
- An **Additional Resources** section with curated YouTube (and official docs) links for Terraform, OSCAL, OPA, AWS CLI, and other lab concepts
- Easy deployment via a GitHub Action that syncs from the main repo

## Decisions (locked)

| Decision | Choice |
|---|---|
| Hosting | Native GitHub Wiki (repo wiki already enabled) |
| Theming | GitHub default styling only — no custom dark/orange CSS (Wiki cannot host custom CSS) |
| Page split | Multi-page: Home, Getting-Started, one page per lab, Glossary, Additional-Resources, `_Sidebar` |
| Source of truth | Root `*_rework.md` files remain lab sources; Getting Started / Glossary / Resources / Home / Sidebar are authored separately; Action generates and publishes wiki pages |
| Deploy approach | Staged wiki build + sync Action on push to `main` (Option 1) |

## Information architecture

| Wiki page | Source |
|---|---|
| `Home` | `wiki-source/Home.md` |
| `Getting-Started` | `wiki-source/Getting-Started.md` |
| `Lab-2.3-First-Compliant-Resource` | `02_03_first_compliant_resource_rework.md` |
| `Lab-2.4-Terraform-Modules-for-Compliance` | `02_04_terraform_modules_for_compliance_rework.md` |
| `Lab-2.5-IaC-as-Compliance-Evidence` | `02_05_iac_as_compliance_evidence_rework.md` |
| `Lab-3.3-Writing-Compliance-Policies-Rego` | `03_03_writing_compliance_policies_rego_rework.md` |
| `Lab-3.4-Integrating-PaC-with-Terraform` | `03_04_integrating_pac_with_terraform_rework.md` |
| `Lab-4.3-GRC-Evidence-Pipeline` | `04_03_grc_evidence_pipeline_rework.md` |
| `Lab-4.4-Evidence-Chain-of-Custody` | `04_04_evidence_chain_of_custody_rework.md` |
| `Lab-5.2-AWS-Security-Services` | `05_02_aws_security_services_rework.md` |
| `Lab-5.4-GCP-Security-Services` | `05_04_gcp_security_services_rework.md` |
| `Lab-6.1-Introduction-to-OSCAL` | `06_01_introduction_to_oscal_rework.md` |
| `Lab-7.1-Capstone-Companion` | `07_01_capstone_companion_rework.md` |
| `Glossary` | `wiki-source/Glossary.md` |
| `Additional-Resources` | `wiki-source/Additional-Resources.md` |
| `_Sidebar` | `wiki-source/_Sidebar.md` |

Page names above are the canonical wiki filenames (GitHub Wiki uses the filename stem as the page title/slug). The build script owns a single mapping table from source file → wiki page name so renames stay explicit.

### Home

- Short GRC Engineering Club / CGEP framing
- Recommended path: Getting Started → labs in numeric order → Capstone
- Links to Glossary and Additional Resources
- Table of contents linking every lab page

### Getting-Started

Extracted primarily from Lab 2.3 Parts 1–2:

- Required tools (Git Bash, Terraform, AWS CLI; preview of gcloud, OPA, Cosign)
- Platform notes (Windows Git Bash, Mac/Linux)
- AWS CLI profile guidance (`default`, and how to substitute)
- Canonical `cgep-labs` repo structure and `.gitignore` guidance

Lab 2.3 retains its full walkthrough. Cross-lab “Before you begin” links that currently point at `../getting-started/tools.md` and `../getting-started/repo-structure.md` are rewritten to `[[Getting-Started]]` during the wiki build.

### Glossary (Appendix)

Alphabetical glossary of course terms, each with:

- A short definition
- Wiki links to the lab page(s) that teach or use the term

Initial term set (non-exhaustive; expand during implementation as needed):

Terraform, AWS CLI, Google Cloud CLI (`gcloud`), OPA (Open Policy Agent), Rego, Conftest, Policy as Code, NIST 800-53, OSCAL, compliance-trestle, Component Definition, Profile, Catalog, evidence vault, Object Lock, Cosign / Sigstore, chain of custody, OIDC (GitHub → AWS), CloudTrail, AWS Config, Security Hub, CMEK, tfsec / Trivy, GitHub Actions, IaC evidence.

Labs may link first-use or high-value term mentions to glossary anchors (e.g. `[[Glossary#OSCAL|OSCAL]]`) via a curated rewrite list in the build script—not every occurrence of every word.

### Additional-Resources

Grouped by topic. Prefer official or high-signal YouTube videos plus primary docs. Each item includes a one-line “why this helps.” Topics:

- Terraform / IaC
- AWS CLI
- OPA / Rego / Conftest
- OSCAL / trestle
- GitHub Actions and OIDC
- Evidence signing (Cosign / Sigstore)
- AWS security services (CloudTrail, Config, Security Hub)
- GCP security / org policy / Workload Identity Federation (as covered in labs)

### Sidebar

`_Sidebar.md` provides left-nav: Home, Getting Started, Labs (ordered), Glossary, Additional Resources.

## Repo layout

```
*_rework.md                 # lab source of truth (existing)
wiki-source/
  Home.md
  Getting-Started.md
  Glossary.md
  Additional-Resources.md
  _Sidebar.md
scripts/
  build-wiki.sh             # assemble staging dir
.github/workflows/
  publish-wiki.yml          # build + push to wiki.git
README.md                   # brief pointer to wiki + publish notes
```

## Build pipeline

### `scripts/build-wiki.sh`

Creates a clean staging directory (e.g. `.wiki-build/`):

1. Copy `wiki-source/*.md` unchanged
2. For each mapped lab source, write the wiki page file
3. Rewrite known relative getting-started links to `[[Getting-Started]]`
4. Optionally apply curated glossary-term link injections
5. Prepend a short HTML comment banner on generated lab pages: source filename and “edit the source file in the main repo; do not edit this page in the Wiki UI”
6. Exit non-zero if a mapped source file is missing

The script must be runnable locally for dry-runs without network access.

### `.github/workflows/publish-wiki.yml`

- **Triggers:**
  - `push` to `main` when paths match `*_rework.md`, `wiki-source/**`, `scripts/build-wiki.sh`, or the workflow file
  - `workflow_dispatch` for manual republish
- **Jobs:**
  1. Checkout repo
  2. Run `scripts/build-wiki.sh`
  3. Publish staging directory to the repository wiki using a maintained wiki-publish action (preferred: `Andrew-Chen-Wang/github-wiki-action` or equivalent thin clone/push)
- **Permissions:** `contents: write` when sufficient; if `GITHUB_TOKEN` cannot push to `wiki.git`, document use of a fine-scoped PAT stored as a repo secret
- **Prerequisite:** Wiki must be initialized once via the GitHub Wiki UI (create any starter page) so `https://github.com/<owner>/<repo>.wiki.git` exists. Repo already has `hasWikiEnabled: true`.

### Data flow

```
push to main
    → publish-wiki.yml
        → build-wiki.sh (labs + wiki-source → .wiki-build/)
            → wiki-publish action → <repo>.wiki.git
                → live GitHub Wiki pages
```

## Styling

Native GitHub Wiki Markdown rendering only. No custom CSS, themes, or HTML/CSS overlays. Brand voice stays in copy (Home framing, sidebar labels); visual theme follows GitHub’s default wiki chrome.

## Error handling

| Failure | Behavior |
|---|---|
| Wiki never initialized | Publish step fails; workflow log / README explain one-time Wiki UI init |
| Missing mapped lab source | `build-wiki.sh` fails before publish |
| Link rewrite miss | Relative path may remain; fix via follow-up PR to rewrite rules |
| Token cannot push wiki | Workflow fails; README documents PAT fallback |

## Verification

1. Local: `scripts/build-wiki.sh` produces expected filenames and rewritten getting-started links (smoke assertions in script or a small companion check)
2. After merge to `main`: Action runs; spot-check Home, one lab, Glossary, Additional-Resources on the live wiki
3. Manual `workflow_dispatch` documented for re-publish without content changes

## In scope (first implementation PR)

- Author `wiki-source/` pages listed above
- Lab → wiki page mapping + `scripts/build-wiki.sh`
- `.github/workflows/publish-wiki.yml`
- Getting-started link rewrites; light curated glossary linking
- Curated Additional-Resources links for lab concepts
- Root README note on wiki location and publish flow

## Out of scope

- Custom dark background / orange header CSS
- Auto-generating Glossary or YouTube lists from lab text
- Changing lab pedagogy beyond link targets / optional glossary anchors
- A parallel GitHub Pages or Docsify site
- Deleting or renaming the root `*_rework.md` sources

## Risks and dependencies

- **Wiki init:** First successful Action run depends on an existing wiki git repo (one empty/starter page in UI is enough)
- **Token scope:** Some orgs restrict `GITHUB_TOKEN` from wiki pushes; may need a PAT
- **Wiki UI drift:** Edits made directly in the Wiki UI will be overwritten on the next publish — banner + README should state that clearly
- **YouTube link churn:** Resource URLs may go stale; Additional-Resources is hand-maintained so updates are normal PRs
