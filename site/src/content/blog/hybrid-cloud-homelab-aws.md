---
title: "Designing a Hybrid Cloud Backup for a Homelab That Travels"
description: "My homelab moves with me from hotel to hotel, which means most of my data sits on one drive in one room. Here's my plan to pair it with AWS: encrypted offsite backups in S3 Glacier Deep Archive, least-privilege IAM, a cloud-side watchdog and Terraform for all of it."
date: 2026-09-24T12:00:00Z
tags: ["aws", "hybrid-cloud", "terraform", "s3", "backup", "homelab", "restic"]
---

In my [last post](/blog/pi-stack-portable-homelab) I wrote about pi-stack, the Raspberry Pi homelab I carry from hotel to hotel. It runs my password manager, documents, notes and file shares off an encrypted 20 TB drive. It's small, cheap and fully under my control.

It also has an obvious weak spot. Most of my data exists exactly once, on one drive, in whatever hotel room I'm in that week. That includes my entire photo library. If the gear were stolen, the encryption means a thief couldn't read my data, but they'd still have it and I wouldn't. A drive failure, a spilled drink or a drop on moving day would do the same.

This post is the design for fixing that: a hybrid setup where the Pi stays my primary system and AWS holds an encrypted offsite copy, watches for trouble and costs a few dollars a month. I haven't built it yet. I'm writing the plan down first because that's how I'd want to see it done at work, and because writing it out is how I find the holes.

## What "hybrid" means here

In a company, hybrid cloud usually means on-premises systems working alongside a public cloud. My "on-premises" happens to be a hotel room, but the idea is the same. Each side does what it's good at:

| | The Pi (primary) | AWS (secondary) |
|---|---|---|
| Role | Runs every service, holds the live data | Holds an offsite copy, watches the Pi from outside |
| Strength | Fast, private, no monthly bill, within arm's reach | Durable, off-site, doesn't care where I am |
| Weakness | One drive, one location, one point of failure | Costs money per GB, slow to restore from cold storage |

The Pi stays the source of truth, and nothing runs in AWS day to day. AWS only matters on the day something goes wrong.

## Requirements

I set these before looking at any services:

1. **A real 3-2-1 backup.** Three copies of the data, on two kinds of media, with one of them somewhere else. Today the 2.2 TB `files` share has one copy.
2. **Encrypted before it leaves the Pi.** AWS should only ever see ciphertext. I don't want to rely on server-side encryption alone.
3. **Nothing inbound.** The Pi has zero open ports today, and it's staying that way. All traffic goes outbound over HTTPS.
4. **Least privilege.** If the Pi's AWS credentials leak, the worst an attacker can do is add data. They can't read my account or permanently delete backups.
5. **It has to work with hotel internet.** Uploads have to be throttled, resumable and polite to a shared connection, and the big initial upload has to happen when I have a fast one.
6. **Low cost.** A single-digit dollar amount per month.
7. **Infrastructure as code.** Every AWS resource goes in Terraform, the same way [this site](/blog/building-cloud-portfolio) is built.
8. **Proven restores.** A backup I haven't restored from is only a hope.

## The design

```
 ┌──────────── In my hotel room ──────────────┐
 │                                            │
 │  Raspberry Pi (primary)                    │
 │   ├─ encrypted 20 TB drive ── copy 1       │
 │   ├─ nightly restic job                    │
 │   └─ USB backup drive ─────── copy 2       │
 └───────────────────┬────────────────────────┘
                     │ outbound HTTPS only, throttled
                     │ (data is already encrypted by restic)
 ┌───────────────────┴──────── AWS us-east-1 ─────────────────┐
 │                                                            │
 │  S3 bucket (versioned, private) ────────────── copy 3      │
 │   ├─ appdata repo   → S3 Standard       (small, fast)      │
 │   └─ files repo     → data in Glacier Deep Archive         │
 │                       metadata in S3 Standard              │
 │                                                            │
 │  IAM user: write-only-ish, one bucket, no version deletes  │
 │  Lambda watchdog (daily) → SNS email if backups go stale   │
 │  AWS Budgets alert                                         │
 │                                                            │
 │  All of it defined in Terraform                            │
 └────────────────────────────────────────────────────────────┘
```

### Two restic repositories, two storage classes

I already use [restic](https://restic.net/) for my laptop backups, which land on the Pi over SFTP, so I'm staying with it. It encrypts everything on the client, deduplicates, and can write to S3 directly.

The data splits into two very different kinds, so I'm planning two repositories:

- **appdata:** the nightly snapshot of my password vault, notes database, Paperless documents and configs. It's small, it changes every day, and it's the first thing I'd need back. It goes to **S3 Standard**, so a restore starts right away.
- **files:** the 2.2 TB share. It's big, it rarely changes, and I'd only need it after a disaster. It goes to **S3 Glacier Deep Archive**, which costs a fraction of a cent per GB per month.

Deep Archive is the part I had to research carefully. Restic doesn't support cold storage in general, but it has an **experimental** feature for it. With `-o s3.storage-class=DEEP_ARCHIVE`, restic sends data files to the cold class but keeps metadata (config, locks and tree blobs) in S3 Standard, so everyday commands like listing snapshots still work. Restoring needs the feature flag `RESTIC_FEATURES=s3-restore` and the `s3.enable-restore` option. According to the [restic FAQ](https://restic.readthedocs.io/en/stable/faq.html), only `backup`, `copy`, `prune` and `restore` are supported with cold storage, and the feature is in early alpha with possible breaking changes.

Relying on an alpha feature for my last line of defense is a real risk, so the plan works around it:

- The USB drive is copy 2, and that's what I'd restore from for anything short of losing the Pi and everything next to it.
- I pin the restic version and read the changelog before upgrading.
- I run restore drills (below), so I find out it's broken during a drill instead of during a disaster.

If the drills go badly, the fallback is S3 Standard-IA, which works with plain restic and costs more but has no restore delay.

### Least-privilege access from the Pi

The Pi gets its own IAM user whose policy covers exactly one bucket. Restic needs to create, read, list and delete objects, because it removes its own lock files. So the policy can't simply deny deletes.

Instead, versioning does the protecting. With versioning on, a delete only adds a "delete marker", and the previous version stays. The policy explicitly **denies** `s3:DeleteObjectVersion` and any change to the bucket's versioning or lifecycle settings. A stolen key could hide objects, but it couldn't destroy them. A lifecycle rule cleans up old versions after 180 days. That matches Deep Archive's 180-day minimum storage charge, so I'm not paying early-deletion fees on data I'd keep anyway.

The access key sits in a root-only file on the Pi, next to the other secrets. The restic repository password lives outside the Pi too, because a backup whose password only exists on the thing that died is useless. Later I'd like to replace the long-lived key with IAM Roles Anywhere, which hands out temporary credentials against a certificate, but a tightly scoped key is a reasonable place to start.

### A watchdog that lives somewhere else

My current monitoring runs on the Pi. That's fine for most problems, but if the Pi is stolen or dies, the monitoring goes with it. The cloud side can cover that gap.

Every restic backup writes a small file into the repository's `snapshots/` folder, and those files stay in S3 Standard. A small Lambda function runs once a day on an EventBridge schedule. It looks at the newest object under `snapshots/` in each repository. If the newest one is more than about 36 hours old, it publishes to an SNS topic that emails me.

That check doesn't need the Pi to be alive, and it's exactly the sort of quiet failure my last post was about. It catches backups that "succeeded" without running, a Pi that's been off for two days, and gear that went missing between hotels.

An AWS Budgets alert rounds it out, so a runaway upload or a surprise restore bill shows up in my inbox rather than on my statement.

## Terraform sketch

This lives in its own Terraform root with the same remote state setup as this site. The core pieces look like this:

```hcl
resource "aws_s3_bucket" "backup" {
  bucket = "pi-stack-backup-${var.aws_account_id}"
}

resource "aws_s3_bucket_versioning" "backup" {
  bucket = aws_s3_bucket.backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "backup" {
  bucket                  = aws_s3_bucket.backup.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Old versions stick around long enough to recover from a bad delete,
# and long enough to clear Deep Archive's 180-day minimum.
resource "aws_s3_bucket_lifecycle_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 180
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "pi_backup" {
  statement {
    sid       = "ListBucket"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.backup.arn]
  }

  statement {
    sid = "ReadWriteObjects"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",  # restic removes its own lock files
      "s3:RestoreObject", # thaw Deep Archive data for a restore
    ]
    resources = ["${aws_s3_bucket.backup.arn}/*"]
  }

  # Even with this key, old versions can't be destroyed
  # and the safety settings can't be switched off.
  statement {
    sid    = "DenyDestructive"
    effect = "Deny"
    actions = [
      "s3:DeleteObjectVersion",
      "s3:PutBucketVersioning",
      "s3:PutLifecycleConfiguration",
      "s3:DeleteBucket",
      "s3:PutBucketPolicy",
    ]
    resources = [
      aws_s3_bucket.backup.arn,
      "${aws_s3_bucket.backup.arn}/*",
    ]
  }
}
```

Next to those go the IAM user and policy attachment, the Lambda function with its EventBridge schedule, the SNS topic with an email subscription, and an `aws_budgets_budget` with an alert threshold. None of it has a console click behind it.

On the Pi, the nightly job for the big repository looks roughly like this:

```sh
export RESTIC_REPOSITORY="s3:s3.us-east-1.amazonaws.com/pi-stack-backup-<account-id>/files"
export RESTIC_PASSWORD_FILE=/root/.restic-files-pass

restic backup "$DATA_ROOT/files" \
  -o s3.storage-class=DEEP_ARCHIVE \
  --limit-upload 12500       # KiB/s, about 100 Mbps: leaves room for everyone else
```

It runs behind the same checks my laptop backups use: wait for the network, confirm the drive is unlocked, and fail loudly if either check fails.

## The hard part: hotel internet

The bottleneck isn't AWS. It's the connection in whatever hotel I'm in that week, and that varies enormously.

Hotel "premium" Wi-Fi averages around 20 Mbps down for me. At that speed, even if upload kept pace, 2.2 TB would take more than ten days of nonstop uploading. But when the room has an Ethernet jack, I plug my travel router into it, and I'm currently averaging about 400 Mbps down and 300 Mbps up, even with the router's VPN turned on. At 300 Mbps, the same 2.2 TB takes about 17 hours.

That changes the plan from "trickle it up over weeks" to "wait for a wired room":

- **Seed on a wired connection.** The initial upload of the files repository only runs when the router is plugged into Ethernet. On Wi-Fi-only stays, the job sends nightly changes and nothing more.
- **Seed in priority order.** appdata goes first, since it's small and done in minutes. Then my photos and documents, then the rest of the share.
- **Throttle anyway.** A limit of about 100 Mbps still finishes the seed in roughly six overnight runs, and leaves plenty of bandwidth for everyone else sharing the hotel's connection.
- **Resume, don't restart.** Restic deduplicates, so an interrupted upload picks up largely where it left off instead of starting from zero.

The other thing I'll measure before trusting this: restic's memory use grows with the size of the repository, and the Pi only has 2 GB. If the Pi can't handle a 2.2 TB repository comfortably, the job moves to my laptop, which can read the same share over the network.

## What it should cost

These are estimates at US East (N. Virginia) list prices when I checked. I'll confirm them against the first real bills.

| Item | Math | Monthly |
|---|---|---|
| files repo data in Deep Archive | ~2,250 GB × $0.00099 | about $2.25 |
| appdata repo + restic metadata in S3 Standard | a few GB × $0.023 | well under $1 |
| Lambda, EventBridge, SNS | one check a day | effectively free |
| Upload bandwidth | data into AWS | free |
| Initial upload requests | Deep Archive charges more per upload request than Standard | a few dollars, once |
| **Total (ongoing)** | | **about $3** |

For comparison, the estimate I'd written down for a hot offsite copy at another provider was about $13 a month. Deep Archive is cheaper because it's slow to get data back, and that's the tradeoff to understand:

- **Restores take hours.** Deep Archive retrievals finish within 12 hours at the standard tier, or within 48 hours at the cheaper bulk tier. That's fine for a disaster copy and useless for "I deleted a file five minutes ago". That's what the USB drive is for.
- **Getting data out costs money.** Besides a retrieval fee, data sent out of AWS to the internet is around $0.09 per GB. A full 2.2 TB restore would cost in the neighborhood of $200 in transfer alone. I'm fine with that: it only happens if the Pi and the USB copy are both gone, and paying $200 once beats losing everything.
- **Deleting early costs money.** Anything removed from Deep Archive before 180 days is still billed for the full 180.

## Proving it works

The build isn't done until a restore works. The plan:

1. **Monthly, appdata:** restore the latest snapshot to a scratch folder on my laptop. Open the vault database, run SQLite's `PRAGMA integrity_check`, and confirm my notes database opens.
2. **Quarterly, files:** restore a random folder from Deep Archive using the experimental restore path. Time how long the thaw takes and compare file hashes against the original.
3. **Once a year:** a tabletop "everything in the room is gone" drill. Starting from a fresh laptop and only what's stored outside the Pi, can I get my passwords, notes and documents back? That drill tests the paperwork as much as the tech: where is the restic password, where is the AWS login, where is the Ansible vault password?

## Risks I'm accepting

| Risk | Mitigation |
|---|---|
| Restic's cold storage support is alpha | USB copy for everyday restores, pinned version, quarterly restore drills, Standard-IA as a fallback |
| Long-lived IAM access key on the Pi | Scoped to one bucket, can't delete versions, rotated regularly; Roles Anywhere later |
| First upload is too big for hotel Wi-Fi | Seed only on a wired connection, critical data first, throttled, with dedup to resume |
| Surprise AWS bill | Budgets alert, lifecycle rules, no restore without deciding to |
| The Pi runs out of memory running restic | Measure first; move the job to my laptop if needed |

## Why I'm doing it this way

I could solve "one drive, one copy" by paying for a consumer backup service and never thinking about it again. But this is the same problem companies deal with, just smaller: where the primary copy lives, how you get a copy off-site safely, what credentials you trust a machine with, how you know it's working when nobody's looking, and how much a restore really costs.

Building it with Terraform, least-privilege IAM and a watchdog outside the primary system is how I'd want to see it done on a real team. Doing it for my own data means I care whether it works.

Once it's built, I'll write a follow-up with the real numbers: how long the seed took, what the first bills looked like and how the first Deep Archive restore went.
