#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IMAGES2ZIP="$PROJECT_ROOT/bin/images2zip"

# Test output directory
TEST_WORKDIR="$SCRIPT_DIR/tmp"
PASSED=0
FAILED=0
SKIPPED=0

# Test image - nginx:alpine is small and common
TEST_IMAGE="nginx:alpine"
TEST_IMAGE_TAR="nginx_alpine.tar"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

cleanup() {
    rm -rf "$TEST_WORKDIR"
}

setup() {
    cleanup
    mkdir -p "$TEST_WORKDIR"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    PASSED=$((PASSED + 1))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1: $2"
    FAILED=$((FAILED + 1))
}

log_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $1"
    SKIPPED=$((SKIPPED + 1))
}

log_info() {
    echo -e "[INFO] $1"
}

# Check if docker is available
check_docker() {
    if ! command -v docker &>/dev/null; then
        return 1
    fi
    if ! docker ps &>/dev/null; then
        return 1
    fi
    return 0
}

# Validate that a zip contains a valid docker image tar
validate_zip_contains_docker_image() {
    local zip_file="$1"
    local expected_tar="$2"
    local extract_dir="$TEST_WORKDIR/extract_$$"

    mkdir -p "$extract_dir"

    # Extract zip
    if ! unzip -q "$zip_file" -d "$extract_dir"; then
        echo "failed to extract zip"
        rm -rf "$extract_dir"
        return 1
    fi

    # Check tar exists
    if [[ ! -f "$extract_dir/$expected_tar" ]]; then
        echo "tar file $expected_tar not found in zip"
        rm -rf "$extract_dir"
        return 1
    fi

    # Check tar is valid and contains manifest.json (docker image format)
    if ! tar -tf "$extract_dir/$expected_tar" | grep -q "manifest.json"; then
        echo "tar does not contain manifest.json (not a valid docker image)"
        rm -rf "$extract_dir"
        return 1
    fi

    rm -rf "$extract_dir"
    return 0
}

# Test: Help flag shows usage
test_help_flag() {
    local test_name="Help flag (-h) shows usage"
    local output
    output=$("$IMAGES2ZIP" -h 2>&1) || true

    if echo "$output" | grep -q "Usage:"; then
        log_pass "$test_name"
    else
        log_fail "$test_name" "usage text not found"
    fi
}

# Test: Help flag long form
test_help_flag_long() {
    local test_name="Help flag (--help) shows usage"
    local output
    output=$("$IMAGES2ZIP" --help 2>&1) || true

    if echo "$output" | grep -q "Usage:"; then
        log_pass "$test_name"
    else
        log_fail "$test_name" "usage text not found"
    fi
}

# Test: Unknown option shows error
test_unknown_option() {
    local test_name="Unknown option shows error"
    local output
    output=$("$IMAGES2ZIP" --invalid-option 2>&1) || true

    if echo "$output" | grep -q "Unknown option"; then
        log_pass "$test_name"
    else
        log_fail "$test_name" "error message not found"
    fi
}

# Test: Missing input file shows error
test_missing_input_file() {
    local test_name="Missing input file shows error"
    cd "$TEST_WORKDIR"

    local output
    output=$("$IMAGES2ZIP" -f nonexistent.txt 2>&1) || true

    if echo "$output" | grep -q "does not exist"; then
        log_pass "$test_name"
    else
        log_fail "$test_name" "error message not found"
    fi
}

# Test: Flag requiring value without value shows error
test_flag_requires_value() {
    local test_name="Flag -f without value shows error"
    local output
    output=$("$IMAGES2ZIP" -f 2>&1) || true

    if echo "$output" | grep -q "requires a value"; then
        log_pass "$test_name"
    else
        log_fail "$test_name" "error message not found"
    fi
}

# Test: Retries flag with invalid value shows error
test_retries_invalid_value() {
    local test_name="Retries flag with invalid value shows error"
    local output
    output=$("$IMAGES2ZIP" -r abc 2>&1) || true

    if echo "$output" | grep -q "must be a positive integer"; then
        log_pass "$test_name"
    else
        log_fail "$test_name" "error message not found"
    fi
}

# Test: Retries flag with zero shows error
test_retries_zero() {
    local test_name="Retries flag with zero shows error"
    local output
    output=$("$IMAGES2ZIP" -r 0 2>&1) || true

    if echo "$output" | grep -q "must be a positive integer"; then
        log_pass "$test_name"
    else
        log_fail "$test_name" "error message not found"
    fi
}

# Test: Default behavior - creates valid docker image zip
test_default_behavior() {
    local test_name="Default behavior creates valid docker image zip"

    if ! check_docker; then
        log_skip "$test_name (docker unavailable)"
        return
    fi

    cd "$TEST_WORKDIR"
    echo "$TEST_IMAGE" > images.txt

    local output
    if ! output=$("$IMAGES2ZIP" -s "$TEST_WORKDIR" -d 2>&1); then
        log_fail "$test_name" "script failed"
        return
    fi

    # default output name: images-<dd-mm-YYYY>
    local today
    today="$(date '+%d-%m-%Y')"
    local expected_name="images-${today}"
    local expected_zip="$TEST_WORKDIR/${expected_name}.zip"

    if [[ ! -f "$expected_zip" ]]; then
        log_fail "$test_name" "zip file not created at $expected_zip"
        return
    fi

    local validation_error
    if validation_error=$(validate_zip_contains_docker_image "$expected_zip" "$TEST_IMAGE_TAR"); then
        log_pass "$test_name"
    else
        log_fail "$test_name" "$validation_error"
    fi
}

# Test: Custom output name
test_custom_output_name() {
    local test_name="Custom output name (-n) creates correctly named zip"

    if ! check_docker; then
        log_skip "$test_name (docker unavailable)"
        return
    fi

    cd "$TEST_WORKDIR"
    echo "$TEST_IMAGE" > images.txt

    local output
    if ! output=$("$IMAGES2ZIP" -s "$TEST_WORKDIR" -n my_images -d 2>&1); then
        log_fail "$test_name" "script failed"
        return
    fi

    if [[ ! -f "$TEST_WORKDIR/my_images.zip" ]]; then
        log_fail "$test_name" "my_images.zip not created"
        return
    fi

    local validation_error
    if validation_error=$(validate_zip_contains_docker_image "$TEST_WORKDIR/my_images.zip" "$TEST_IMAGE_TAR"); then
        log_pass "$test_name"
    else
        log_fail "$test_name" "$validation_error"
    fi
}

# Test: Custom input file
test_custom_input_file() {
    local test_name="Custom input file (-f) works"

    if ! check_docker; then
        log_skip "$test_name (docker unavailable)"
        return
    fi

    cd "$TEST_WORKDIR"
    echo "$TEST_IMAGE" > custom_list.txt

    local output
    if ! output=$("$IMAGES2ZIP" -f custom_list.txt -s "$TEST_WORKDIR" -n from_custom -d 2>&1); then
        log_fail "$test_name" "script failed"
        return
    fi

    local validation_error
    if validation_error=$(validate_zip_contains_docker_image "$TEST_WORKDIR/from_custom.zip" "$TEST_IMAGE_TAR"); then
        log_pass "$test_name"
    else
        log_fail "$test_name" "$validation_error"
    fi
}

# Test: Delete flag removes directory but keeps zip
test_delete_flag() {
    local test_name="Delete flag (-d) removes directory, keeps valid zip"

    if ! check_docker; then
        log_skip "$test_name (docker unavailable)"
        return
    fi

    cd "$TEST_WORKDIR"
    echo "$TEST_IMAGE" > images.txt

    local output
    if ! output=$("$IMAGES2ZIP" -s "$TEST_WORKDIR" -n delete_test -d 2>&1); then
        log_fail "$test_name" "script failed"
        return
    fi

    if [[ -d "$TEST_WORKDIR/delete_test" ]]; then
        log_fail "$test_name" "directory was not deleted"
        return
    fi

    if [[ ! -f "$TEST_WORKDIR/delete_test.zip" ]]; then
        log_fail "$test_name" "zip file not created"
        return
    fi

    local validation_error
    if validation_error=$(validate_zip_contains_docker_image "$TEST_WORKDIR/delete_test.zip" "$TEST_IMAGE_TAR"); then
        log_pass "$test_name"
    else
        log_fail "$test_name" "$validation_error"
    fi
}

# Test: Without delete flag, directory is preserved
test_no_delete_keeps_directory() {
    local test_name="Without -d flag, output directory is preserved"

    if ! check_docker; then
        log_skip "$test_name (docker unavailable)"
        return
    fi

    cd "$TEST_WORKDIR"
    echo "$TEST_IMAGE" > images.txt

    local output
    if ! output=$("$IMAGES2ZIP" -s "$TEST_WORKDIR" -n keep_dir 2>&1); then
        log_fail "$test_name" "script failed"
        return
    fi

    if [[ ! -d "$TEST_WORKDIR/keep_dir" ]]; then
        log_fail "$test_name" "directory was deleted"
        return
    fi

    if [[ ! -f "$TEST_WORKDIR/keep_dir/$TEST_IMAGE_TAR" ]]; then
        log_fail "$test_name" "tar file not in directory"
        return
    fi

    # Verify tar is valid
    if tar -tf "$TEST_WORKDIR/keep_dir/$TEST_IMAGE_TAR" | grep -q "manifest.json"; then
        log_pass "$test_name"
    else
        log_fail "$test_name" "tar is not a valid docker image"
    fi
}

# Test: Verbose flag produces more output
test_verbose_flag() {
    local test_name="Verbose flag (-v) produces VERBOSE output"

    if ! check_docker; then
        log_skip "$test_name (docker unavailable)"
        return
    fi

    cd "$TEST_WORKDIR"
    echo "$TEST_IMAGE" > images.txt

    local output_verbose
    output_verbose=$("$IMAGES2ZIP" -s "$TEST_WORKDIR" -n verbose_test -v -d 2>&1) || true

    if echo "$output_verbose" | grep -q "VERBOSE"; then
        log_pass "$test_name"
    else
        log_fail "$test_name" "VERBOSE messages not found in output"
    fi
}

# Test: Log flag creates log file with content
test_log_flag() {
    local test_name="Log flag (-l) creates log file with entries"

    if ! check_docker; then
        log_skip "$test_name (docker unavailable)"
        return
    fi

    cd "$TEST_WORKDIR"
    echo "$TEST_IMAGE" > images.txt

    local output
    if ! output=$("$IMAGES2ZIP" -s "$TEST_WORKDIR" -n log_test -l "$TEST_WORKDIR/test.log" -d 2>&1); then
        log_fail "$test_name" "script failed"
        return
    fi

    if [[ ! -f "$TEST_WORKDIR/test.log" ]]; then
        log_fail "$test_name" "log file not created"
        return
    fi

    # Check log has actual content
    if [[ $(wc -l < "$TEST_WORKDIR/test.log") -lt 2 ]]; then
        log_fail "$test_name" "log file is empty or too short"
        return
    fi

    if grep -q "SUCCESS" "$TEST_WORKDIR/test.log"; then
        log_pass "$test_name"
    else
        log_fail "$test_name" "log file missing SUCCESS entries"
    fi
}

# Test: Long form flags work
test_long_form_flags() {
    local test_name="Long form flags (--file, --name, --save, --delete)"

    if ! check_docker; then
        log_skip "$test_name (docker unavailable)"
        return
    fi

    cd "$TEST_WORKDIR"
    echo "$TEST_IMAGE" > longform.txt

    local output
    if ! output=$("$IMAGES2ZIP" --file longform.txt --name longform_test --save "$TEST_WORKDIR" --delete 2>&1); then
        log_fail "$test_name" "script failed"
        return
    fi

    local validation_error
    if validation_error=$(validate_zip_contains_docker_image "$TEST_WORKDIR/longform_test.zip" "$TEST_IMAGE_TAR"); then
        log_pass "$test_name"
    else
        log_fail "$test_name" "$validation_error"
    fi
}

# Test: Multiple images creates zip with multiple tars
test_multiple_images() {
    local test_name="Multiple images creates zip with multiple valid tars"

    if ! check_docker; then
        log_skip "$test_name (docker unavailable)"
        return
    fi

    cd "$TEST_WORKDIR"
    cat > multi.txt <<EOF
nginx:alpine
busybox:latest
EOF

    local output
    if ! output=$("$IMAGES2ZIP" -f multi.txt -s "$TEST_WORKDIR" -n multi_test -d 2>&1); then
        log_fail "$test_name" "script failed"
        return
    fi

    local extract_dir="$TEST_WORKDIR/multi_extract"
    mkdir -p "$extract_dir"
    unzip -q "$TEST_WORKDIR/multi_test.zip" -d "$extract_dir"

    # Check both tars exist
    if [[ ! -f "$extract_dir/nginx_alpine.tar" ]]; then
        log_fail "$test_name" "nginx_alpine.tar not found"
        rm -rf "$extract_dir"
        return
    fi

    if [[ ! -f "$extract_dir/busybox_latest.tar" ]]; then
        log_fail "$test_name" "busybox_latest.tar not found"
        rm -rf "$extract_dir"
        return
    fi

    # Validate both are docker images
    if ! tar -tf "$extract_dir/nginx_alpine.tar" | grep -q "manifest.json"; then
        log_fail "$test_name" "nginx_alpine.tar is not a valid docker image"
        rm -rf "$extract_dir"
        return
    fi

    if ! tar -tf "$extract_dir/busybox_latest.tar" | grep -q "manifest.json"; then
        log_fail "$test_name" "busybox_latest.tar is not a valid docker image"
        rm -rf "$extract_dir"
        return
    fi

    rm -rf "$extract_dir"
    log_pass "$test_name"
}

# Test: Zip file size is reasonable (not empty)
test_zip_has_content() {
    local test_name="Zip file has substantial content (>1KB)"

    if ! check_docker; then
        log_skip "$test_name (docker unavailable)"
        return
    fi

    cd "$TEST_WORKDIR"
    echo "$TEST_IMAGE" > images.txt

    local output
    if ! output=$("$IMAGES2ZIP" -s "$TEST_WORKDIR" -n size_test -d 2>&1); then
        log_fail "$test_name" "script failed"
        return
    fi

    local size
    size=$(stat -c%s "$TEST_WORKDIR/size_test.zip" 2>/dev/null || stat -f%z "$TEST_WORKDIR/size_test.zip" 2>/dev/null)

    if [[ $size -gt 1024 ]]; then
        log_pass "$test_name"
    else
        log_fail "$test_name" "zip is only ${size} bytes"
    fi
}

# Test: Can load image back from tar
test_image_can_be_loaded() {
    local test_name="Exported image can be loaded back into docker"

    if ! check_docker; then
        log_skip "$test_name (docker unavailable)"
        return
    fi

    cd "$TEST_WORKDIR"
    echo "$TEST_IMAGE" > images.txt

    local output
    if ! output=$("$IMAGES2ZIP" -s "$TEST_WORKDIR" -n load_test -d 2>&1); then
        log_fail "$test_name" "script failed"
        return
    fi

    # Extract and load
    local extract_dir="$TEST_WORKDIR/load_extract"
    mkdir -p "$extract_dir"
    unzip -q "$TEST_WORKDIR/load_test.zip" -d "$extract_dir"

    # Remove the image first to ensure we're testing the load
    docker rmi "$TEST_IMAGE" &>/dev/null || true

    if docker load -i "$extract_dir/$TEST_IMAGE_TAR" &>/dev/null; then
        log_pass "$test_name"
    else
        log_fail "$test_name" "docker load failed"
    fi

    rm -rf "$extract_dir"
}

# Main
main() {
    echo "========================================"
    echo "images2zip.sh Test Suite"
    echo "========================================"
    echo ""

    if ! check_docker; then
        echo -e "${RED}Docker is not available. Docker-dependent tests will be skipped.${NC}"
        echo ""
    fi

    setup
    trap cleanup EXIT

    log_info "Running tests with image: $TEST_IMAGE"
    echo ""

    # Tests that don't require docker
    test_help_flag
    test_help_flag_long
    test_unknown_option
    test_missing_input_file
    test_flag_requires_value
    test_retries_invalid_value
    test_retries_zero

    # Tests that require docker and validate actual output
    test_default_behavior
    test_custom_output_name
    test_custom_input_file
    test_delete_flag
    test_no_delete_keeps_directory
    test_verbose_flag
    test_log_flag
    test_long_form_flags
    test_multiple_images
    test_zip_has_content
    test_image_can_be_loaded

    echo ""
    echo "========================================"
    echo -e "Results: ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}, ${YELLOW}$SKIPPED skipped${NC}"
    echo "========================================"

    if [[ $FAILED -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
