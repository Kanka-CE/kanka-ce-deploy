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

#GIT='https://github.com/owlchester/kanka.git'
GIT='https://github.com/kanka-ce/kanka-community-edition.git'

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

# Tools directory
TOOLS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"



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
        echo "Usage: $0 [options] --kanka-dir=</Path/to/kanka>"
        echo "  -h,           --help      Print this message"
        echo "  -m            --branch    Branch name of docker-kanka-ce that shall be used (default: main)"
        echo "  -t            --target    Target Kanka version that shall be used as base (default: latest)"
        echo "  -b            --build     build folder"
        echo "  -i            --icons     Select which icon set to use, options <fontawesome-free|fontawesome-nonfree|lineawesome>, defaults to fontawesome-free"
        exit 0
      ;;

      # BRANCH NAME
      -m|--branch)
        BRANCH_NAME="$2"
        shift
        shift
        ;;

      # TARGET VERSION
      -t|--target)
        TARGET_VERSION="$2"
        shift
        shift
        ;;

      # BUILD DIRECTORY
      -b|--build)
        BUILD_DIR="$2"
        shift
        shift
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

  # -- BRANCH NAME --
  cecho ${INFO} "Branch Name:"
  if [ -z "${BRANCH_NAME}" ]; then
    BRANCH_NAME="main"
    echo "  No branch name provided. Use the default branch name:"
    echo "  ${BRANCH_NAME}"
    echo "  If you want to specify another version"
    echo "  use the -m <BRANCH_NAME> or --branch <BRANCH_NAME> option."
  else 
    echo "  ${BRANCH_NAME}"
  fi

  # -- TARGET VERSION --
  cecho ${INFO} "Target Version:"
  if [ -z "${TARGET_VERSION}" ]; then
    TARGET_VERSION="latest"
    echo "  No target version provided. Use the default target version:"
    echo "  ${TARGET_VERSION}"
    echo "  If you want to specify another version"
    echo "  use the -t <VERSION> or --target <VERSION> option."
  else 
    echo "  ${TARGET_VERSION}"
  fi

  # -- BUILD DIRECTORY --
  # If user provided build_dir is not set, use default build_dir
  cecho ${INFO} "Build folder:"
  if [ -z "${BUILD_DIR}" ]; then
    BUILD_DIR="${TOOLS_ROOT}/build"
    echo "  No build directory was provided. Use the default build folder:"
    echo "  ${BUILD_DIR}"
    echo "  If you want to specify another path, provide a build directory"
    echo "  use the -b <DIR> or --build <DIR> option."
  else 
    # Check the input argument of the install path and (if used) replace the tilde
    # character '~' by the users home directory ${HOME}. 
    BUILD_DIR=${BUILD_DIR/#~\//$HOME\/}
    echo "  ${BUILD_DIR}"
  fi

  # --- ICON SET ---
  # If user-provided icons is not set, use default 
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

# --- Verify that the script is called from the kanka root directory ---
if [ "$(pwd)" != "${TOOLS_ROOT}" ]; then
  error "This script has to be called from the kanka-ce-tools root directory." $E_USAGE
fi


# -- Parse arguments ---
if ! parse_arguments "$@"; then
  exit 0
fi

cecho ${INFO} "Downloading..."

# Check if git is installed
if ! command -v git &>/dev/null; then
  cecho ${INFO} "Please install git to proceed:"
  cecho ${INFO} "- Debian/Ubuntu: sudo apt install git"
  cecho ${INFO} "- Red Hat/Fedora: sudo dnf install git"
  error "'git' is not available on this system." 7
fi

# Download the Dockerfile
cecho ${INFO} "Download Dockerfile"
git clone \
  --branch "${BRANCH_NAME}" \
  --single-branch \
  https://github.com/kanka-ce/docker-kanka-ce.git \
  "${BUILD_DIR}"

# -- Build Container --
cd ${BUILD_DIR}
if command -v podman &>/dev/null; then
  podman build -t kanka-ce:${TARGET_VERSION} -f Dockerfile
elif command -v docker &>/dev/null; then
  docker build -t kanka-ce:${TARGET_VERSION} -f Dockerfile
else
  cecho ${INFO} "Please install either podman or docker to proceed:"
  cecho ${INFO} "- Debian/Ubuntu: sudo apt install podman  # or docker"
  cecho ${INFO} "- Red Hat/Fedora: sudo dnf install podman  # or docker"
  error "Neither 'podman' nor 'docker' is available on this system." 7
fi  

# Note that the publishing of the container is done via a GitHub action.

echo
cecho ${GOOD} "All Done!"
