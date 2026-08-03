# CGEP lab guide rework

Reworked Capstone GRC Engineering Pathway (CGEP) lab guides for the GRC Engineering Club.

## Wiki

The student-facing multi-page guide lives in this repository’s
[GitHub Wiki](https://github.com/dexcopeland/cgep-lab-guide-rework/wiki).

| Content | Source of truth |
|---|---|
| Lab pages | Root `*_rework.md` files |
| Home, Getting Started, Glossary, Additional Resources, Sidebar | `wiki-source/` |

Do **not** edit lab pages in the Wiki UI — they are regenerated and overwritten on publish.

## Local wiki build

```bash
./scripts/test-build-wiki.sh
# staging output: .wiki-build/ (gitignored)
```

## Publishing

On push to `main` (lab guides, `wiki-source/`, or build scripts), the
`Publish wiki` GitHub Action builds `.wiki-build/` and syncs it with
`Andrew-Chen-Wang/github-wiki-action` pinned to commit `1bbb428` (v5.0.6).

You can also run the workflow manually via **Actions → Publish wiki → Run workflow**.

### One-time prerequisite

GitHub only creates the `*.wiki.git` backend after the first Wiki page exists.
If publish fails on a missing wiki repo, open the Wiki tab once and create any
starter page, then re-run the workflow.

### Token note

The workflow uses `permissions: contents: write` with the default
`GITHUB_TOKEN`. If your org blocks wiki pushes from that token, add a PAT with
repo access as a secret and set `token: ${{ secrets.WIKI_TOKEN }}` on the
publish step.
