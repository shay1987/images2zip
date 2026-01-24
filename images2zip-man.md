# images2zip(1)

## NAME
**images2zip** – download Docker images, save them as tar files, zip them, and log all operations. [file:1]

## SYNOPSIS
**images2zip.sh** \[**OPTIONS**] [file:1]

## DESCRIPTION
**images2zip.sh** reads a list of Docker image references from a text file, pulls each image, retags it, saves it as a tar archive into a directory, and finally creates a zip archive containing all generated tar files. [file:1]
The script writes a timestamped log of all operations to `images2zip.log`, including successes, failures, retry attempts, and a final summary with image counts. [file:1]
By default, the script expects an `images.txt` file in the current working directory and creates an `images/` directory with `images.zip`. [file:1]

## OPTIONS
**-f**, **--file** *FILE*
: Use *FILE* as the input file containing the list of Docker images, one per line. Default: `images.txt`. [file:1]

**-n**, **--name** *NAME*
: Set the output directory name and resulting zip file name. The script creates a directory named *NAME* and a zip file named `NAME.zip`. Default: directory `images`, zip `images.zip`. [file:1]

**-r**, **--retries** *NUM*
: Set the number of attempts for `docker pull` for each image. `NUM` must be a positive integer. A value of `1` means a single attempt (no extra retries). On failure the script logs each attempt and waits 5 seconds before retrying. [file:1]

**-d**, **--delete**
: Delete the output directory after a successful zip is created, keeping only the zip file. [file:1]

**-h**, **--help**
: Display a short help message describing usage, options, and default values, then exit. [file:1]

## INPUT FILE FORMAT
The input file is a plain text file containing Docker image references, one per line, for example: [file:1]

(Replace the next two lines with ```text and ``` after pasting)
```text
harbor.getapp.sh/library/nginx:1.25
harbor.getapp.sh/library/redis:7
docker.io/library/alpine:3.19
```

Empty lines and lines with only whitespace are ignored. [file:1]
For images pulled from `harbor.getapp.sh`, the script strips the registry prefix and retags them (for example, `harbor.getapp.sh/library/nginx:1.25` → `library/nginx:1.25`) to simplify later use in other environments. [file:1]

## OPERATION
1. **Argument parsing** – parses options to determine input file, output directory, retry count, delete behavior, and help. [file:1]
2. **Input validation** – checks the existence of the input file and counts non‑empty lines. [file:1]
3. **Image processing** – for each non‑empty line: pulls with retry logic, retags Harbor images, and saves to a tar file. [file:1]
4. **Archiving** – collects all `*.tar` files and creates `<output_directory>.zip`. [file:1]
5. **Optional cleanup** – if `-d`/`--delete` is set and zip succeeded, removes the output directory. [file:1]
6. **Logging and summary** – logs all operations and ends with a summary: images in file, images zipped, retry count. [file:1]

## LOGGING
All actions and errors are logged with timestamps to `images2zip.log`. Logged events include configuration, per‑image status, zip creation, and optional directory deletion. [file:1]

## EXIT STATUS
Exit status 0 on success; non‑zero on missing input file, no tar files to zip, or zip failure. [file:1]

## EXAMPLES

(Replace the markers around each example with ```sh and ``` after pasting)

Run with defaults: [file:1]
```sh
./images2zip.sh
```

Custom input and output name: [file:1]
```sh
./images2zip.sh -f my_images.txt -n getapp-images
```

Retries and delete tars afterward: [file:1]
```sh
./images2zip.sh -f images.txt -n images-pack -r 3 -d
```

Show help: [file:1]
```sh
./images2zip.sh -h
```

## FILES
`images2zip.sh` – the script itself. [file:1]
`images2zip.log` – log file with timestamped execution information. [file:1]
`images.txt` (or custom input file) – list of Docker images to process. [file:1]
`<name>/` – output directory containing tar files. [file:1]
`<name>.zip` – zip archive containing all tar files produced. [file:1]

## SEE ALSO
**docker-pull**(1), **docker-save**(1), **zip**(1) [file:1]