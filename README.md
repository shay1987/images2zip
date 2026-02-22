# images2zip

![CI](https://github.com/shay1987/images2zip/actions/workflows/build.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

images2zip is a small CLI utility that reads a list of Docker images, pulls them (with optional retries), saves them as tar files, packs them into a zip archive, and optionally logs every step to a timestamped log file.

It is designed for air‑gapped or constrained environments where you need to pre‑bundle images and move them as a single archive.

---

## Table of Contents
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Input file format](#input-file-format)
- [Examples](#examples)
- [Logging](#logging)
- [Exit status](#exit-status)
- [How to cut a release](#how-to-cut-a-release)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- Read Docker image names from a text file.
- Pull each image with configurable retry logic.
- Safe filename derivation for private-registry images (e.g. `registry:5000/team/app:v1` → `app_v1.tar`).
- Save each image as a `.tar` file.
- Zip all `.tar` files into a single `<name>.zip`.
- Save output directory and zip under a configurable base directory (default: `~/Downloads`).
- Optional timestamped logging to a user-specified file (disabled by default).
- Quiet mode (`-q`) for error-only output; verbose mode (`-v`) for detailed progress.
- Dependency checking (Docker, zip) before execution.
- Final summary with:
  - Total images in the input file.
  - Total images successfully zipped.
  - Retry count used.
- Optional cleanup of the output directory after zipping.

---

## Requirements

- Bash
- Docker CLI (`docker pull`, `docker tag`, `docker save` must work)
- `zip` utility
- A text file with one image reference per line (default: `images.txt`)

---

## Installation

### From package (recommended)

Download the latest `.deb` or `.rpm` from the [Releases page](https://github.com/shay1987/images2zip/releases).

**Debian / Ubuntu:**
```bash
sudo dpkg -i images2zip_*.deb
```

**Fedora / RHEL / Rocky / AlmaLinux:**
```bash
sudo rpm -i images2zip-*.rpm
```

### From source

Requires `make` and standard POSIX tools.

```bash
git clone https://github.com/shay1987/images2zip.git
cd images2zip
sudo make install          # installs to /usr/local/bin by default
```

To install to a custom prefix:
```bash
sudo make install PREFIX=/usr
```

To uninstall:
```bash
sudo make uninstall
```

---

## Usage

```
images2zip [OPTIONS]
```

### Options

- `-f, --file <file>`
  Input file containing Docker image references, one per line.
  Default: `images.txt`.

- `-n, --name <name>`
  Set the output *name* (directory and zip base name).
  The script creates a directory `<save>/<name>/` and a zip `<save>/<name>.zip`.
  Default: auto-generated as `images-DD-MM-YYYY` (today's date).

- `-s, --save <dir>`
  Set the base directory where the output directory and zip file are created.
  Default: `~/Downloads`.

- `-r, --retries <num>`
  Number of attempts for `docker pull` for each image (must be ≥ 1).
  `1` means a single attempt (no extra retries).
  On failure, each retry waits 2 seconds before the next attempt.

- `-d, --delete`
  Delete the output directory after a successful zip, keeping only the zip file.

- `-q, --quiet`
  Suppress all output except errors. Useful for scripts and cron jobs.

- `-v, --verbose`
  Enable verbose output with detailed progress messages.

- `-l, --log <file>`
  Enable logging to the specified file. Logging is disabled by default.

- `-h, --help`
  Show a short help message and exit.

---

## Input file format

The input file is a plain text file containing Docker image references, one per line, for example:

```
shay1987/arcade:latest
nginx:latest
alpine:3.19
```

- Empty lines and whitespace‑only lines are ignored.
- If your images live in a private registry, you can reference them with the registry prefix, for example:

```
myregistry.local:5000/team/app-backend:1.2.3
myregistry.local:5000/team/app-frontend:2.0.0
```

The script will strip a configured prefix in its logic (e.g., your private registry host) when retagging to simplify later use in other environments.

---

## Examples

Use defaults (read `images.txt`, write into `~/Downloads/images-DD-MM-YYYY/`, create `~/Downloads/images-DD-MM-YYYY.zip`):

```
images2zip
```

Use a custom input file and output name (still under `~/Downloads`):

```
images2zip -f my_images.txt -n my-bundle
```

Save under a different base directory and enable retries:

```
images2zip -f images.txt -n lab-pack -s /mnt/shared -r 3
```

Use retries and delete the tar directory after zipping:

```
images2zip -f images.txt -n images-pack -r 3 -d
```

Enable verbose output:

```
images2zip -f images.txt -n my-bundle -v
```

Run quietly (errors only):

```
images2zip -f images.txt -n my-bundle -q
```

Log to a file:

```
images2zip -f images.txt -n my-bundle -l build.log
```

Show help:

```
images2zip -h
```

---

## Logging

Logging is disabled by default. To enable it, use the `-l` flag with a file path:

```
images2zip -f images.txt -n my-bundle -l build.log
```

Each log line is prefixed with a timestamp, for example:

```
2026-01-19 20:30:00 File 'images.txt' found. Proceeding...
2026-01-19 20:30:05 Attempt 1/3 for pulling image: nginx:latest
2026-01-19 20:31:10 Successfully created zip file: /home/user/Downloads/images.zip
2026-01-19 20:31:10 Summary: images in file = 10, images zipped = 9, retries = 3
```

Logged events include:

- Configuration (input file, save directory, output name, retry count).
- Per-image processing (pull attempts, tagging, saving to tar).
- Zipping (which tar files are added, success/failure).
- Optional deletion of the output directory.
- Final summary line.

---

## Exit status

| Code | Meaning |
|------|---------|
| `0` | success |
| `1` | generic / unexpected error |
| `2` | invalid usage / bad arguments |
| `3` | no images processed |
| `4` | dependency or environment error |
| `5` | I/O or filesystem error |

---

## How to cut a release

Releases are fully automated once a version tag is pushed. Use the helper script:

```bash
bash scripts/release.sh 1.0.4
```

The script will:
1. Verify the working tree is clean and you are on `main`.
2. Create the tag `v1.0.4` and push it to origin.

GitHub Actions then automatically:
- Runs the test suite.
- Builds `.deb` (Debian/Ubuntu) and `.rpm` (Fedora/RHEL) packages versioned from the tag.
- Publishes a GitHub Release with both packages attached.

---

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/shay1987/images2zip).

Before submitting a pull request, run the test suite:
```bash
make test
```

---

## License

[MIT](LICENSE)

---

## Notes

- The script assumes Docker is already installed and configured on the host.
- Install via `make install`; the binary is called `images2zip`.
- The generated zip can be moved to another machine and loaded with `docker load` on that side.
