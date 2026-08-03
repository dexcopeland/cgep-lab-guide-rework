#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BUILD="$ROOT/.wiki-build"
rm -rf "$BUILD"

"$ROOT/scripts/build-wiki.sh"

expected_pages=(
  Home.md
  Getting-Started.md
  Glossary.md
  Additional-Resources.md
  _Sidebar.md
  Lab-2.3-First-Compliant-Resource.md
  Lab-2.4-Terraform-Modules-for-Compliance.md
  Lab-2.5-IaC-as-Compliance-Evidence.md
  Lab-3.3-Writing-Compliance-Policies-Rego.md
  Lab-3.4-Integrating-PaC-with-Terraform.md
  Lab-4.3-GRC-Evidence-Pipeline.md
  Lab-4.4-Evidence-Chain-of-Custody.md
  Lab-5.2-AWS-Security-Services.md
  Lab-5.4-GCP-Security-Services.md
  Lab-6.1-Introduction-to-OSCAL.md
  Lab-7.1-Capstone-Companion.md
)

for page in "${expected_pages[@]}"; do
  test -f "$BUILD/$page" || { echo "FAIL: missing $page"; exit 1; }
done

# Getting-started relative links must be rewritten on a lab that has them
if grep -q '../getting-started/' "$BUILD/Lab-2.4-Terraform-Modules-for-Compliance.md"; then
  echo "FAIL: unre-written getting-started link in Lab 2.4 wiki page"
  exit 1
fi
grep -q '\[\[Getting-Started\]\]' "$BUILD/Lab-2.4-Terraform-Modules-for-Compliance.md" \
  || { echo "FAIL: expected [[Getting-Started]] rewrite in Lab 2.4"; exit 1; }

# Generated lab pages carry a do-not-edit banner
grep -q 'do not edit this page in the Wiki UI' "$BUILD/Lab-2.3-First-Compliant-Resource.md" \
  || { echo "FAIL: missing do-not-edit banner on Lab 2.3"; exit 1; }

# Authored pages are copied through
grep -qi 'glossary' "$BUILD/Glossary.md" \
  || { echo "FAIL: Glossary.md looks empty/wrong"; exit 1; }

# GitHub/Gollum pipe links are [[Label|Page]], not MediaWiki [[Page|Label]]
grep -q '\[\[2.3 First Compliant Resource|Lab-2.3-First-Compliant-Resource\]\]' "$BUILD/_Sidebar.md" \
  || { echo "FAIL: sidebar must use Gollum [[Label|Page]] order"; exit 1; }
if grep -q '\[\[Lab-2.3-First-Compliant-Resource|' "$BUILD/_Sidebar.md"; then
  echo "FAIL: sidebar still uses MediaWiki [[Page|Label]] order"
  exit 1
fi

echo "PASS: wiki build smoke checks"
