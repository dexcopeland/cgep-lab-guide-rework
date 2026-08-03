# Getting Started

Complete this once before any lab. It covers the tools every guide assumes and the `cgep-labs` repository shape later labs reuse.

If you already have Git Bash (or a native bash shell), Terraform, the AWS CLI, and a pushed `cgep-labs` repo, skip to [[Lab-2.3-First-Compliant-Resource]].

## Part 1: Set up your tools

Skip ahead to Part 2 if you already have Git Bash, Terraform, and the AWS CLI working. If any of those is new to you, read on. Getting this right once saves you from a dozen confusing errors later.

## The tools you need, and where to get them

Every link below points at the official source. Don't install these from random blog mirrors; cloud tooling is exactly the kind of thing you want to get from the vendor.

| Tool | What it does | Official download |
|---|---|---|
| **Git for Windows (Git Bash)** | Gives Windows a Unix-style terminal so every command in these guides runs as written. Mac and Linux already have this. | https://git-scm.com/download/win |
| **Terraform** | Turns your `.tf` files into real cloud resources. The core of every IaC lab. | https://developer.hashicorp.com/terraform/install |
| **AWS CLI v2** | Lets you talk to AWS from the terminal, and lets Terraform authenticate. | https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html |

Three more tools show up in later labs. You don't need them today, but here's where they live so you can install them ahead of time if you like:

| Tool | First used in | Official download |
|---|---|---|
| **Google Cloud CLI (`gcloud`)** | Lab 2.4 (GCP) | https://cloud.google.com/sdk/docs/install |
| **OPA (Open Policy Agent)** | Lab 3.3 (Rego policies) | https://www.openpolicyagent.org/docs and releases at https://github.com/open-policy-agent/opa/releases |
| **Cosign** | Lab 2.5 / Lab 4.4 (signing evidence) | https://docs.sigstore.dev/cosign/system_config/installation/ and releases at https://github.com/sigstore/cosign/releases |

## Windows users: set up Git Bash

These guides are written in bash, the command language that ships with Mac and Linux. On Windows, the closest thing you'll already have is PowerShell, but PowerShell uses different syntax for a lot of these commands. Rather than translate every command, we standardize the whole cohort on **Git Bash**, which gives you a real bash terminal on Windows. When a guide says to run `mkdir -p terraform/primitives/compliant-s3`, you'll be able to paste it exactly as written.

1. Download and run the installer from https://git-scm.com/download/win. Accepting the default options at every screen is fine.
2. After it installs, you'll have a "Git Bash" entry in your Start menu. That's your terminal for these labs.

**Make Git Bash your default terminal in VS Code.** If you use VS Code (recommended), tell it to open Git Bash instead of PowerShell so your integrated terminal matches the guides:

- Open the Command Palette with `Ctrl+Shift+P`.
- Type `Terminal: Select Default Profile` and select it.
- Choose **Git Bash** from the list.
- Open a new terminal (`` Ctrl+` ``). It should now be a Git Bash prompt.

**Run this one config command before you do anything else.** Windows and Unix disagree about how lines end in text files, and that disagreement can silently corrupt shell scripts you'll write in later labs. This setting tells Git to leave your files alone:

```bash
git config --global core.autocrlf input
```

### Git Bash quirks worth knowing now

You probably won't hit these in this lab, but they cause real head-scratching later, so file them away:

- **Mangled paths.** Git Bash tries to be helpful by converting anything that looks like a Unix path (starting with `/`) into a Windows path. That's great for filenames and wrong for things like S3 keys, ARNs, or `file:///...` arguments. If a command fails with a path that looks half-rewritten, run it again with `MSYS_NO_PATHCONV=1` in front, for example `MSYS_NO_PATHCONV=1 aws s3api ...`.
- **`sha256sum` vs `shasum`.** Git Bash ships `sha256sum`. macOS ships `shasum -a 256`. They compute the same hash; later lab scripts detect which one you have automatically.

## Mac and Linux users

You already have bash, so there's nothing extra to install for the terminal itself. Install Terraform and the AWS CLI from the official links above. On Mac, Homebrew is the easy path: `brew install terraform awscli`. On Ubuntu, the install pages above include `apt` instructions.

## Confirm everything works

Open your terminal (Git Bash on Windows) and run each of these. You want a version number back from each one, not a "command not found":

```bash
git --version
terraform version
aws --version
```

If any command isn't found, the tool either didn't install or isn't on your PATH. The official install pages above each have a "verify your installation" section that walks through fixing PATH issues for your OS.

## Connect the AWS CLI to your account

Terraform doesn't log into AWS by itself. It borrows credentials from the AWS CLI. You need a working CLI profile before Terraform will do anything.

- If your sandbox uses a plain access key, run `aws configure` and paste in your key, secret, and default region (`us-east-1` for this lab).
- If your sandbox uses AWS SSO (also called IAM Identity Center), run `aws configure sso` and follow the browser prompts.

Commands in this guide (and later labs) use `--profile default` so you can paste them as-is if you kept the usual AWS CLI profile name. **If you named your profile something else during `aws configure` or `aws configure sso`, replace `default` with that name** wherever you see `--profile default`.

Confirm the CLI can reach your account:

```bash
aws sts get-caller-identity --profile default
```

A JSON blob with your account ID means you're connected.

---

## Part 2: Set up your repository

This is the part that tripped up the last cohort, so we're going to be explicit. Every lab in this course drops files into the same repository, in the same shape. Get the shape right once, here, and the rest of the course just slots into it. Get it wrong, and you'll spend later labs hunting for files that aren't where the guide expects.

## The mental model

You're building **one repository** called `cgep-labs`. It lives in two places at once:

- **On your machine**, as a folder you work in.
- **On GitHub**, as the published copy your instructor reviews.

These aren't two different things. When you `git push`, your local folder becomes the GitHub copy, file for file. So when a guide talks about "the version that gets evaluated," it means your `cgep-labs` repo on GitHub, which is just your local folder after you've pushed it. There's no separate "submission" copy to assemble.

(Your final capstone is a separate repository later on, a fork of the starter app. It uses this exact same structural discipline, so the habits you build here carry straight over.)

## Create the structure

Pick a home for your work (your Documents folder is fine) and build the skeleton — including the empty files this lab will fill in. From your terminal:

```bash
mkdir -p cgep-labs
cd cgep-labs

# Repo-wide folders every later lab reuses
mkdir -p terraform/primitives terraform/modules scripts evidence

# This lab's empty files (matches the diagram below)
mkdir -p terraform/primitives/compliant-s3 evidence/lab-2-3
touch README.md .gitignore \
  terraform/primitives/compliant-s3/main.tf \
  terraform/primitives/compliant-s3/variables.tf \
  terraform/primitives/compliant-s3/outputs.tf \
  terraform/primitives/compliant-s3/README.md

# Confirm the shape
find terraform/primitives/compliant-s3 evidence/lab-2-3 -type f | sort
```

Here's what you just created and what each folder is for:

```
cgep-labs/                        ← repository root. Everything lives under here.
│
├── README.md                     ← what this repo is (you'll create this below)
├── .gitignore                    ← tells Git which files NOT to publish
│
├── terraform/                    ← all your infrastructure-as-code
│   ├── primitives/               ← standalone units you deploy directly
│   │   └── compliant-s3/         ← THIS lab lives here
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── README.md
│   └── modules/                  ← reusable modules (Lab 2.4 fills this in)
│
├── scripts/                      ← shared scripts (Lab 2.5 adds one here)
│
└── evidence/                     ← captured proof, one folder per lab
    └── lab-2-3/                  ← THIS lab's evidence lands here
        ├── plan.json             ← filled in when you capture evidence
        └── state.json            ← filled in when you capture evidence
```

Two ideas are doing all the work in this layout, and they're worth saying out loud:

- **Code and evidence are separate.** Your Terraform lives under `terraform/`. The proof you capture lives under `evidence/`, named by lab. A reviewer can find every artifact for Lab 2.3 in `evidence/lab-2-3/` without digging through your code. This separation is also why a later lab can capture evidence *from* an earlier lab's workspace; the workspace is always `terraform/.../<thing>`, and the evidence always lands in `evidence/lab-X-Y/`.
- **`primitives/` vs `modules/`.** A primitive is something you deploy as-is. A module is a reusable template that other code calls. This lab builds a primitive. Lab 2.4 builds your first module. Keeping them in separate folders keeps that distinction visible.

## Add a `.gitignore` before you commit anything

This step matters more than it looks. When Terraform runs, it creates files you must **not** publish to GitHub:

- `terraform.tfstate` and its backups: Terraform's record of what it built. It can contain sensitive values, and it's specific to your machine.
- The `.terraform/` directory: hundreds of megabytes of downloaded provider plugins. No one needs your copy.
- `.terraform.lock.hcl`: the provider dependency lock. It's useful in a long-lived production repo, but it's not part of this course's submission, so we keep it out to match the checklist exactly.
- `tfplan`: the saved binary plan from `terraform plan -out=tfplan`. It's scratch input for `apply`, not an artifact a reviewer wants.
- `*.tfvars`: where people often put secrets.

A `.gitignore` file tells Git to skip these. Open the empty **`.gitignore`** at the repo root (created in the scaffold above) and paste this in, or overwrite it from the terminal:

```bash
cat > .gitignore << 'EOF'
# Terraform working files (never publish these)
.terraform/
.terraform.lock.hcl
*.tfstate
*.tfstate.*
*.tfvars
tfplan
*.tfplan
crash.log

# OS noise
.DS_Store
EOF
```

Notice what this does *not* ignore: your `evidence/` folder. The files in there are named `plan.json` and `state.json`, not `*.tfstate`, so they sail right past these rules. That's deliberate. The live state file is private working data; the evidence snapshot is the artifact you *want* reviewed. Same data, captured for two different purposes, treated two different ways. Understanding that distinction is half of what this course is about.

## Initialize Git and push to GitHub

```bash
git init
git add .
git commit -m "Scaffold cgep-labs repo structure"
```

Then create an empty repository named `cgep-labs` on GitHub (don't let GitHub add a README or .gitignore, since you already have them), and connect it:

```bash
git remote add origin https://github.com/<your-username>/cgep-labs.git
git branch -M main
git push -u origin main
```

From now on, finishing a lab means committing your new files and running `git push`. That published copy is what gets reviewed.

---

## What's next

Continue with [[Lab-2.3-First-Compliant-Resource]]. Unfamiliar terms? See the [[Glossary]]. For videos and official docs, see [[Additional-Resources]].
