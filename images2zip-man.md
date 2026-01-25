# images2zip(1)

## NAME
**images2zip** – download Docker images, save them as tar files, zip them, and log all operations.  

## SYNOPSIS
**images2zip.sh** \[**OPTIONS**]  

## DESCRIPTION
**images2zip.sh** reads a list of Docker image references from a text file, pulls each image, retags it, saves it as a tar archive into a directory, and finally creates a zip archive containing all generated tar files.  
The script writes a timestamped log of all operations to `images2zip.log`, including successes, failures, retry attempts, and a final summary with image counts.  
By default, the script expects an `images.txt` file in the current working directory and creates an `images/` directory with `images.zip`. With the `-s/--save` option, outputs are written under a configurable base directory (default: `~/Downloads`).   
  
## OPTIONS
**-f**, **--file** *FILE*  
: Use *FILE* as the input file containing the list of Docker images, one per line. Default: `images.txt`.  
  
**-n**, **--name** *NAME*  
: Set the output name (directory and zip base name). The script creates a directory named *NAME* under the save directory and a zip file named `NAME.zip` in the same location. Default: `images`.   
  
**-s**, **--save** *DIR*  
: Set the base directory where the output directory and zip file are created.  
  Default: `~/Downloads`.  
  
**-r**, **--retries** *NUM*  
: Set the number of attempts for `docker pull` for each image. `NUM` must be a positive integer. A value of `1` means a single attempt (no extra retries). On failure the script logs each attempt and waits 5 seconds before retrying.   
  
**-d**, **--delete**  
: Delete the output directory after a successful zip is created, keeping only the zip file.   
  
**-h**, **--help**  
: Display a short help message describing usage, options, and default values, then exit.  
  
## INPUT FILE FORMAT
The input file is a plain text file containing Docker image references, one per line, for example:  

 ```
shay1987/arcade:latest
nginx:latest
alpine:3.19
 ```
  
Empty lines and lines with only whitespace are ignored.    
If your images are hosted in a private registry, you can include the registry prefix, for example:  

 ```
myregistry.local:5000/team/app-backend:1.2.3
myregistry.local:5000/team/app-frontend:2.0.0
 ```
  
The script will retag images according to its internal rules to make them easier to use in other environments.   
  
## OPERATION
1. **Argument parsing** – parses options to determine input file, save directory, output name, retry count, delete behavior, and help.     
2. **Input validation** – checks the existence of the input file and counts non‑empty lines.    
3. **Image processing** – for each non‑empty line: pulls with retry logic, retags images, and saves to a tar file in the output directory.     
4. **Archiving** – collects all `*.tar` files and creates `<save>/<name>.zip`.     
5. **Optional cleanup** – if `-d`/`--delete` is set and zip succeeded, removes the output directory.    
6. **Logging and summary** – logs all operations and ends with a summary: images in file, images zipped, retry count.   
  
## LOGGING
All actions and errors are logged with timestamps to `images2zip.log`. Logged events include configuration, per‑image status, zip creation, and optional directory deletion.  
  
## EXIT STATUS
Exit status 0 on success; non‑zero on missing input file, no tar files to zip, or zip failure.  
  
## EXAMPLES
  
(Replace the markers around each example with ```sh and ``` after pasting)  
  
Run with defaults:    
 ```
./images2zip.sh
 ```
  
Custom input and output name (saved under `~/Downloads`):     
 ```
./images2zip.sh -f my_images.txt -n my-bundle
 ```
  
Custom save directory and retries:    
 ```
./images2zip.sh -f images.txt -n lab-pack -s /mnt/shared -r 3
 ```
  
Retries and delete tars afterward:    
 ```
./images2zip.sh -f images.txt -n images-pack -r 3 -d
 ```
  
Show help:    
 ```
./images2zip.sh -h
 ```
  
## FILES
`images2zip.sh` – the script itself.    
`images2zip.log` – log file with timestamped execution information.    
`images.txt` (or custom input file) – list of Docker images to process.    
`<save>/<name>/` – output directory containing tar files.     
`<save>/<name>.zip` – zip archive containing all tar files produced.   
  
## SEE ALSO
**docker-pull**(1), **docker-save**(1), **zip**(1)  