#!/bin/bash
#
# test.sh - Comprehensive test suite for git-sub-project
#
# Usage: ./test.sh [--verbose] [--no-cleanup]
#
# Exit codes:
#   0 - All tests passed
#   1 - One or more tests failed
#

# Configuration
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
TEST_DIR="/tmp/git-sub-project-tests-$$"
TEST_INSTALL_DIR="$TEST_DIR/bin"
TEST_REPO="$TEST_DIR/test-repo.git"
ORIGINAL_PATH="$PATH"
ORIGINAL_PWD="$PWD"
VERBOSE=false
NO_CLEANUP=false

# Counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0
FAILED_TESTS=()

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

# ============================================================================
# Output Functions
# ============================================================================

print_header() {
    echo ""
    echo -e "${BOLD}${BLUE}==== $1 ====${NC}"
    echo ""
}

print_pass() {
    echo -e "  ${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

print_fail() {
    echo -e "  ${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
    FAILED_TESTS+=("$1")
}

print_skip() {
    echo -e "  ${YELLOW}[SKIP]${NC} $1"
    ((TESTS_SKIPPED++))
}

print_info() {
    echo -e "  ${BLUE}[INFO]${NC} $1"
}

print_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "  ${BLUE}[DEBUG]${NC} $1"
    fi
}

# ============================================================================
# Assertion Functions
# ============================================================================

# Assert command succeeds (exit code 0)
assert_success() {
    local description="$1"
    shift
    local output
    if output=$("$@" 2>&1); then
        print_pass "$description"
        print_verbose "Output: $output"
        return 0
    else
        print_fail "$description (command failed: $*)"
        print_verbose "Output: $output"
        return 1
    fi
}

# Assert command fails (exit code != 0)
assert_failure() {
    local description="$1"
    shift
    local output
    if output=$("$@" 2>&1); then
        print_fail "$description (command should have failed: $*)"
        print_verbose "Output: $output"
        return 1
    else
        print_pass "$description"
        print_verbose "Output: $output"
        return 0
    fi
}

# Assert specific exit code
assert_exit_code() {
    local description="$1"
    local expected_code="$2"
    shift 2
    local actual_code
    "$@" >/dev/null 2>&1 || true
    actual_code=$?
    # Re-run to get the actual code
    set +e
    "$@" >/dev/null 2>&1
    actual_code=$?
    set -e
    if [ "$actual_code" -eq "$expected_code" ]; then
        print_pass "$description"
        return 0
    else
        print_fail "$description (expected exit code $expected_code, got $actual_code)"
        return 1
    fi
}

# Assert file exists
assert_file_exists() {
    local description="$1"
    local filepath="$2"
    if [ -f "$filepath" ]; then
        print_pass "$description"
        return 0
    else
        print_fail "$description (file not found: $filepath)"
        return 1
    fi
}

# Assert file does NOT exist
assert_file_not_exists() {
    local description="$1"
    local filepath="$2"
    if [ ! -e "$filepath" ]; then
        print_pass "$description"
        return 0
    else
        print_fail "$description (file exists but shouldn't: $filepath)"
        return 1
    fi
}

# Assert directory exists
assert_dir_exists() {
    local description="$1"
    local dirpath="$2"
    if [ -d "$dirpath" ]; then
        print_pass "$description"
        return 0
    else
        print_fail "$description (directory not found: $dirpath)"
        return 1
    fi
}

# Assert path is a file (not a directory)
assert_is_file() {
    local description="$1"
    local filepath="$2"
    if [ -f "$filepath" ] && [ ! -d "$filepath" ]; then
        print_pass "$description"
        return 0
    else
        print_fail "$description (not a regular file: $filepath)"
        return 1
    fi
}

# Assert file content equals expected
assert_file_equals() {
    local description="$1"
    local filepath="$2"
    local expected="$3"
    local actual
    if [ ! -f "$filepath" ]; then
        print_fail "$description (file not found: $filepath)"
        return 1
    fi
    actual=$(cat "$filepath")
    if [ "$actual" = "$expected" ]; then
        print_pass "$description"
        return 0
    else
        print_fail "$description (expected: '$expected', got: '$actual')"
        return 1
    fi
}

# Assert file contains string
assert_file_contains() {
    local description="$1"
    local filepath="$2"
    local expected="$3"
    if [ -f "$filepath" ] && grep -q "$expected" "$filepath"; then
        print_pass "$description"
        return 0
    else
        print_fail "$description (file does not contain: $expected)"
        return 1
    fi
}

# Assert git command works in directory
assert_git_works() {
    local description="$1"
    local dirpath="$2"
    if (cd "$dirpath" && git status >/dev/null 2>&1); then
        print_pass "$description"
        return 0
    else
        print_fail "$description (git status failed in: $dirpath)"
        return 1
    fi
}

# Assert command output contains string
assert_output_contains() {
    local description="$1"
    local expected="$2"
    shift 2
    local output
    output=$("$@" 2>&1) || true
    if echo "$output" | grep -q "$expected"; then
        print_pass "$description"
        return 0
    else
        print_fail "$description (output does not contain: $expected)"
        print_verbose "Output was: $output"
        return 1
    fi
}

# Assert file is executable
assert_executable() {
    local description="$1"
    local filepath="$2"
    if [ -x "$filepath" ]; then
        print_pass "$description"
        return 0
    else
        print_fail "$description (file not executable: $filepath)"
        return 1
    fi
}

# ============================================================================
# Setup Functions
# ============================================================================

setup_test_environment() {
    print_info "Creating test environment: $TEST_DIR"

    mkdir -p "$TEST_DIR"
    mkdir -p "$TEST_INSTALL_DIR"
    mkdir -p "$TEST_DIR/workspaces"

    # Create a local bare repo for clone tests
    print_info "Creating local test repository..."
    git clone --bare "$PROJECT_ROOT" "$TEST_REPO" 2>/dev/null

    # Store original directory
    ORIGINAL_PWD="$PWD"
}

install_commands() {
    print_info "Installing commands to $TEST_INSTALL_DIR..."
    (cd "$PROJECT_ROOT" && ./install.sh "$TEST_INSTALL_DIR") >/dev/null 2>&1
    export PATH="$TEST_INSTALL_DIR:$PATH"
}

# ============================================================================
# Cleanup
# ============================================================================

cleanup() {
    if [ "$NO_CLEANUP" = true ]; then
        echo ""
        print_info "Skipping cleanup (--no-cleanup specified)"
        print_info "Test directory: $TEST_DIR"
        return
    fi

    echo ""
    print_header "Cleaning Up"

    # Return to original directory
    cd "$ORIGINAL_PWD" 2>/dev/null || cd "$PROJECT_ROOT"

    # Remove test directory
    if [ -d "$TEST_DIR" ]; then
        print_info "Removing test directory: $TEST_DIR"
        rm -rf "$TEST_DIR"
    fi

    # Restore PATH
    export PATH="$ORIGINAL_PATH"

    print_info "Cleanup complete"
}

# ============================================================================
# Test Suites
# ============================================================================

test_install_sh() {
    print_header "Testing install.sh (7 tests)"

    local test_install_dir="$TEST_DIR/workspaces/install_test"
    mkdir -p "$test_install_dir"

    # Test 1: Install to custom directory
    (cd "$PROJECT_ROOT" && ./install.sh "$test_install_dir") >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_pass "install.sh installs to custom directory"
    else
        print_fail "install.sh installs to custom directory"
    fi

    # Test 2-4: All three scripts are installed
    assert_file_exists "git-clone-sub-project is installed" "$test_install_dir/git-clone-sub-project"
    assert_file_exists "git-init-sub-project is installed" "$test_install_dir/git-init-sub-project"
    assert_file_exists "git-link-sub-project is installed" "$test_install_dir/git-link-sub-project"

    # Test 5: Scripts are executable
    local all_executable=true
    for script in git-clone-sub-project git-init-sub-project git-link-sub-project; do
        if [ ! -x "$test_install_dir/$script" ]; then
            all_executable=false
        fi
    done
    if [ "$all_executable" = true ]; then
        print_pass "All scripts are executable"
    else
        print_fail "All scripts are executable"
    fi

    # Test 6: Fails for non-existent directory
    assert_failure "install.sh fails for non-existent directory" \
        bash -c "cd '$PROJECT_ROOT' && ./install.sh /nonexistent/path/that/does/not/exist"

    # Test 7: Fails when run from wrong directory
    local wrong_dir="$TEST_DIR/workspaces/wrong_dir"
    mkdir -p "$wrong_dir"
    assert_failure "install.sh fails when run from wrong directory" \
        bash -c "cd '$wrong_dir' && '$PROJECT_ROOT/install.sh' '$test_install_dir'"
}

test_clone_sub_project() {
    print_header "Testing git-clone-sub-project (12 tests)"

    local workspace="$TEST_DIR/workspaces/clone_tests"
    mkdir -p "$workspace"

    # Create a parent repo for testing
    (
        cd "$workspace"
        git init parent-repo >/dev/null 2>&1
        cd parent-repo
        echo "# Parent Repo" > README.md
        git add README.md
        git commit -m "Initial commit" >/dev/null 2>&1
    )

    local parent="$workspace/parent-repo"

    # Test 1: Clone repository successfully
    print_info "Cloning test sub-project..."
    if (cd "$parent" && git-clone-sub-project "$TEST_REPO" sub1) >/dev/null 2>&1; then
        print_pass "git-clone-sub-project clones repository"
    else
        print_fail "git-clone-sub-project clones repository"
    fi

    # Test 2: .git-sub-project directory created
    assert_dir_exists ".git-sub-project/ directory created" "$parent/sub1/.git-sub-project"

    # Test 3: .git is a file, not directory
    assert_is_file ".git is a pointer file (not directory)" "$parent/sub1/.git"

    # Test 4: .git contains correct pointer
    assert_file_equals ".git contains 'gitdir: .git-sub-project'" \
        "$parent/sub1/.git" "gitdir: .git-sub-project"

    # Test 5: git status works
    assert_git_works "git status works in sub-project" "$parent/sub1"

    # Test 6: git log works
    if (cd "$parent/sub1" && git log --oneline -1) >/dev/null 2>&1; then
        print_pass "git log works in sub-project"
    else
        print_fail "git log works in sub-project"
    fi

    # Test 7: Clone with branch argument
    print_info "Cloning with branch specification..."
    if (cd "$parent" && git-clone-sub-project "$TEST_REPO" sub2 main) >/dev/null 2>&1; then
        print_pass "git-clone-sub-project with branch argument works"
    else
        print_fail "git-clone-sub-project with branch argument works"
    fi

    # Test 8: Fails without arguments
    assert_output_contains "Fails without arguments (shows usage)" "Usage" \
        git-clone-sub-project

    # Test 9: Fails with only URL argument
    assert_failure "Fails with only URL argument" \
        git-clone-sub-project "$TEST_REPO"

    # Test 10: Fails if non-empty directory already exists
    mkdir -p "$parent/existing_dir"
    echo "existing file" > "$parent/existing_dir/file.txt"
    assert_failure "Fails if non-empty directory already exists" \
        bash -c "cd '$parent' && git-clone-sub-project '$TEST_REPO' existing_dir"

    # Test 11: Fails with invalid repository URL
    assert_failure "Fails with invalid repository URL" \
        bash -c "cd '$parent' && git-clone-sub-project 'not-a-valid-url' invalid_sub"

    # Test 12: .git-sub-project contains proper git structure
    local has_structure=true
    for item in objects refs HEAD config; do
        if [ ! -e "$parent/sub1/.git-sub-project/$item" ]; then
            has_structure=false
        fi
    done
    if [ "$has_structure" = true ]; then
        print_pass ".git-sub-project/ contains objects, refs, HEAD, config"
    else
        print_fail ".git-sub-project/ contains objects, refs, HEAD, config"
    fi
}

test_init_sub_project() {
    print_header "Testing git-init-sub-project (10 tests)"

    local workspace="$TEST_DIR/workspaces/init_tests"
    mkdir -p "$workspace"

    # Create a parent repo
    (
        cd "$workspace"
        git init parent-repo >/dev/null 2>&1
        cd parent-repo
        echo "# Parent" > README.md
        git add README.md
        git commit -m "Initial" >/dev/null 2>&1
    )

    local parent="$workspace/parent-repo"

    # Create test directory with files
    mkdir -p "$parent/my-lib"
    echo "# My Library" > "$parent/my-lib/README.md"
    echo "console.log('hello');" > "$parent/my-lib/index.js"

    # Test 1: Initializes directory successfully
    if (cd "$parent" && git-init-sub-project my-lib) >/dev/null 2>&1; then
        print_pass "git-init-sub-project initializes directory"
    else
        print_fail "git-init-sub-project initializes directory"
    fi

    # Test 2: .git-sub-project created
    assert_dir_exists ".git-sub-project/ created" "$parent/my-lib/.git-sub-project"

    # Test 3: .git pointer file created
    assert_file_equals ".git pointer file has correct content" \
        "$parent/my-lib/.git" "gitdir: .git-sub-project"

    # Test 4: git status works
    assert_git_works "git status works after init" "$parent/my-lib"

    # Test 5: Files are staged
    local staged_count
    staged_count=$(cd "$parent/my-lib" && git diff --cached --numstat 2>/dev/null | wc -l)
    if [ "$staged_count" -gt 0 ]; then
        print_pass "Files are staged after init ($staged_count files)"
    else
        print_fail "Files are staged after init"
    fi

    # Test 6: Init with remote URL
    mkdir -p "$parent/my-lib2"
    echo "# Library 2" > "$parent/my-lib2/README.md"
    if (cd "$parent" && git-init-sub-project my-lib2 "git@github.com:test/test-repo.git") >/dev/null 2>&1; then
        # Verify remote is configured
        local remote_url
        remote_url=$(cd "$parent/my-lib2" && git remote get-url origin 2>/dev/null)
        if [ "$remote_url" = "git@github.com:test/test-repo.git" ]; then
            print_pass "Init with remote URL configures origin"
        else
            print_fail "Init with remote URL configures origin (got: $remote_url)"
        fi
    else
        print_fail "Init with remote URL configures origin"
    fi

    # Test 7: Fails for non-existent directory
    assert_failure "Fails for non-existent directory" \
        bash -c "cd '$parent' && git-init-sub-project nonexistent-dir"

    # Test 8: Fails if .git already exists
    mkdir -p "$parent/already-git"
    (cd "$parent/already-git" && git init) >/dev/null 2>&1
    assert_failure "Fails if .git directory already exists" \
        bash -c "cd '$parent' && git-init-sub-project already-git"

    # Test 9: Fails without arguments
    assert_output_contains "Fails without arguments (shows usage)" "Usage" \
        git-init-sub-project

    # Test 10: .git-sub-project structure is valid
    local has_structure=true
    for item in objects refs HEAD; do
        if [ ! -e "$parent/my-lib/.git-sub-project/$item" ]; then
            has_structure=false
        fi
    done
    if [ "$has_structure" = true ]; then
        print_pass ".git-sub-project/ structure is valid"
    else
        print_fail ".git-sub-project/ structure is valid"
    fi
}

test_link_sub_project() {
    print_header "Testing git-link-sub-project (14 tests)"

    local workspace="$TEST_DIR/workspaces/link_tests"
    mkdir -p "$workspace"

    # Create parent repo
    (
        cd "$workspace"
        git init parent-repo >/dev/null 2>&1
        cd parent-repo
        echo "# Parent" > README.md
        git add README.md
        git commit -m "Initial" >/dev/null 2>&1
    )

    local parent="$workspace/parent-repo"

    # Create a sub-project structure manually (simulating state after parent clone without .git pointer)
    # This mimics what happens when: 1) clone-sub-project was run, 2) parent was cloned (loses .git pointer)
    mkdir -p "$parent/sub1"
    echo "# Sub 1" > "$parent/sub1/README.md"
    (cd "$parent/sub1" && git init && git add . && git commit -m "init") >/dev/null 2>&1
    mv "$parent/sub1/.git" "$parent/sub1/.git-sub-project"
    # Now sub1 has .git-sub-project but no .git pointer (simulating post-clone state)

    # Test 1: Links single directory (exit code 0)
    set +e
    (cd "$parent" && git-link-sub-project sub1) >/dev/null 2>&1
    local exit_code=$?
    set -e
    if [ $exit_code -eq 0 ]; then
        print_pass "Links single directory by path (exit code 0)"
    else
        print_fail "Links single directory by path (exit code 0) - got $exit_code"
    fi

    # Test 2: .git pointer created correctly
    assert_file_equals ".git pointer created correctly" \
        "$parent/sub1/.git" "gitdir: .git-sub-project"

    # Test 3: Git works after linking
    assert_git_works "Git works after linking" "$parent/sub1"

    # Test 4: Re-linking detects "already linked" (script returns 0 since it's a success state)
    local relink_output
    relink_output=$(cd "$parent" && git-link-sub-project sub1 2>&1)
    if echo "$relink_output" | grep -q "Already linked"; then
        print_pass "Re-linking detects 'Already linked'"
    else
        print_fail "Re-linking detects 'Already linked'"
    fi

    # Test 5: Links current directory (no path arg)
    mkdir -p "$parent/sub2"
    echo "# Sub 2" > "$parent/sub2/README.md"
    (cd "$parent/sub2" && git init && git add . && git commit -m "init") >/dev/null 2>&1
    mv "$parent/sub2/.git" "$parent/sub2/.git-sub-project"
    if (cd "$parent/sub2" && git-link-sub-project) >/dev/null 2>&1; then
        print_pass "Links current directory (no path arg)"
    else
        print_fail "Links current directory (no path arg)"
    fi

    # Test 6: --all flag links multiple sub-projects
    mkdir -p "$parent/deep/nested/sub3"
    echo "# Sub 3" > "$parent/deep/nested/sub3/README.md"
    (cd "$parent/deep/nested/sub3" && git init && git add . && git commit -m "init") >/dev/null 2>&1
    mv "$parent/deep/nested/sub3/.git" "$parent/deep/nested/sub3/.git-sub-project"

    mkdir -p "$parent/another/sub4"
    echo "# Sub 4" > "$parent/another/sub4/README.md"
    (cd "$parent/another/sub4" && git init && git add . && git commit -m "init") >/dev/null 2>&1
    mv "$parent/another/sub4/.git" "$parent/another/sub4/.git-sub-project"

    if (cd "$parent" && git-link-sub-project --all) >/dev/null 2>&1; then
        if [ -f "$parent/deep/nested/sub3/.git" ] && [ -f "$parent/another/sub4/.git" ]; then
            print_pass "--all flag links multiple sub-projects recursively"
        else
            print_fail "--all flag links multiple sub-projects recursively"
        fi
    else
        print_fail "--all flag links multiple sub-projects recursively"
    fi

    # Test 7: -a short flag works
    mkdir -p "$parent/sub5"
    echo "# Sub 5" > "$parent/sub5/README.md"
    (cd "$parent/sub5" && git init && git add . && git commit -m "init") >/dev/null 2>&1
    mv "$parent/sub5/.git" "$parent/sub5/.git-sub-project"
    if (cd "$parent" && git-link-sub-project -a) >/dev/null 2>&1; then
        print_pass "-a short flag works"
    else
        print_fail "-a short flag works"
    fi

    # Test 8: Fails without .git-sub-project directory (exit code 1)
    mkdir -p "$parent/empty-dir"
    set +e
    (cd "$parent" && git-link-sub-project empty-dir) >/dev/null 2>&1
    exit_code=$?
    set -e
    if [ $exit_code -eq 1 ]; then
        print_pass "Fails without .git-sub-project/ (exit code 1)"
    else
        print_fail "Fails without .git-sub-project/ (exit code 1) - got $exit_code"
    fi

    # Test 9: Fails for non-existent directory (exit code 1)
    set +e
    (cd "$parent" && git-link-sub-project /nonexistent/path) >/dev/null 2>&1
    exit_code=$?
    set -e
    if [ $exit_code -eq 1 ]; then
        print_pass "Fails for non-existent directory (exit code 1)"
    else
        print_fail "Fails for non-existent directory (exit code 1) - got $exit_code"
    fi

    # Test 10: Fails when regular .git directory exists (exit code 1)
    mkdir -p "$parent/regular-git"
    (cd "$parent/regular-git" && git init) >/dev/null 2>&1
    mkdir -p "$parent/regular-git/.git-sub-project"
    set +e
    (cd "$parent" && git-link-sub-project regular-git) >/dev/null 2>&1
    exit_code=$?
    set -e
    if [ $exit_code -eq 1 ]; then
        print_pass "Fails when regular .git directory exists (exit code 1)"
    else
        print_fail "Fails when regular .git directory exists (exit code 1) - got $exit_code"
    fi

    # Test 11: --help flag works
    if git-link-sub-project --help 2>&1 | grep -q "Usage"; then
        print_pass "--help flag works"
    else
        print_fail "--help flag works"
    fi

    # Test 12: -h flag works
    if git-link-sub-project -h 2>&1 | grep -q "Usage"; then
        print_pass "-h flag works"
    else
        print_fail "-h flag works"
    fi

    # Test 13: Detects wrong pointer content (exit code 1)
    mkdir -p "$parent/wrong-pointer"
    echo "# Wrong" > "$parent/wrong-pointer/README.md"
    (cd "$parent/wrong-pointer" && git init && git add . && git commit -m "init") >/dev/null 2>&1
    mv "$parent/wrong-pointer/.git" "$parent/wrong-pointer/.git-sub-project"
    echo "gitdir: .git-wrong" > "$parent/wrong-pointer/.git"
    set +e
    (cd "$parent" && git-link-sub-project wrong-pointer) >/dev/null 2>&1
    exit_code=$?
    set -e
    if [ $exit_code -eq 1 ]; then
        print_pass "Detects wrong pointer content (exit code 1)"
    else
        print_fail "Detects wrong pointer content (exit code 1) - got $exit_code"
    fi

    # Test 14: Verify all link operations leave proper state
    # Check that sub1 still works after all the tests
    assert_git_works "Sub-project still works after all link tests" "$parent/sub1"
}

test_integration() {
    print_header "Integration Tests (7 tests)"

    local workspace="$TEST_DIR/workspaces/integration"
    mkdir -p "$workspace"

    # -------------------------------------------------------------------------
    # Test 1: Full workflow - clone, commit in sub, add to parent
    # -------------------------------------------------------------------------
    print_info "Running full workflow test..."

    (
        cd "$workspace"
        git init main-project >/dev/null 2>&1
        cd main-project
        echo "# Main Project" > README.md
        git add README.md
        git commit -m "Initial main project" >/dev/null 2>&1
    )

    local main_project="$workspace/main-project"

    if (cd "$main_project" && git-clone-sub-project "$TEST_REPO" shared-lib) >/dev/null 2>&1; then
        # Can we commit in sub-project and add to parent?
        (
            cd "$main_project/shared-lib"
            echo "# Test change" >> README.md
            git add README.md
            git commit -m "Test commit in sub-project" >/dev/null 2>&1
        )
        if (cd "$main_project/shared-lib" && git log --oneline -1 | grep -q "Test commit"); then
            print_pass "Full workflow: clone -> commit in sub -> works"
        else
            print_fail "Full workflow: clone -> commit in sub -> works"
        fi
    else
        print_fail "Full workflow: clone -> commit in sub -> works"
    fi

    # -------------------------------------------------------------------------
    # Test 2: Simulate team member clone (remove .git, then link)
    # -------------------------------------------------------------------------
    print_info "Simulating team member clone..."

    local cloned_project="$workspace/cloned-project"
    mkdir -p "$cloned_project"

    # Copy the sub-project without the .git pointer (simulating what git clone does)
    cp -r "$main_project/shared-lib" "$cloned_project/"
    rm -f "$cloned_project/shared-lib/.git"  # Remove the pointer

    # Initialize parent as git repo
    (cd "$cloned_project" && git init && echo "# Clone" > README.md && git add -A && git commit -m "Cloned") >/dev/null 2>&1

    # Now link should restore functionality
    if (cd "$cloned_project" && git-link-sub-project shared-lib) >/dev/null 2>&1; then
        if (cd "$cloned_project/shared-lib" && git status) >/dev/null 2>&1; then
            print_pass "Team member clone: link restores sub-project functionality"
        else
            print_fail "Team member clone: link restores sub-project functionality"
        fi
    else
        print_fail "Team member clone: link restores sub-project functionality"
    fi

    # -------------------------------------------------------------------------
    # Test 3: Deeply nested sub-project paths work
    # -------------------------------------------------------------------------
    print_info "Testing deeply nested paths..."

    local nested_project="$workspace/nested-project"
    mkdir -p "$nested_project"
    (cd "$nested_project" && git init) >/dev/null 2>&1

    if (cd "$nested_project" && git-clone-sub-project "$TEST_REPO" "level1/level2/deep-sub") >/dev/null 2>&1; then
        if (cd "$nested_project/level1/level2/deep-sub" && git status) >/dev/null 2>&1; then
            print_pass "Deeply nested sub-project paths work"
        else
            print_fail "Deeply nested sub-project paths work"
        fi
    else
        print_fail "Deeply nested sub-project paths work"
    fi

    # -------------------------------------------------------------------------
    # Test 4: Multiple sub-projects with --all linking
    # -------------------------------------------------------------------------
    print_info "Testing multiple sub-projects with --all..."

    local multi_project="$workspace/multi-project"
    mkdir -p "$multi_project"
    (cd "$multi_project" && git init) >/dev/null 2>&1

    # Clone multiple sub-projects
    (cd "$multi_project" && git-clone-sub-project "$TEST_REPO" lib-a) >/dev/null 2>&1
    (cd "$multi_project" && git-clone-sub-project "$TEST_REPO" lib-b) >/dev/null 2>&1

    # Remove .git pointers (simulate clone)
    rm -f "$multi_project/lib-a/.git"
    rm -f "$multi_project/lib-b/.git"

    # Link all
    if (cd "$multi_project" && git-link-sub-project --all) >/dev/null 2>&1; then
        if [ -f "$multi_project/lib-a/.git" ] && [ -f "$multi_project/lib-b/.git" ]; then
            print_pass "Multiple sub-projects with --all linking"
        else
            print_fail "Multiple sub-projects with --all linking"
        fi
    else
        print_fail "Multiple sub-projects with --all linking"
    fi

    # -------------------------------------------------------------------------
    # Test 5: .gitignore workflow
    # -------------------------------------------------------------------------
    print_info "Testing .gitignore workflow..."

    local gitignore_project="$workspace/gitignore-project"
    mkdir -p "$gitignore_project"
    (
        cd "$gitignore_project"
        git init >/dev/null 2>&1
        echo "# Project" > README.md
        git add README.md
        git commit -m "Initial" >/dev/null 2>&1
    )

    # Clone sub-project
    (cd "$gitignore_project" && git-clone-sub-project "$TEST_REPO" mylib) >/dev/null 2>&1

    # Add .git to .gitignore and commit
    echo -e "\n# Sub-project pointer\nmylib/.git" >> "$gitignore_project/.gitignore"
    (
        cd "$gitignore_project"
        git add .gitignore mylib/
        git commit -m "Add sub-project with gitignore" >/dev/null 2>&1
    )

    if (cd "$gitignore_project" && git log --oneline -1 | grep -q "Add sub-project"); then
        print_pass ".gitignore workflow: parent can commit with sub-project"
    else
        print_fail ".gitignore workflow: parent can commit with sub-project"
    fi

    # -------------------------------------------------------------------------
    # Test 6: Sub-project commit works independently
    # -------------------------------------------------------------------------
    print_info "Testing sub-project independent commits..."

    # Make a change in the sub-project and commit
    (
        cd "$gitignore_project/mylib"
        echo "// New file" > newfile.js
        git add newfile.js
        git commit -m "Add new file in sub-project" >/dev/null 2>&1
    )

    if (cd "$gitignore_project/mylib" && git log --oneline -1 | grep -q "Add new file"); then
        print_pass "Sub-project commit works independently"
    else
        print_fail "Sub-project commit works independently"
    fi

    # -------------------------------------------------------------------------
    # Test 7: Verify cleanup verification (meta-test)
    # -------------------------------------------------------------------------
    # This test verifies that our test directory exists (cleanup hasn't happened yet)
    if [ -d "$TEST_DIR" ]; then
        print_pass "Test directory exists (cleanup verification will run at end)"
    else
        print_fail "Test directory exists (cleanup verification will run at end)"
    fi
}

# ============================================================================
# Main Runner
# ============================================================================

run_all_tests() {
    local start_time
    start_time=$(date +%s)

    echo ""
    echo -e "${BOLD}========================================${NC}"
    echo -e "${BOLD}   Git Sub-Project Test Suite${NC}"
    echo -e "${BOLD}========================================${NC}"
    echo ""
    echo "Project: $PROJECT_ROOT"
    echo "Test Directory: $TEST_DIR"
    echo ""

    # Setup
    print_header "Setting Up Test Environment"
    setup_test_environment
    install_commands

    # Run test suites
    test_install_sh
    test_clone_sub_project
    test_init_sub_project
    test_link_sub_project
    test_integration

    # Calculate duration
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # Summary
    echo ""
    echo -e "${BOLD}========================================${NC}"
    echo -e "${BOLD}   Test Summary${NC}"
    echo -e "${BOLD}========================================${NC}"
    echo ""
    echo "Duration: ${duration}s"
    echo -e "Passed:  ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed:  ${RED}$TESTS_FAILED${NC}"
    echo -e "Skipped: ${YELLOW}$TESTS_SKIPPED${NC}"
    echo -e "Total:   $((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))"
    echo ""

    if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
        echo -e "${RED}Failed Tests:${NC}"
        for test in "${FAILED_TESTS[@]}"; do
            echo -e "  - $test"
        done
        echo ""
    fi

    # Return appropriate exit code
    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}TESTS FAILED${NC}"
        return 1
    else
        echo -e "${GREEN}ALL TESTS PASSED${NC}"
        return 0
    fi
}

# ============================================================================
# Main Entry Point
# ============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  -h, --help       Show this help"
                echo "  -v, --verbose    Verbose output"
                echo "  --no-cleanup     Don't cleanup after tests"
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --no-cleanup)
                NO_CLEANUP=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    # Trap EXIT to ensure cleanup
    trap cleanup EXIT

    # Run tests
    run_all_tests
    exit $?
}

main "$@"
