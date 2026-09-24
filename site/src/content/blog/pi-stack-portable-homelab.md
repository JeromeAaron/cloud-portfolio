---
title: "Pi-Stack: A Homelab That Travels With Me"
description: "I live mostly out of hotels for work, so I built a small, encrypted, self-hosted homelab on a Raspberry Pi that comes with me from city to city. Why I built it, what it runs, how it shares the work with my laptop, how to build one, and what broke along the way."
date: 2026-09-24
tags: ["homelab", "raspberry-pi", "docker", "self-hosting", "security", "tailscale", "ansible", "ai"]
---

I travel full-time for work, and most nights I sleep in a hotel. A lot of people keep a homelab in a closet at home. Mine comes with me. It's a Raspberry Pi 4, a 20 TB USB drive and a GL.iNet travel router. On moving days it packs up alongside my laptop. When I get to the next hotel, it comes back out and gets set up on the desk, and it runs there until I move again.

I call it pi-stack. It runs:

- my DNS
- my password manager
- my scanned documents
- my notes sync
- file sync between my MacBook and my Fedora laptop
- monitoring for all of it

My laptop picks up the heavy work the Pi can't handle: photos, machine learning and local AI models.

This post covers:

- why I built it
- what it does
- why I picked each piece
- how the Pi and the laptop split the work
- how to build one yourself
- the problems that taught me the most

## Why I built it

When you live out of hotels, your network is whatever the front desk gives you. It's shared with hundreds of strangers, and it changes every week or two. I wanted something steady underneath all that. These were my goals going in:

- **Close.** A server sitting in a closet a thousand miles away is only useful until the power blinks and nobody's there to press the button. I wanted my lab within arm's reach, so I could fix it, unplug it or move it.
- **Portable.** Everything had to pack up quickly, run on a normal hotel outlet and survive being moved every week or so.
- **Secure.** Hotel Wi-Fi is an untrusted network, so the lab had to assume the network around it was hostile. And if the gear were ever stolen, from the room or in transit, nothing on the drive could be readable.
- **Low cost.** I used a Pi I already owned. It draws a few watts and makes no noise, which matters when it sits in the room where I sleep. The software is all open source, and remote access uses Tailscale's free tier. No new monthly bills.
- **My data, on my hardware.** My passwords, documents, notes and photos live on hardware I control, not on someone else's service with its own terms and its own breach history.
- **Something to learn on.** I'm working toward a cloud engineering role, and hotel evenings are long. Running real services with real consequences has taught me more about Linux, networking, security and, lately, AI than any course has.

## What it does

| Use | Service | Runs on |
|---|---|---|
| DNS for every device I own, with ad, tracker and malware blocking | Pi-hole | Pi |
| Password manager that works with the official Bitwarden apps | Vaultwarden | Pi |
| Scan a receipt or letter on my phone, then search it later by any word in it | Paperless-ngx | Pi |
| Obsidian notes synced across my computers and my Android phone | CouchDB + Obsidian LiveSync | Pi |
| Downloads and Documents kept in sync between my MacBook, my Fedora laptop and the Pi | Syncthing | Pi + both laptops |
| File shares, plus nightly backups of both laptops | OpenMediaVault (Samba, Time Machine, SFTP) | Pi |
| Status page, update alerts and a private runbook site | Uptime Kuma, Diun, MkDocs | Pi |
| Photo library: import and organize, then browse, search and recognize faces | digiKam, Immich | Laptop, photos stored on the Pi |
| Local AI models for learning and experiments | Ollama, Open WebUI | Laptop |

Every service on the Pi gets its own HTTPS address, like `vault.nas.lan`. Anything sensitive lives on the encrypted drive. I can reach all of it from anywhere through Tailscale, and not a single port is open to the internet.

## The hardware, and why the router matters most

| | |
|---|---|
| Server | Raspberry Pi 4 Model B, 2 GB RAM, 128 GB high-endurance SD card |
| Storage | 20 TB USB 3 hard drive, LUKS-encrypted |
| Network | GL.iNet GL-AXT1800 travel router |
| OS | OpenMediaVault 8 on Debian 13 (64-bit) |
| Containers | Docker Compose, 10 services defined, 9 running all the time |
| Memory in use | about 960 MB of 1.8 GB |
| Ports open to the internet | none |

The travel router is what makes the whole thing work on the road. It connects to the hotel's network as its upstream and runs my own private network behind it. Every device I own joins that private network and never talks to the hotel network directly:

- my MacBook
- my Fedora laptop
- my Android phone
- the Pi
- my onn 4K Pro Android TV box

That solves a few problems at once:

- **One captive portal login instead of ten.** Hotel Wi-Fi makes every device click through a login page. With the router, I sign in once, for the router, and everything behind it is online. That matters most for the onn box, because signing into a hotel portal with a TV remote is miserable.
- **The same network in every city.** The Pi keeps the same reserved address everywhere, DNS always points at the Pi, and none of my devices need reconfiguring when I change hotels.
- **A lot more speed.** Hotel "premium" Wi-Fi averages around 20 Mbps down in my experience. When the room has an Ethernet jack, I plug the router straight into it, and I'm currently averaging about 400 Mbps down and 300 Mbps up, even with the router's VPN turned on.

Setting up in a new room means plugging in the router and the Pi, connecting the router to the hotel's network, and unlocking the drive. Nothing else changes.

## Why I chose each piece

**Raspberry Pi 4 (2 GB).** I already had it, it's small, and it sips power. I thought about something bigger. But I liked treating 2 GB as a design constraint, and a bigger box is one more thing to pack. Everything on the Pi has to earn its memory. Anything heavy goes to the laptop (more on that below).

**OpenMediaVault.** It's Debian underneath, with a web UI for the NAS jobs I didn't want to script myself: disks, encryption, SMB shares, SMART tests and scheduled tasks. Its plugins also handle Docker Compose. The catch is that OMV owns certain config files, like `sshd_config` and `smb.conf`, and rewrites them whenever you apply a change in the UI. I learned to treat those files as read-only.

**LUKS with the Adiantum cipher.** The Pi 4 has no hardware AES, so standard disk encryption is slow on it. Google designed Adiantum for exactly this kind of hardware. There's no key file on the Pi, and I type the passphrase after every boot. If someone walks off with the drive, it's useless to them.

**Tailscale.** A WireGuard-based mesh VPN that works behind hotel Wi-Fi and carrier NAT without any port forwarding. The Pi advertises its network as a subnet route. So when my phone is on cellular, it acts like it's on the same network as the Pi.

**Pi-hole.** Light and mature. I added two threat-intel blocklists (abuse.ch URLhaus and Phishing Army), which took it from about 100,000 to 250,000 blocked domains for almost no extra memory. It also serves the `*.nas.lan` names.

**Caddy.** One line (`local_certs`) gives every site a certificate from Caddy's own internal certificate authority, and the whole config is about 40 lines. nginx would have meant making certificates by hand. Traefik felt like overkill for eight fixed routes.

**Vaultwarden.** A lightweight server that speaks the Bitwarden protocol. The official Bitwarden self-hosted setup wants several containers and a database, which doesn't fit in 2 GB. Login needs a YubiKey or a TOTP code, and signups are turned off.

**Paperless-ngx.** The best open-source document manager I tried. I run it with one worker and SQLite instead of PostgreSQL, which saves a whole database server's worth of memory.

**CouchDB for Obsidian LiveSync.** LiveSync is an Obsidian plugin that syncs through a CouchDB database I host. Changes show up on my other devices within seconds, it works the same on my Android phone as on my computers, and notes are encrypted on each device before they're sent. I don't pay for Obsidian Sync.

**Syncthing.** Peer-to-peer file sync with no cloud account. It keeps Downloads and Documents identical across my MacBook, my Fedora laptop and the Pi. I turned off global discovery, public relays and NAT traversal, so it only ever talks to my own devices.

**Uptime Kuma and Diun.** Uptime Kuma checks every service and posts to Discord. Diun tells me when a newer image is out but never updates anything on its own. I didn't want my password manager silently upgrading itself overnight.

## Splitting the work between the Pi and my laptop

The Pi is good at being always on, quiet and low-power. It's bad at anything that needs real CPU, a GPU or a lot of memory. So I split the work. The Pi holds the data and runs the light, always-on services. My laptop does the heavy lifting when I need it.

The laptop is an ASUS ProArt PX13 running Fedora:

| | |
|---|---|
| CPU | AMD Ryzen AI 9 HX 370, 12 cores / 24 threads |
| Memory | 32 GB DDR5 |
| GPU | NVIDIA RTX 4050 Laptop, 6 GB VRAM |
| Integrated graphics | AMD Radeon 890M (it runs the desktop, which leaves the NVIDIA GPU free for compute) |

### Photos: digiKam and Immich

My photo library lives on the Pi's encrypted drive. The laptop does everything else:

- **digiKam** is where I import and organize. New photos land in an uploads folder on the NAS, and I sort them into the main library from there. The laptop mounts that folder read-write.
- **Immich** is how I browse and search. It runs in Docker on the laptop, as four containers: the server, PostgreSQL, Redis and machine learning. It reads the library as an external library over a **read-only** network mount, so it can never change or delete an original.
- **Face recognition and smart search** run on the RTX 4050 through CUDA, and video transcoding uses the GPU's NVENC encoder. None of that would be possible on a Pi.
- **Immich's and digiKam's databases** get backed up to the Pi every night with restic.

Running all this on the Pi was never an option. Immich alone wants more memory than the Pi has.

There is one tradeoff. Because Immich lives on the laptop, I can only reach it from my phone while the laptop is on. I'm fine with that. The photos themselves stay on the Pi either way.

### A small AI and machine learning lab

The laptop is also where I learn AI hands-on. Ollama runs natively as a user service, with Open WebUI in Docker as the chat interface. That gives me private, offline models I can take apart without paying per request.

The most useful thing I've learned so far is to judge a model by its **active** parameters, not its download size. With only 6 GB of VRAM, most of any large model sits in system RAM, so speed depends on how many parameters each token has to touch. On this laptop:

- A mixture-of-experts model with 35 billion parameters but only about 3.5 billion active per token (Qwen3.6 35B-A3B) runs at about 25 tokens a second, with most of the work (78 percent) on the CPU.
- A smaller MoE model with 8.5 billion parameters and about 1.7 billion active per token (LFM2.5 8B) runs at just over 90 tokens a second, with 88 percent of it on the GPU.
- Dense models of a similar size are far slower, because every parameter is used for every token.

Two settings made a big difference to the small model: turning on flash attention and quantizing the KV cache (the model's short-term memory for the conversation). With them off, the small model runs at about 70 tokens a second. With them on, it runs at just over 90, and it takes about a gigabyte less memory, which lets more of it fit on the GPU. On the 35B model they also save about a gigabyte, but the speed doesn't change, because most of that model runs on the CPU either way. I ran a needle-in-a-haystack recall test before trusting that the quantized cache hadn't hurt quality.

The next step is connecting this lab to the Pi. Paperless on the Pi could send new documents to a model on the laptop for titles, tags and cleaner OCR, using a tool like paperless-gpt. The Pi stays light, and my documents never leave my own network.

### Why the split works

- **The always-on part stays small.** The Pi uses about 960 MB of its 1.8 GB, with room to spare. If Immich or Ollama ran there, it would fall over.
- **The Pi doesn't need the laptop.** When the laptop is closed, DNS, passwords, documents, notes and file sync all keep running.
- **Heavy work runs on hardware built for it:** the GPU for face detection, transcoding and model inference, and 32 GB of RAM for the big models.
- **There's one copy of the truth.** Photos live on the NAS. The laptop reads them over the network instead of keeping its own copy.
- **Backups flow toward the Pi.** Restic runs on the laptop and pushes to the Pi over plain SFTP. I actually built a separate restic server on the Pi first. Then I noticed SFTP already worked and removed it, because an unused service with a login page is just extra attack surface.

## How it fits together

```
            Hotel network (untrusted)
                     │   one captive portal login
          ┌──────────┴──────────┐
          │  GL.iNet router     │   my private network, same in every city
          └──────────┬──────────┘
   MacBook, Android phone, onn TV box        Tailscale (phone on cellular, etc.)
                     │                           │  subnet route + split DNS
      ┌──────────────┼───────────────────────────┘
      │              │
┌─────┴──────────────┴─────────────────────┐   ┌──────────────────────────────┐
│ Raspberry Pi 4 · OpenMediaVault          │   │ Fedora laptop (ProArt PX13)  │
│                                          │   │                              │
│  Pi-hole ····· DNS, blocking, *.nas.lan  │   │  Immich + ML (GPU)           │
│  Caddy ······· HTTPS for every service   │   │  digiKam                     │
│  Vaultwarden · passwords                 │   │  Ollama + Open WebUI         │
│  Paperless ··· documents + OCR           │   │  restic backup client        │
│  CouchDB ····· Obsidian notes            │   │                              │
│  Syncthing ··· file sync                 │◄──┤  photos: read-only mount     │
│  Uptime Kuma, Diun, runbook site         │◄──┤  backups: restic over SFTP   │
│                                          │   └──────────────────────────────┘
│  SD card ······ OS, boot-time services   │
│  20 TB (LUKS) · documents, notes, photos,│
│                 file shares, backups     │
└──────────────────────────────────────────┘
```

None of the web apps on the Pi publishes a port of its own. They're only reachable through Caddy over Docker's internal network. Every published port is bound to the Pi's private address instead of `0.0.0.0`, so a new network interface can't accidentally expose anything.

## The design decisions that mattered most

### A locked drive shouldn't mean lost data

Travel means reboots. The Pi loses power every time I pack up, so the encrypted drive comes up locked a lot. Until I unlock it, its mount point is just an empty folder on the SD card.

By default, Docker creates a missing bind-mount folder and starts the container anyway. Paperless would have happily come up and saved new documents, unencrypted, onto the SD card. When I unlocked the drive later, those files would disappear under the mount. I'd have had two diverging copies of my data without knowing it.

One option fixes it:

```yaml
- type: bind
  source: ${DATA_ROOT}/appdata/paperless/media
  target: /usr/src/paperless/media
  bind: { create_host_path: false }   # refuse to start instead of writing to the SD card
```

With that set, anything that needs the drive simply won't start while it's locked. A scheduled task checks every five minutes and starts those containers once the drive is mounted:

```sh
mountpoint -q "$DATA_ROOT" && docker start caddy redis paperless couchdb syncthing
```

So my whole startup routine in a new hotel is: plug in, unlock the drive, wait a few minutes.

The split between the two kinds of storage is deliberate. Things I need immediately after boot, like DNS and my password manager, live on the SD card. Everything personal lives on the encrypted drive. Vaultwarden is on the SD card on purpose: the vault is encrypted on my devices before it's ever uploaded, and I need my passwords before I can unlock anything else.

### HTTPS without a public domain

The usual Let's Encrypt setup needs either a server reachable from the internet or a domain plus DNS API keys stored on the box. I didn't want either. Instead, Caddy runs its own certificate authority. I imported its root certificate on each device once, and now every `*.nas.lan` site gets a normal padlock. The CA's private key never leaves the encrypted drive.

### Updating on purpose

Almost every image is pinned to an exact version, in the form `repo:tag@sha256:digest`, so a redeploy gives me exactly the same bits. (The last two are on my to-do list.) When Diun pings me, I update one image at a time and check it's healthy before moving on.

I learned why that habit matters. Vaultwarden once fell about three months behind while the Bitwarden browser extension kept updating on its own. Eventually the two stopped understanding each other, and my vault showed up empty in Firefox until I updated the server. Pinning versions without a regular update habit just swaps one risk for another.

## How to build it

This is the condensed version. My full runbook has every command, with a check at the end of each phase. Here's the order I'd do it in again.

**What I used:**

- a Raspberry Pi 4 (2 GB) with a proper power supply and a fan
- a high-endurance microSD card
- a 20 TB USB 3 drive
- the GL.iNet router, which needs to support DHCP reservations and a custom DNS server
- a free Tailscale account
- a weekend

1. **OS.** I flashed Raspberry Pi OS Lite (64-bit) with SSH and my key already set up. Then I installed OpenMediaVault with its community install script and added the Compose, LUKS encryption and writecache plugins. Writecache keeps temporary writes in RAM to spare the SD card.
2. **A fixed address.** I reserved an address for the Pi on the router and listed both its Ethernet and Wi-Fi MAC addresses. That way it keeps the same address whichever connection it's using.
3. **Encryption.** I encrypted the data drive in the OMV UI with the Adiantum cipher. The passphrase and a backup of the LUKS header both live somewhere other than the NAS.
4. **Shares.** I set up three places on the drive:
   - a `files` share
   - a Time Machine share for the MacBook
   - a `backups` folder the Fedora laptop writes to over SFTP

   SMB is set to version 2 or higher.
5. **Hardening.** I moved the OMV admin page off ports 80 and 443 and onto HTTPS, and switched SSH to keys only. I also added fail2ban and automatic security updates. Swap goes to compressed RAM (zram) instead of the SD card.
6. **Secrets.** I generate each secret on the Pi itself with `openssl rand -base64 32` and write it directly into a `.env` file that only root can read. That keeps passwords out of my terminal scrollback and out of git.
7. **The Compose file.** Every service has a memory limit, every port is bound to the Pi's private address, and every mount on the encrypted drive has `create_host_path: false`.
8. **Images.** I pulled images one at a time, because pulling them all at once can run a 2 GB Pi out of memory. Once everything was healthy, I pinned each image to the digest I'd just tested.
9. **DNS and certificates.** I added the `*.nas.lan` records in Pi-hole, pointed the router's DHCP DNS at the Pi and imported Caddy's root certificate on each device.
10. **Service setup.** I opened Vaultwarden signups just long enough to create my account, then closed them. I locked Syncthing to my own devices and connected Obsidian LiveSync to CouchDB.
11. **Tailscale.** I installed it on the Pi and advertised the private subnet as a route. Then I set up split DNS in the Tailscale console, so only `nas.lan` lookups go to Pi-hole. The Pi runs Tailscale with `--accept-dns=false`, so Tailscale never replaces Pi-hole as the Pi's own resolver.
12. **Monitoring.** A health script runs every six hours. It checks SMART status, disk space, containers, backup freshness, swap and failed systemd units. It only posts to Discord when something's wrong, plus one "all good" message a day, so silence never means the script itself has died.
13. **The laptop side.** On the laptop I added:
    - read-only and read-write mounts for the photo folders
    - Immich and digiKam on top of those mounts
    - restic jobs that back up the laptop and the Immich and digiKam databases to the Pi every night
14. **Backing up the Pi itself.** Every night the Pi takes a snapshot of its app data, using SQLite's backup API so live databases copy cleanly. My laptop pulls that snapshot down.
15. **Ansible.** I wrote the whole services layer up as an Ansible playbook that's safe to run against the live box. It notices whether the drive is locked, pulls images one at a time and never touches OMV's own files.
16. **A reboot test.** I didn't call it done until it survived a cold boot with the drive locked, then came all the way back after I unlocked it.

It took me a while to spot one trap. If the only copy of my Ansible vault password were in Vaultwarden and the Pi died, I'd need Vaultwarden to rebuild Vaultwarden. So everything I'd need for a rebuild, including the drive passphrase, has a copy somewhere that doesn't depend on the NAS.

## What broke, and what it taught me

### I took down my own network with DNS

I wanted `*.nas.lan` to resolve even while the router's VPN was on, so I turned on a router option that forces its custom DNS over the VPN's. Around the same time, I'd set Pi-hole's rate limit to unlimited. The router funnels every device's DNS through its own single address, and that address kept tripping Pi-hole's per-client limit.

Together, those two changes produced a DNS storm of roughly 670,000 queries in an hour, and every device on my network lost internet. Turning the router option back off fixed it in seconds. Pi-hole now has a high but bounded limit of 10,000 queries a minute.

The lesson: don't remove the only brake in a system.

### A fix that failed quietly

At boot, Docker sometimes tries to bind Pi-hole to the Pi's address before the network has handed it out. I wrote a small systemd unit that waits for the address and then recreates Pi-hole. It waited for the address on `eth0`, specifically.

The Pi fell back to Wi-Fi, and my unit failed on every single boot without a word.

Now the unit waits for the address on any interface. More importantly, the health script now checks for failed systemd units. The thing that repairs problems needs monitoring too.

### Backups that "succeeded" without running

My laptop backups only ran if a ping to the NAS succeeded, using systemd's `ExecCondition`. After waking from sleep, that ping often ran before Wi-Fi had reconnected. When an `ExecCondition` fails, systemd marks the run as skipped, and skipped counts as success. My backups stopped for four days, and nothing complained.

While I was in there, I found my Immich backup had never run once. Its script lived in `/root`, and SELinux doesn't let systemd run programs from there.

I rebuilt the backup jobs. Now they:

- wait for the NAS
- confirm the drive is unlocked
- fail loudly if either check fails
- stop the laptop from sleeping mid-backup

A daily check also looks at when each backup last actually *succeeded*, not whether it ran.

### Trusting a certificate is harder than it sounds

Importing Caddy's certificate into Firefox didn't help Obsidian, because Firefox keeps its own certificate store. Obsidian on desktop reads the operating system's store, and only after a full restart. Obsidian on my Android phone won't accept a custom certificate authority at all. Firefox for Android doesn't reliably honor one either, even with its setting turned on, so on my phone I use Chrome for the internal sites.

For Obsidian on the phone, Caddy also serves CouchDB with a real Let's Encrypt certificate that Tailscale issues for the Pi's `ts.net` name, but only on the Tailscale interface. A weekly script renews that certificate and reloads Caddy only if it changed.

### "Can't be fixed" wasn't permanent

The Raspberry Pi kernel turns off memory accounting on low-RAM boards, and when I built this, the documented way to turn it back on was broken by a kernel bug. I wrote container memory limits off as impossible. A later kernel update fixed it without me touching anything, and I only noticed because I went back and checked.

Now the limits are enforced. A container that goes over its limit gets killed and restarted instead of slowing the whole Pi down. That changed how the box behaves, and I have some re-tuning to do. I now recheck my "known limitations" list after big updates.

## What's next

The biggest gap is offsite backup. My 2.2 TB `files` share, which includes my whole photo library, has exactly one copy, on one drive, in whatever hotel room I'm in that week. If that drive dies or the gear is stolen, the encryption protects my privacy but not my data.

Fixing that is the next project: a hybrid setup where the Pi stays the primary and AWS holds an encrypted offsite copy, all managed with Terraform. I've written up the plan in [Designing a Hybrid Cloud Backup for a Homelab That Travels](/blog/hybrid-cloud-homelab-aws).

After that, the list includes:

- connecting Paperless on the Pi to a local model on the laptop, as described above
- a default-deny firewall on the host, since the Pi sits on hotel networks
- Authelia for single sign-on with YubiKeys in front of the admin pages
- healthchecks on every container
- Renovate pull requests for image updates

Eventually I'd like a Pi 5 or a small N100 box with hardware AES and room to spare.

## What I got out of it

The biggest lesson was about failure. My worst problems weren't the loud ones. They were the quiet ones: a backup marked successful that never ran, and a boot fix that failed on every boot without a word. Most of the monitoring in this build exists because of one of those.

It also made me much more comfortable with the things cloud work is built on:

- systemd, cgroups and SELinux
- disk encryption and DNS
- running my own certificate authority
- VPN routing
- Ansible
- backing up databases that are in use

The laptop side added GPU containers, and a real feel for what local AI models can and can't do on modest hardware. It turns out a hotel room is a pretty good lab.
