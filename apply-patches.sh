#!/usr/bin/env bash

# ---------------------------------------------------------------------
#
# Copyright (C) 2026 @Sebastian Kinnewig
#
# This file is part of the Kanka CE toolchain.
# It is NOT part of the official Kanka project and is not affiliated
# with or endorsed by the Kanka developers.
#
# The code in this file is licensed under the GNU Lesser General
# Public License v2.1 (LGPL-2.1) as published by the Free Software
# Foundation.
#
# The full text of the license can be found in the file LICENSE.md.
#
# ---------------------------------------------------------------------


# ++============================================================++
# ||                         Premilaris                         ||
# ++============================================================++
set -e

# Colours for progress and error reporting
ERROR="\033[1;31m"
GOOD="\033[1;32m"
WARN="\033[1;35m"
INFO="\033[1;34m"
BOLD="\033[1m"

# Display messages in a specified colour
cecho() {
  COL=$1; shift
  echo -e "${COL}$@\033[0m"
}

# Error codes
E_OK=0
E_USAGE=1
E_UPSTREAM_NOT_FOUND=2
E_OUTPUT_WRITE_FAIL=3
E_PATCH_FAILED=4
E_RESOURCE_FAILED=5
E_STEP_FAILED=6
E_DEPENDENCY_MISSING=7

# Error handling
error() {
    local message="$1"
    local code="${2:-1}"

    cecho ${ERROR} "ERROR: $message" >&2
    exit "$code"
}

patch_name_to_commit_message() {
    local s="$1"

    # Remove path prefix 
    s=${s#"$TOOLS_ROOT/patches/patch-files/"}

    # Remove .patch
    s=${s%.patch}

    s=$(printf '%s\n' "$s" \
        | sed 's/^[0-9]\+-//' \
        | tr '-' ' ')

    echo "${s^}"
}

# ++============================================================++
# ||                       Parse arguments                      ||
# ++============================================================++
parse_arguments() {
  # Parse command line arguments
  while [[ $# -gt 0 ]]; do
    KEY="$1"
    case $KEY in
      # Help
      -h|--help)
        echo "Kanka CE Tools, Version $(cat VERSION)"
        echo "Usage: $0 [options]"
        echo "  -h,           --help      Print this message"
        echo "  -i            --icons     Select which icon set to use, options <fontawesome-free|fontawesome-nonfree|lineawesome>, defaults to fontawesome-free"
        exit 0
      ;;

      # ICON SET
      -i|--icons)
        ICONS="$2"
        shift
        shift
        ;;

      # unknown flag
      *)
        error "Invalid command line option <$KEY>. See -h for more information." $E_USAGE
        ;;
    esac
  done

  # --- ICON SET ---
  # If user provided icons is not set, use default
  cecho ${INFO} "Icons to use:"
  if [ -z "${ICONS}" ]; then
    ICONS="fontawesome-free"
    echo "  No icon-set selected, default to fontawesome-free."
    echo "  To use different icons use the -i <ICONS-NAME> or --icons <ICONS-NAME> option."
    echo "  The available options are: fontawesome-free, fontawesome-nonfree and lineawesome."
  fi
}



# ++============================================================++
# ||                    The actual program                      ||
# ++============================================================++

# Tools directory
TOOLS_ROOT=ce-tools

# -- Parse arguments ---
if ! parse_arguments "$@"; then
  exit 0
fi

# -- Clean up --
cecho ${INFO} "Delete unused files:"
git rm -rf    \
    .agents   \
    .codex    \
    .claude   \
    .github   \
    .opencode \
    .mariadb  \
    .nginx    \
    docker    \
    docs      \
    public/vendor/fontawesome
git rm -f \
    .editorconfig      \
    .env.example       \
    .env.testing       \
    .gitattributes     \
    .gitignore         \
    .jshintrc          \
    AGENTS.md          \
    boost.json         \
    CLAUDE.md          \
    docker-compose.yml
git commit -m "Delete unused files."

# -- update gitignore --
cat << EOF >> .gitignore

# --- Kanka-CE ignores ---
# Kanka-CE-Tools
# During patching the the tools are downloaded
# into the source folder, let git ignore them:
${TOOLS_ROOT}
EOF
git add .gitignore
git commit -m "Update gitignore."

# -- Add new files --
cp $TOOLS_ROOT/resources/docs/* .
git add .
git commit -m "Upload Kanka-CE docs."

# -- Add workflows --
mkdir -p .github/workflows
cp $TOOLS_ROOT/resources/workflows/* .github/workflows
git add .github/workflows
git commit -m "Upload workflows."

# -- Replace font --
cecho ${INFO} "Replace Icons"
if ! bash "$TOOLS_ROOT/patches/icons/replace-fontawesome.sh" "$TOOLS_ROOT" "." "$ICONS" "$@"; then
  error "Icon replacement failed" 4
fi
git add .
git commit -m "Replace icons."
cecho ${GOOD} "Done!"

# -- Apply Patches --
cecho ${INFO} "Apply patches"
for file in $TOOLS_ROOT/patches/patch-files/*.patch; do
    echo "  Apply: $file"
    patch -p1 < "$file" || {
        error "Patch $file failed" 4
    }
    git add .
    commit_message=$(patch_name_to_commit_message "$file")
    git commit -m "$commit_message."
done
cecho ${GOOD} "Done!"


