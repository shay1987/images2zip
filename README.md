# images2zip

images2zip is a small CLI utility that reads a list of Docker images, pulls them (with optional retries), saves them as tar files, packs them into a zip archive, and logs every step to a timestamped log file.  
  
It is designed for air‑gapped or constrained environments where you need to pre‑bundle images and move them as a single archive.  
  
---
  
## Features
  
- Read Docker image names from a text file.  
- Pull each image with configurable retry logic.  
- Retag Harbor images by stripping the prefix.  
- Save each image as a `.tar` file.  
- Zip all `.tar` files into a single `<name>.zip`.  
- Timestamped logging to `images2zip.log`.  
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

```bash
./images2zip.sh [OPTIONS]
  ```
  
### Options
  
- `-f, --file <file>`  
  Input file containing Docker image references, one per line.  
  Default: `images.txt`.  
  
- `-n, --name <name>`  
  Set the output directory and zip name.  
  The script creates a directory `<name>/` and a zip `<name>.zip`.  
  Default: `images` → `images/` and `images.zip`.  
  
- `-r, --retries <num>`  
  Number of attempts for `docker pull` for each image (must be ≥ 1).  
  `1` means a single attempt (no extra retries).  
  On failure, each retry waits 5 seconds before the next attempt.  
  
- `-d, --delete`  
  Delete the output directory after a successful zip, keeping only the zip file.  
  
- `-h, --help`  
  Show a short help message and exit.   
  
---
  
## Input file format

The input file is a plain text file containing Docker image references, one per line, for example:   

```text
shay1987/arcade:latest
nginx:latest
alpine:3.19
  ```
  
- Empty lines and whitespace‑only lines are ignored.  
- For images starting with `harbor.getapp.sh/`, the script strips this prefix when retagging, e.g.:  
  
```text
harbor.getapp.sh/library/nginx:1.25  ->  library/nginx:1.25
  ```
  
This makes the saved images easier to use in other environments.  
  
---
  
## Examples
  
Use defaults (read `images.txt`, write into `images/`, create `images.zip`):  

```bash
./images2zip.sh
  ```
  
Use a custom input file and output name:  

```bash
./images2zip.sh -f my_images.txt -n getapp-images
  ```
  
Enable retries and delete the tar directory after zipping:  

```bash
./images2zip.sh -f images.txt -n images-pack -r 3 -d
  ```
  
Show help:  

```bash
./images2zip.sh -h
  ```
  
---
  
## Logging
  
The script writes log messages to:  

```text
images2zip.log
  ```
  
in the current working directory.  
  
Each log line is prefixed with a timestamp, for example:  
  
```text
2026-01-19 20:30:00 File 'images.txt' found. Proceeding...
2026-01-19 20:30:05 Attempt 1/3 for pulling image: harbor.getapp.sh/library/nginx:1.25
2026-01-19 20:31:10 Successfully created zip file: images.zip
2026-01-19 20:31:10 Summary: images in file = 10, images zipped = 9, retries = 3
  ```
  
Logged events include:  
  
- Configuration (input file, output directory, retry count).  
- Per‑image processing (pull attempts, tagging, saving to tar).  
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
- It is intended to be run from a directory containing:
  - `images2zip.sh`
  - Your input file (e.g. `images.txt`)
- The generated zip can be moved to another machine and loaded with `docker load` on that side.