# images2zip
  
images2zip is a small CLI utility that reads a list of Docker images, pulls them (with optional retries), saves them as tar files, packs them into a zip archive, and optionally logs every step to a timestamped log file.  
  
It is designed for air‑gapped or constrained environments where you need to pre‑bundle images and move them as a single archive.  
  
---
  
## Features
  
- Read Docker image names from a text file.  
- Pull each image with configurable retry logic.  
- Retag images from a private registry by stripping the registry prefix.  
- Save each image as a `.tar` file.  
- Zip all `.tar` files into a single `<name>.zip`.  
- Save output directory and zip under a configurable base directory (default: `~/Downloads`).  
- Optional timestamped logging to a user-specified file (disabled by default).
- Verbose mode for detailed progress output.
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
  Default: `images`.  
  
- `-s, --save <dir>`  
  Set the base directory where the output directory and zip file are created.  
  Default: `~/Downloads`.  
  
- `-r, --retries <num>`  
  Number of attempts for `docker pull` for each image (must be ≥ 1).  
  `1` means a single attempt (no extra retries).  
  On failure, each retry waits 2 seconds before the next attempt.

- `-d, --delete`
  Delete the output directory after a successful zip, keeping only the zip file.

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
  
Use defaults (read `images.txt`, write into `~/Downloads/images/`, create `~/Downloads/images.zip`):

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
  
- `0` – success.  
- Non‑zero – error conditions, such as:  
  - Input file missing.  
  - No tar files created to zip.  
  - Zip creation failure.  
  - Docker pull/save failures (for specific images).  
  
---
  
## Notes

- The script assumes Docker is already installed and configured on the host.
- Install via `make install`; the binary is called `images2zip`.
- The generated zip can be moved to another machine and loaded with `docker load` on that side.