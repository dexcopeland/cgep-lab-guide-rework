#!/usr/bin/env bash
# Assemble .wiki-build/ for GitHub Wiki publish.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_WIKI="$ROOT/wiki-source"
OUT="$ROOT/.wiki-build"

rm -rf "$OUT"
mkdir -p "$OUT"

if [[ ! -d "$SRC_WIKI" ]]; then
  echo "error: missing wiki-source/ directory" >&2
  exit 1
fi

cp "$SRC_WIKI"/*.md "$OUT/"

# source_file|wiki_page_basename (without .md)
LAB_MAP=(
  "02_03_first_compliant_resource_rework.md|Lab-2.3-First-Compliant-Resource"
  "02_04_terraform_modules_for_compliance_rework.md|Lab-2.4-Terraform-Modules-for-Compliance"
  "02_05_iac_as_compliance_evidence_rework.md|Lab-2.5-IaC-as-Compliance-Evidence"
  "03_03_writing_compliance_policies_rego_rework.md|Lab-3.3-Writing-Compliance-Policies-Rego"
  "03_04_integrating_pac_with_terraform_rework.md|Lab-3.4-Integrating-PaC-with-Terraform"
  "04_03_grc_evidence_pipeline_rework.md|Lab-4.3-GRC-Evidence-Pipeline"
  "04_04_evidence_chain_of_custody_rework.md|Lab-4.4-Evidence-Chain-of-Custody"
  "05_02_aws_security_services_rework.md|Lab-5.2-AWS-Security-Services"
  "05_04_gcp_security_services_rework.md|Lab-5.4-GCP-Security-Services"
  "06_01_introduction_to_oscal_rework.md|Lab-6.1-Introduction-to-OSCAL"
  "07_01_capstone_companion_rework.md|Lab-7.1-Capstone-Companion"
)

rewrite_lab_page() {
  local src="$1"
  local dest="$2"
  local source_name
  source_name="$(basename "$src")"

  {
    echo "<!-- Generated from ${source_name}. Edit the source file in the main repo; do not edit this page in the Wiki UI. -->"
    echo
    # Rewrite getting-started markdown links (tools + repo-structure variants)
    sed -E \
      -e 's|\[([^]]+)\]\(\.\./getting-started/tools\.md\)|[[Getting-Started]]|g' \
      -e 's|\[([^]]+)\]\(\.\./getting-started/repo-structure\.md\)|[[Getting-Started]]|g' \
      "$src"
  } > "$dest"
}

for entry in "${LAB_MAP[@]}"; do
  src_name="${entry%%|*}"
  page_name="${entry##*|}"
  src_path="$ROOT/$src_name"
  if [[ ! -f "$src_path" ]]; then
    echo "error: missing mapped lab source: $src_name" >&2
    exit 1
  fi
  rewrite_lab_page "$src_path" "$OUT/${page_name}.md"
done

echo "Built wiki staging dir: $OUT"
