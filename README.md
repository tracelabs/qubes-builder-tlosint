# Trace Labs OSINT template for Qubes OS

A Debian 13 (trixie) template for [Qubes OS](https://www.qubes-os.org/) with the
Trace Labs OSINT toolset preinstalled. Create a qube from it and the tools are
ready to use, with Qubes keeping each investigation in its own isolated qube.

It is inspired by and closely follows
[tlosint-vm](https://github.com/tracelabs/tlosint-vm), the Trace Labs OSINT
virtual machine. The Trace Labs VM team built this Qubes version after many
users asked for one.

This repository is a fork of
[QubesOS/qubes-builder-debian](https://github.com/QubesOS/qubes-builder-debian)
that adds a `tlosint` template flavor. The template is built with
[qubes-builderv2](https://github.com/QubesOS/qubes-builderv2).

## Install

The template is published for Qubes R4.3 at <https://apt.tracelabs.org/qubes/r4.3>.
Before `qvm-template` can see it, dom0 needs the repository definition and the
Trace Labs signing key. Full instructions are in the
[Qubes OS install guide](https://github.com/tracelabs/tlosint-apt-repository/blob/main/qubes/README.md).
The short version is below.

> **dom0 has no network access, and that's on purpose.** You download files in
> an ordinary qube and copy them into dom0. Only copy files you've verified,
> because dom0 has full control of the system.

The examples use a qube named `work`. Substitute your own.

### 1. Add the repository and key

**Option 1: the `.repo` file.** In `work`, download the repository file and
the key, and check the key's fingerprint:

```bash
curl -fsSLO https://raw.githubusercontent.com/tracelabs/tlosint-apt-repository/main/qubes/tlosint.repo
curl -fsSLO https://apt.tracelabs.org/tlosint-archive-keyring.asc
gpg --show-keys tlosint-archive-keyring.asc
```

The fingerprint must be `34CE 4BC7 4FC3 BFFE 7AD7  7C2A E7A5 76CA 1ABD 03CD`.
Read `tlosint.repo` before you copy it. It's short.

In dom0, copy both files into place:

```bash
qvm-run --pass-io work 'cat tlosint.repo' | sudo tee /etc/qubes/repo-templates/tlosint.repo >/dev/null
qvm-run --pass-io work 'cat tlosint-archive-keyring.asc' | sudo tee /etc/qubes/repo-templates/keys/tlosint.asc >/dev/null
```

**Option 2: the `qubes-repo-tlosint` package.** This installs the same two
files, and also gives you a version number, removal with `dnf remove`, and an
upgrade path when the key rotates. Download `qubes-repo-tlosint-*.noarch.rpm`
and `SHA256SUMS` from the
[latest release](https://github.com/tracelabs/tlosint-apt-repository/releases/latest)
in `work`, check them with `sha256sum -c SHA256SUMS`, then in dom0:

```bash
qvm-run --pass-io work 'cat qubes-repo-tlosint-1.0-1.fc41.noarch.rpm' > /tmp/qubes-repo-tlosint.rpm
sudo dnf install /tmp/qubes-repo-tlosint.rpm
```

The install guide also explains how to check the RPM's signature before
copying it.

### 2. Install the template

In dom0:

```bash
qvm-template list --available debian-13-tlosint
qvm-template install debian-13-tlosint
```

`qvm-template` checks the repository metadata and the template's signature
against the key you installed. Then create an app qube based on
`debian-13-tlosint` and start working.

## Tools

| Tool | Description | Source |
|---|---|---|
| [auto-archiver](https://github.com/bellingcat/auto-archiver) | Automated archiving of web resources | Container image, pulled on first run |
| [carbon14](https://github.com/Lazza/Carbon14) | OSINT dating of web content | Trace Labs repo |
| ffmpeg | Media transcoding, required by yt-dlp merging | Debian |
| gallery-dl | Image gallery downloader | Debian backports |
| [ghunt](https://github.com/mxrch/GHunt) | Google account OSINT | Trace Labs repo |
| [gowitness](https://github.com/sensepost/gowitness) | Web screenshot utility | Upstream release, checksum-pinned |
| httrack | Website mirroring utility | Debian |
| instaloader | Download Instagram media and metadata | Debian |
| internetarchive (`ia`) | Internet Archive command line client | Debian |
| [maigret](https://github.com/soxoj/maigret) | Collect a dossier on a person by username | Trace Labs repo |
| mat2 | Metadata anonymisation toolkit | Debian |
| [metagoofil](https://github.com/opsdisk/metagoofil) | Extract metadata from public documents | Trace Labs repo |
| [monolith](https://github.com/Y2Z/monolith) | Save a web page as a single self-contained HTML file | Upstream release, checksum-pinned |
| shred | Securely overwrite files | Debian (coreutils) |
| [spiderfoot](https://github.com/smicallef/spiderfoot) | Automated OSINT reconnaissance | Trace Labs repo |
| streamlink | Extract streams from live services | Debian backports |
| tesseract | OCR engine and English language data | Debian |
| [twscrape](https://github.com/vladkens/twscrape) | Twitter/X scraping | pipx, version-pinned |
| [whatsmyname](https://github.com/C3n7ral051nt4g3ncy/WhatsMyName-Python) | Username enumeration across sites | Trace Labs repo |
| yt-dlp | Video downloader for archiving sources | Debian backports |

The template also includes the standard Debian XFCE desktop that the upstream
`debian-13-xfce` template ships, plus Docker for auto-archiver.

Non-apt tools are installed under `/opt/tlosint` and linked into `/usr/bin`.
In app qubes, `/usr/local` and `/home` are private to each qube, so installing
anything there in the template would hide it from the qubes based on it.

## Updates

Tool updates are managed by
[tlosint-apt-repository](https://github.com/tracelabs/tlosint-apt-repository),
which publishes signed packages at <https://apt.tracelabs.org>. Because the
tools are ordinary apt packages, the standard Qubes OS updater keeps them
current in your template, alongside Debian's own updates. Tools are updated on
the Trace Labs quarterly release cadence.

The tools whose source above is not Debian or the Trace Labs repo (auto-archiver,
gowitness, monolith and twscrape) aren't apt packages yet, so the updater
doesn't touch them. They are updated with each quarterly template release.
To move to a newer template build, run this in dom0:

```bash
qvm-template upgrade debian-13-tlosint
```

## Building

You need a Fedora-based qube set up for
[qubes-builderv2](https://github.com/QubesOS/qubes-builderv2) with the Docker
executor. Copy [`example-builder-tlosint.yml`](example-builder-tlosint.yml)
into your qubes-builderv2 checkout as `builder.yml`, then run:

```bash
./qb -c builder-debian package fetch
./qb -t debian-13-tlosint template all
```

The result is a `qubes-template-debian-13-tlosint-*.noarch.rpm`. To test an
unsigned local build, copy it to dom0 and install it with
`qvm-template install --nogpgcheck <file>`.

### What the flavor adds

| Path | Purpose |
|---|---|
| [`template_debian/packages_trixie_tlosint.list`](template_debian/packages_trixie_tlosint.list) | Package list: Debian's trixie list plus the tools |
| [`template_debian/tlosint/02_install_groups_trixie.sh`](template_debian/tlosint/02_install_groups_trixie.sh) | Adds apt.tracelabs.org and trixie-backports |
| [`template_debian/tlosint/02_install_groups_packages_installed.sh`](template_debian/tlosint/02_install_groups_packages_installed.sh) | Installs the non-apt tools (pinned versions at the top) and fails the build if any tool is missing |
| [`template_debian/tlosint/04_install_qubes_post.sh`](template_debian/tlosint/04_install_qubes_post.sh) | Adds the default qube user to the `docker` group |
| [`template_debian/appmenus_trixie_tlosint/`](template_debian/appmenus_trixie_tlosint) | Default app menu entries |
| [`keys/tlosint-archive-keyring.gpg`](keys/tlosint-archive-keyring.gpg) | Trace Labs signing key |

Everything else is upstream qubes-builder-debian. Keep the flavor in new files
so upstream changes merge cleanly.
