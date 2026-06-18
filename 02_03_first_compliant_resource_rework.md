# Lab 2.3: Building Your First Compliant Resource (AWS S3)

Welcome to the first hands-on lab. This is the one that turns the ideas from the lectures into something running in a real cloud account, so we're going to move slowly and explain the *why* behind each step, not just the commands.

A quick word on who's in the room. Some of you come from GRC and have written plenty of controls but never touched Terraform. Some of you come from cloud or DevOps and have deployed plenty of infrastructure but never had to prove a control to an auditor. This lab is built for both of you. The GRC folks will recognize the control language and learn how it gets enforced in code. The technical folks will recognize the tooling and learn why the tagging, logging, and evidence steps aren't busywork. By the end, everyone will have built the same thing: one S3 bucket that satisfies five real NIST 800-53 controls, plus machine-readable proof that it does.

No screenshots. That's the theme of the whole course, and it starts here.

## What you'll build, in plain language

You'll use Terraform to create an Amazon S3 bucket (cloud storage) that is locked down to a security baseline, and a second bucket that records who accessed the first one. Then you'll capture a file that proves the baseline is in place. That proof file is the thing an auditor would accept instead of a screenshot, because it comes straight from the system and can't be faked by cropping a browser window.

The five controls you'll satisfy, translated out of NIST-speak:

| Control | What it means in plain terms | Where it lives in your code |
|---|---|---|
| **SC-28** | Data is encrypted while it sits in storage, so a stolen disk is useless. | `aws_s3_bucket_server_side_encryption_configuration` |
| **AC-3** | Nobody on the public internet can reach the bucket. | `aws_s3_bucket_public_access_block` (four flags, all `true`) |
| **AU-3** | There's a record of who accessed the data. | `aws_s3_bucket_logging` writing to the log bucket |
| **AU-6** | Those records are kept somewhere you can actually review. | the separate log bucket |
| **CM-6** | The resource is set to an approved configuration, and that's labeled and enforced. | required tags + versioning |

You don't need to memorize the control IDs. You need to be able to point at a line of code and say which control it enforces, because that's the muscle every later lab builds on.

## Learning objectives

- Express NIST 800-53 controls as Terraform resources, and cite each control where it's enforced.
- Capture pre- and post-deploy compliance evidence as JSON instead of screenshots.
- Stand up the repository structure that every later lab (and your capstone) will reuse.
- Build a primitive that the rest of the course verifies automatically.

## Time and cost

- Time: 60 to 90 minutes the first time, because we're setting up your tools and your repo too. Closer to 20 minutes on a second pass.
- Cost: under one cent if you destroy the same day. Empty S3 buckets cost nothing to sit there. You pay fractions of a cent for the handful of API calls Terraform makes.

---

# Part 1: Set up your tools

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

Throughout this guide you'll see `--profile <your-sandbox>`. Replace `<your-sandbox>` with the name you gave your profile. **If your profile is the default one (literally named `default`), you can drop `--profile <your-sandbox>` entirely**, since the CLI uses `default` automatically.

Confirm the CLI can reach your account:

```bash
aws sts get-caller-identity --profile <your-sandbox>
```

A JSON blob with your account ID means you're connected.

---

# Part 2: Set up your repository

This is the part that tripped up the last cohort, so we're going to be explicit. Every lab in this course drops files into the same repository, in the same shape. Get the shape right once, here, and the rest of the course just slots into it. Get it wrong, and you'll spend later labs hunting for files that aren't where the guide expects.

## The mental model

You're building **one repository** called `cgep-labs`. It lives in two places at once:

- **On your machine**, as a folder you work in.
- **On GitHub**, as the published copy your instructor reviews.

These aren't two different things. When you `git push`, your local folder becomes the GitHub copy, file for file. So when a guide talks about "the version that gets evaluated," it means your `cgep-labs` repo on GitHub, which is just your local folder after you've pushed it. There's no separate "submission" copy to assemble.

(Your final capstone is a separate repository later on, a fork of the starter app. It uses this exact same structural discipline, so the habits you build here carry straight over.)

## Create the structure

Pick a home for your work (your Documents folder is fine) and build the skeleton. From your terminal:

```bash
mkdir -p cgep-labs/terraform/primitives
mkdir -p cgep-labs/terraform/modules
mkdir -p cgep-labs/scripts
mkdir -p cgep-labs/evidence
cd cgep-labs
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
│   └── modules/                  ← reusable modules (Lab 2.4 fills this in)
│
├── scripts/                      ← shared scripts (Lab 2.5 adds one here)
│
└── evidence/                     ← captured proof, one folder per lab
    └── lab-2-3/                  ← THIS lab's evidence lands here
        ├── plan.json
        └── state.json
```

Two ideas are doing all the work in this layout, and they're worth saying out loud:

- **Code and evidence are separate.** Your Terraform lives under `terraform/`. The proof you capture lives under `evidence/`, named by lab. A reviewer can find every artifact for Lab 2.3 in `evidence/lab-2-3/` without digging through your code. This separation is also why a later lab can capture evidence *from* an earlier lab's workspace; the workspace is always `terraform/.../<thing>`, and the evidence always lands in `evidence/lab-X-Y/`.
- **`primitives/` vs `modules/`.** A primitive is something you deploy as-is. A module is a reusable template that other code calls. This lab builds a primitive. Lab 2.4 builds your first module. Keeping them in separate folders keeps that distinction visible.

## Add a `.gitignore` before you commit anything

This step matters more than it looks. When Terraform runs, it creates files you must **not** publish to GitHub:

- `terraform.tfstate` and its backups: Terraform's record of what it built. It can contain sensitive values, and it's specific to your machine.
- The `.terraform/` directory: hundreds of megabytes of downloaded provider plugins. No one needs your copy.
- `*.tfvars`: where people often put secrets.

A `.gitignore` file tells Git to skip these. Create it at the repo root:

```bash
cat > .gitignore << 'EOF'
# Terraform working files (never publish these)
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
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

# Part 3: Build the compliant bucket

Now the actual lab. Make sure you're in the repo root (`cgep-labs`) and your AWS CLI profile is working.

## How the pieces fit

You're building two buckets. The **primary bucket** is where data would go. The **log bucket** quietly records every access to the primary one. Both buckets enforce the same baseline: encryption, versioning, a full public-access block, and the required compliance tags.

```
                ┌──────────────────────────────┐
   default_tags │  Project / Environment /     │
   (provider)   │  ManagedBy / ComplianceScope │
                └───────────────┬──────────────┘
                                │  applied automatically to everything
             ┌──────────────────┴───────────────────┐
             ▼                                       ▼
   ┌────────────────────┐                ┌──────────────────────┐
   │ primary bucket     │  access logs   │ log bucket           │
   │ AES256  (SC-28)    │ ──────────────▶│ receives logs (AU-3) │
   │ versioning ON      │                │ AES256               │
   │ public-block (AC-3)│                │ public-block (AC-3)  │
   └────────────────────┘                └──────────────────────┘
```

The `default_tags` block at the top is a small trick that pays off all course long: it stamps the four required compliance tags onto every taggable resource automatically, so you can't forget them on one resource and quietly fail CM-6.

### Why we bother capturing evidence at all

In production, you don't get to walk an auditor through your AWS console. They want proof that's hard to fake and easy to re-check: a file that came out of the system, that anyone can run the same command to reproduce. `terraform show -json` gives you exactly that. The bucket you build today is small. The habit of capturing its configuration as JSON is the whole point, and it's the thread that runs through every remaining lab.

## Step 1: Create the lab folder

From the repo root:

```bash
mkdir -p terraform/primitives/compliant-s3 && cd terraform/primitives/compliant-s3
touch main.tf variables.tf outputs.tf README.md
```

You're now sitting inside `terraform/primitives/compliant-s3/`, which is where this lab's `.tf` files live. The three `.tf` files split the work the way every Terraform project does: `main.tf` for the resources, `variables.tf` for the inputs, `outputs.tf` for the values you want back out.

## Step 2: Write the base bucket and tags

Open `main.tf`. Start with the provider configuration. The `default_tags` block is what makes the four required compliance tags non-optional.

```hcl
# main.tf
terraform {
  required_version = ">= 1.6"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

provider "aws" {
  region = "us-east-1"

  # CM-6: Configuration settings, required compliance tags applied to every
  # taggable resource by default. Removes the chance of forgetting them.
  default_tags {
    tags = {
      Project         = var.project_name
      Environment     = var.environment
      ManagedBy       = "terraform"
      ComplianceScope = "cge-p-lab"
    }
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

locals {
  effective_suffix = var.bucket_suffix != "" ? var.bucket_suffix : random_id.bucket_suffix.hex
  primary_name     = "${var.project_name}-${var.environment}-data-${local.effective_suffix}"
  log_name         = "${var.project_name}-${var.environment}-logs-${local.effective_suffix}"
}

resource "aws_s3_bucket" "primary" {
  bucket = local.primary_name
}
```

The `random_id` deserves a note, because it prevents a very common first-day error. **S3 bucket names are globally unique across all of AWS**, not just your account. If you and three classmates all try to create `cgep-lab-dev-data`, only the first one wins and the rest get an error. The random suffix sidesteps that by tacking a few unique characters onto every name.

Now `variables.tf`. These `validation` blocks are doing compliance work: they turn a typo into a clear failure at plan time, before anything is built, instead of a confusing error halfway through deployment.

```hcl
# variables.tf
variable "project_name" {
  type        = string
  description = "Short project identifier. Becomes part of bucket names and the Project tag."
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.project_name))
    error_message = "project_name must be 3-21 lowercase alphanumerics or hyphens, starting with a letter."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment. Drives the Environment tag and downstream policy decisions."
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "bucket_suffix" {
  type        = string
  description = "Optional suffix to force a specific bucket name. Defaults to a random_id."
  default     = ""
}
```

## Step 3: Add encryption, versioning, and the public access block

Three resources, three controls. Append these to `main.tf`.

```hcl
# main.tf (continued)

# SC-28: Protection of information at rest.
# AES-256 keeps this lab simple. The commented block below shows how you'd
# switch to KMS-managed keys, covered in a later lab.
resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }

  # KMS teaser:
  # rule {
  #   apply_server_side_encryption_by_default {
  #     sse_algorithm     = "aws:kms"
  #     kms_master_key_id = aws_kms_key.bucket.arn
  #   }
  #   bucket_key_enabled = true
  # }
}

# CM-6: Versioning preserves prior object states for recovery and audit.
resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id
  versioning_configuration {
    status = "Enabled"
  }
}

# AC-3: Access control, explicit deny on every public access vector.
resource "aws_s3_bucket_public_access_block" "primary" {
  bucket                  = aws_s3_bucket.primary.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

All four flags in that last block must be `true`. AWS treats them as four independent doors into the bucket, and leaving any one open defeats the purpose. Three out of four is not "mostly compliant"; it's a public bucket waiting to happen. This is the kind of thing AC-3 exists to catch.

## Step 4: Add the log bucket and turn on access logging

The log bucket needs its own encryption and public-access block, plus a small ACL that lets AWS's log-delivery service write into it. The order matters here, which is why there's a `depends_on`. Append to `main.tf`:

```hcl
# main.tf (continued)

# AU-3 / AU-6: Content of audit records + audit review.
resource "aws_s3_bucket" "log" {
  bucket = local.log_name
}

resource "aws_s3_bucket_ownership_controls" "log" {
  bucket = aws_s3_bucket.log.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "log" {
  depends_on = [aws_s3_bucket_ownership_controls.log]
  bucket     = aws_s3_bucket.log.id
  acl        = "log-delivery-write"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log" {
  bucket = aws_s3_bucket.log.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "log" {
  bucket                  = aws_s3_bucket.log.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "primary" {
  bucket        = aws_s3_bucket.primary.id
  target_bucket = aws_s3_bucket.log.id
  target_prefix = "access-logs/"
}
```

That last resource, `aws_s3_bucket_logging`, is the line that actually wires AU-3. It tells the primary bucket to send its access logs to the log bucket. Without it you'd have two buckets and no audit trail between them.

Now `outputs.tf`. Outputs are values Terraform hands back after it runs. Most of these are identifiers, but `encryption_algorithm` is something more interesting: it's deliberate evidence. It's the SC-28 attestation, in a form a machine can read and a policy can later check.

```hcl
# outputs.tf
output "bucket_arn"     { value = aws_s3_bucket.primary.arn }
output "bucket_name"    { value = aws_s3_bucket.primary.id }
output "log_bucket_arn" { value = aws_s3_bucket.log.arn }

output "encryption_algorithm" {
  description = "Server-side encryption algorithm in effect (SC-28 attestation)."
  value = one([
    for rule in aws_s3_bucket_server_side_encryption_configuration.primary.rule :
    rule.apply_server_side_encryption_by_default[0].sse_algorithm
  ])
}
```

> **Why the `one(...)` expression looks odd.** Terraform represents that `rule` block as a *set*, not a list, and sets can't be accessed by index. The `for` expression flattens the single rule into a list, and `one()` pulls out the lone element, failing loudly if there's ever somehow more than one. It catches everyone off-guard the first time. Once you've seen it, you'll recognize the pattern whenever a nested block is modeled as a set.

## Step 5: Initialize, plan, and apply

These three Terraform commands are the core loop you'll run for the rest of the course, so here's what each one does:

- `terraform init` downloads the AWS and random providers into `.terraform/` (the folder your `.gitignore` skips). Run it once per workspace, or any time you change providers.
- `terraform validate` checks your `.tf` files for syntax and obvious mistakes.
- `terraform plan` works out exactly what it would create, without creating anything. The `-out=tfplan` saves that plan to a file.
- `terraform apply` builds it. Passing the saved `tfplan` means it builds precisely what you just reviewed, no surprises.

If your sandbox uses AWS SSO, export your credentials first so Terraform's AWS provider can use them (the provider doesn't always read SSO config the way the CLI does):

```bash
eval "$(aws configure export-credentials --profile <your-sandbox> --format env)"
```

Then run the loop:

```bash
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply -auto-approve tfplan
```

You should see something like this at the end of `apply`:

```
Apply complete! Resources: 11 added, 0 changed, 0 destroyed.

Outputs:

bucket_arn = "arn:aws:s3:::cgep-lab-dev-data-XXXXXXXX"
bucket_name = "cgep-lab-dev-data-XXXXXXXX"
encryption_algorithm = "AES256"
log_bucket_arn = "arn:aws:s3:::cgep-lab-dev-logs-XXXXXXXX"
```

Eleven resources, four outputs. Your suffix will be different from anyone else's, which is the random_id doing its job.

## Step 6: Capture your evidence

Here's where the last cohort got tangled up, so read this carefully. You're going to capture two JSON files, and they belong in the repo-root `evidence/lab-2-3/` folder, **not** inside this Terraform directory.

You're currently inside `terraform/primitives/compliant-s3/`. To write up to the repo root, the path climbs back three levels: `../` to `primitives/`, `../../` to `terraform/`, `../../../` to the repo root. So:

```bash
mkdir -p ../../../evidence/lab-2-3
terraform show -json tfplan > ../../../evidence/lab-2-3/plan.json
terraform show -json        > ../../../evidence/lab-2-3/state.json
```

If counting the `../` makes you nervous, here's the same thing done from the repo root instead, which some people find clearer:

```bash
# from cgep-labs (the repo root)
mkdir -p evidence/lab-2-3
terraform -chdir=terraform/primitives/compliant-s3 show -json tfplan > evidence/lab-2-3/plan.json
terraform -chdir=terraform/primitives/compliant-s3 show -json        > evidence/lab-2-3/state.json
```

Either way, open `evidence/lab-2-3/state.json` and find your bucket. Reading it, you can point at the evidence for every control you set out to enforce:

- **SC-28** at `server_side_encryption_configuration[].rule[].apply_server_side_encryption_by_default[].sse_algorithm = "AES256"`
- **AC-3** in `public_access_block`, where all four flags read `true`
- **CM-6** in the four tags
- **AU-3** at `logging[].target_bucket`

That file is machine-readable compliance evidence. It's the thing you hand over instead of a screenshot, and in Lab 3 a policy will read it automatically.

## Verify it from the outside

The evidence above comes from Terraform's own view of the world. It's worth confirming the same facts by asking AWS directly, the way an auditor's tool would. Substitute your bucket name:

```bash
BUCKET=$(terraform output -raw bucket_name)

aws s3api get-bucket-encryption    --profile <your-sandbox> --bucket "$BUCKET"
aws s3api get-bucket-versioning    --profile <your-sandbox> --bucket "$BUCKET"
aws s3api get-public-access-block  --profile <your-sandbox> --bucket "$BUCKET"
```

Expected output, trimmed:

```json
{ "ServerSideEncryptionConfiguration": { "Rules": [ {
    "ApplyServerSideEncryptionByDefault": { "SSEAlgorithm": "AES256" },
    "BucketKeyEnabled": false
} ] } }

{ "Status": "Enabled" }

{ "PublicAccessBlockConfiguration": {
    "BlockPublicAcls": true, "IgnorePublicAcls": true,
    "BlockPublicPolicy": true, "RestrictPublicBuckets": true
} }
```

If any of the three comes back missing or wrong, the bucket isn't compliant. Fix the Terraform, re-apply, re-verify. That loop, fix the code rather than fix the resource by hand, is the production-correct instinct: in real life the code is the source of truth, and clicking around the console to patch something just means it drifts back the next time Terraform runs.

---

## Commit your work

```bash
# from the repo root
git add terraform/primitives/compliant-s3 evidence/lab-2-3
git commit -m "Lab 2.3: compliant S3 primitive + evidence"
git push
```

## Cleanup: tear down the live resources

With your evidence captured and pushed, the buckets have done their job. Destroy them now so they don't linger in your account. This only removes the live AWS resources; your committed evidence files stay in the repo as proof they once existed exactly as configured.

Versioned buckets won't delete while they still hold object versions, so empty them first, then destroy:

```bash
LOG_BUCKET=$(terraform output -raw log_bucket_arn | sed 's/.*:::\(.*\)/\1/')

# Empty the primary bucket (probably nothing in it yet, but be safe)
aws s3 rm "s3://$(terraform output -raw bucket_name)" --recursive --profile <your-sandbox>

# The log bucket may hold access-log objects. Empty all versions:
aws s3api list-object-versions --profile <your-sandbox> --bucket "$LOG_BUCKET" \
  --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json \
  | aws s3api delete-objects --profile <your-sandbox> --bucket "$LOG_BUCKET" --delete file:///dev/stdin || true

terraform destroy -auto-approve
```

If you destroy within a few minutes of applying, the log bucket is probably still empty and the `delete-objects` call simply does nothing.

## Portfolio submission checklist

Your `cgep-labs` repo on GitHub should now contain:

- [ ] `terraform/primitives/compliant-s3/main.tf`
- [ ] `terraform/primitives/compliant-s3/variables.tf`
- [ ] `terraform/primitives/compliant-s3/outputs.tf`
- [ ] `terraform/primitives/compliant-s3/README.md`, one paragraph: "this module enforces SC-28, AU-3, AU-6, CM-6, AC-3 on a single S3 bucket."
- [ ] `evidence/lab-2-3/plan.json`
- [ ] `evidence/lab-2-3/state.json`
- [ ] No `.terraform/` directory or `*.tfstate` files committed (your `.gitignore` handles this; double-check with `git status`).
- [ ] Live AWS resources destroyed once your evidence was committed (`terraform destroy` ran clean). Your committed evidence stays in the repo regardless.

## Troubleshooting

- **`BucketAlreadyExists`.** S3 bucket names are globally unique. The `random_id` suffix should prevent this; if you set `bucket_suffix` by hand, pick something more unique.
- **`AccessDenied` writing to the log bucket.** The log bucket needs the `log-delivery-write` ACL, which requires `aws_s3_bucket_ownership_controls` set to `BucketOwnerPreferred` *first*. The `depends_on` in Step 4 sequences this for you, so don't remove it.
- **`failed to find SSO session section`.** Terraform's AWS provider doesn't always parse SSO config the way the CLI does. Run `eval "$(aws configure export-credentials --profile <your-sandbox> --format env)"` before your Terraform commands.
- **Terraform state lock errors.** Usually a leftover from an interrupted run. Run `terraform force-unlock <lock-id>` only if you're sure no one else is applying.
- **Region mismatch / `NoSuchBucket` on a verify command.** Your profile may default to a different region than the provider's `us-east-1`. Add `--region us-east-1` to the `aws s3api` command.
- **(Windows) a command fails with a path that looks half-converted.** Git Bash rewrote a `/`-leading argument. Re-run with `MSYS_NO_PATHCONV=1` in front of the command.
- **(Windows) shell scripts behaving strangely after editing.** Confirm you ran `git config --global core.autocrlf input`. Line-ending conversion is the usual culprit.

## How this feeds the rest of the course

This is your first compliant primitive. By the end of the course you'll have a dozen, and they'll all share the structure you just built.

- **Chapter 3:** you'll write Rego policies that read this exact `plan.json` and prove each control is in place. The `state.json` becomes a continuous-evaluation input.
- **Chapter 4:** the `terraform plan` plus `show -json` ritual you ran by hand becomes a step in a CI pipeline. The `evidence/lab-2-3/` artifacts are the seed of the signed evidence bundles your pipeline will produce.
- **Chapter 6:** you'll write an OSCAL Component Definition for this module. SC-28's implementation will point at `evidence/lab-2-3/state.json`. An assessor reads the OSCAL, follows the link, and sees the same JSON you just generated. The audit becomes a matter of following links rather than scheduling a screen-share.

That's the arc. A bucket today, a self-evidencing compliance pipeline by the end. You've built the first piece and, just as importantly, the shape that holds all the rest.
