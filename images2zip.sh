#!/bin/bash

# Default values
log_file="images2zip.log"
input_file="images.txt"
output_name="images"               # logical name
save_directory="$HOME/Downloads"   # new: base directory for output dir + zip
delete_dir=false
retries=1   # default: 1 attempt (no extra retries)

log() {
    # Timestamp format: 2026-01-19 20:30:00
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$log_file"
}

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Download Docker images listed in an input file, save them as tar files,
zip them, and log all operations.

Options:
  -f, --file <file>     Set input file with image list (default: images.txt)
  -n, --name <name>     Set output name (directory and zip base name, default: images)
  -s, --save <dir>      Set base directory where output dir and zip are created
                        (default: \$HOME/Downloads)
  -r, --retries <num>   Number of retries for docker pull (default: 1 = no extra retries)
  -d, --delete          Delete the output directory at the end (after successful zip)
  -h, --help            Show this help message and exit

Notes:
  - Input file is: $input_file
  - Log file is:   $log_file
EOF
}

docker_pull_with_retries() {
    local image="$1"
    local attempt=1

    while true; do
        log "Attempt $attempt/$retries for pulling image: $image"
        if docker pull "$image"; then
            log "Successfully pulled image: $image on attempt $attempt"
            return 0
        fi

        if (( attempt >= retries )); then
            log "Error: Failed to pull image '$image' after $attempt attempt(s)."
            return 1
        fi

        attempt=$((attempt + 1))
        log "Failed to pull '$image', retrying in 5 seconds..."
        sleep 5
    done
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--file)
            if [[ -z "${2:-}" ]]; then
                echo "Error: -f/--file requires a value." >&2
                exit 1
            fi
            input_file="$2"
            shift 2
            ;;
        -n|--name)
            if [[ -z "${2:-}" ]]; then
                echo "Error: -n/--name requires a value." >&2
                exit 1
            fi
            output_name="$2"
            shift 2
            ;;
        -s|--save)
            if [[ -z "${2:-}" ]]; then
                echo "Error: -s/--save requires a directory path." >&2
                exit 1
            fi
            save_directory="$2"
            shift 2
            ;;
        -r|--retries)
            if [[ -z "${2:-}" ]]; then
                echo "Error: -r/--retries requires a numeric value." >&2
                exit 1
            fi
            if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                echo "Error: -r/--retries must be a non-negative integer." >&2
                exit 1
            fi
            retries="$2"
            if (( retries < 1 )); then
                echo "Error: -r/--retries must be at least 1." >&2
                exit 1
            fi
            shift 2
            ;;
        -d|--delete)
            delete_dir=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 1
            ;;
    esac
done

# Resolve and create save_directory
save_directory="${save_directory/#\~/$HOME}"
mkdir -p "$save_directory"

output_directory="$save_directory/$output_name"
output_zip="$save_directory/${output_name}.zip"

# Count non-empty lines (images) in the input file
if [ -f "$input_file" ]; then
    total_images_in_file=$(grep -v '^[[:space:]]*$' "$input_file" | wc -l)
else
    total_images_in_file=0
fi

# Check if the input file exists
if [ ! -f "$input_file" ]; then
    log "Error: File '$input_file' does not exist in the current directory."
    log "Exiting..."
    exit 1
fi

log "File '$input_file' found. Proceeding..."
log "Total images listed in '$input_file': $total_images_in_file"
log "Using retries for docker pull: $retries"
log "Save directory: $save_directory"
log "Output directory: $output_directory"
log "Zip file will be named: $output_zip"

# Create the output directory if it doesn't exist
mkdir -p "$output_directory"

log "Starting to process Docker images from '$input_file'..."
log "This might take some time, depending on your internet speed."

# Process each image from the input file
while IFS= read -r image; do
    # Skip empty lines
    if [ -n "$image" ]; then
        log "Processing image: $image"

        # Pull the Docker image with retries
        if docker_pull_with_retries "$image"; then
            # Retag the image for Even
            even_image_tag=$(echo "$image" | sed 's|harbor\.getapp\.sh/||')
            docker tag "$image" "$even_image_tag"
            log "Tagged '$image' as '$even_image_tag' for easier uploading to Even."

            # Save the image to a tar file
            output_tar="$output_directory/$(echo "$even_image_tag" | tr / _).tar"
            log "Saving '$even_image_tag' to tar file: $output_tar"
            if docker save "$even_image_tag" -o "$output_tar"; then
                log "Successfully saved image '$even_image_tag' to '$output_tar'"
            else
                log "Error: Failed to save image '$even_image_tag' to '$output_tar'"
            fi
        else
            log "Error: Failed to pull or process image '$image' after retries. Skipping..."
        fi
    fi
done < "$input_file"

# Zip all tar files into a single zip archive
log "Collecting tar files to add to zip..."

tar_files=( "$output_directory"/*.tar )

if [ ${#tar_files[@]} -eq 0 ]; then
    log "No tar files found in '$output_directory'. Nothing to zip."
    log "Summary: images in file = $total_images_in_file, images zipped = 0, retries = $retries"
    exit 1
fi

for f in "${tar_files[@]}"; do
    log "Will add to zip: $f"
done

log "Creating zip file: $output_zip"

if zip -j "$output_zip" "${tar_files[@]}"; then
    log "Successfully created zip file: $output_zip"
    for f in "${tar_files[@]}"; do
        log "Successfully added to zip: $f"
    done
else
    log "Error: Failed to create zip file. Check available storage or permissions."
    log "Summary: images in file = $total_images_in_file, images zipped = 0, retries = $retries"
    exit 1
fi

total_zipped=${#tar_files[@]}
log "Summary: images in file = $total_images_in_file, images zipped = $total_zipped, retries = $retries"

# Optional delete of output directory
if [ "$delete_dir" = true ]; then
    log "Deleting output directory: $output_directory"
    rm -rf "$output_directory"
    log "Output directory '$output_directory' deleted."
fi

log "All Docker images have been saved and zipped into '$output_zip'."
log "Process complete!"