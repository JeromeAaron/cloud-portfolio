---
title: "Building a Cloud Portfolio: Why IaC Matters"
description: "How I used Terraform to provision every piece of AWS infrastructure for this site — and why that approach matters when applying for cloud engineering roles."
date: 2026-03-13
tags: ["terraform", "aws", "iac", "portfolio"]
---

When most people build a personal website, they spin up a server, drag files over FTP, or click through a hosting wizard. I wanted this site to demonstrate that I think like a cloud engineer — so every AWS resource powering it was defined in code and deployed through a pipeline.

Everything you're reading right now — the S3 bucket storing these files, the CloudFront distribution delivering them to your browser, the Route 53 DNS records pointing at that distribution, the WAF rules in front of it — was defined in a Terraform `.tf` file and applied through a GitHub Actions workflow. Not a single resource was clicked into existence in the AWS console.

## Why This Matters

In cloud engineering, infrastructure as code (IaC) is foundational. Here's what it gives you:

- **Reproducibility** — I can tear this entire site down and rebuild it identically in minutes
- **Auditability** — every infrastructure change is a git commit with a message explaining why
- **Safety** — `terraform plan` shows exactly what will change before anything touches production
- **Collaboration** — another engineer can read my `.tf` files and understand the full architecture without clicking around the console

## The Stack

This site runs on a fully serverless, static architecture on AWS:

| Layer | Service | Purpose |
|---|---|---|
| Storage | S3 | Hosts the built HTML/CSS/JS files |
| CDN | CloudFront | Global edge caching, HTTPS termination |
| DNS | Route 53 | Points the domain to CloudFront |
| Security | WAF | Blocks malicious traffic at the edge |
| TLS | ACM | Free SSL certificate, auto-renewed |
| IaC | Terraform | Defines all of the above as code |
| CI/CD | GitHub Actions | Builds and deploys on every push |

## The Terraform State Problem

One of the first things you learn with Terraform is that it needs to store *state* — a record of what infrastructure it created — so it can compare what exists against what your code describes.

If you store that state file locally, you have two problems: it can't be shared with teammates, and if your machine dies, you lose track of your infrastructure. The solution is a *remote state backend* — an S3 bucket (with versioning enabled) and a DynamoDB table (for state locking, so two people can't run `terraform apply` simultaneously).

The irony is you need some infrastructure to manage your infrastructure. That's what the `terraform/bootstrap` directory in this project handles.

## What I Learned

This project was my first time writing Terraform. The learning curve is real but the concepts map well to what I already knew from the AWS SAA exam — I was just expressing those concepts in code instead of clicking through the console.

The biggest mindset shift: **treat infrastructure like software**. Version it. Review it. Test it before applying it.
