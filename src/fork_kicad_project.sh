#!/usr/bin/env bash
set -euo pipefail

# Version
VERSION="0.7.0"

# fork_kicad_project.sh
# Copy a KiCad project folder, exclude junk, and rename main files to a new basename.
# Usage:
#   ./fork_kicad_project.sh <source_project_dir> <new_project_basename> [<destination_parent_dir>] [flags]
#
# Flags:
#   -T 'tagline text'   Set custom tagline under project name
#   -S 'short desc'     Set custom short description under tagline
#   -D                  Keep About section (don't reset)
#   -R                  Keep Roadmap section (don't clear)
#   -I                  Keep instructions (don't remove Getting Started, etc.)
#   -A                  Copy archive folders (normally excluded)
#   -P                  Keep production files (don't sanitize jlcpcb/)
#   -M                  Keep images (don't reset images/ folder)
#   -W                  Keep original tagline/shortdesc from source
#   -K                  Keep ALL (= -P -M -D -R -I -W combined)
#
# Examples:
#   # Create sibling folder next to source:
#   ./fork_kicad_project.sh ./esp32_wroom esp32_s3_wroom
#
#   # Put the new project elsewhere:
#   ./fork_kicad_project.sh ~/hw/esp32_wroom esp32_s3_wroom ~/hw/forks
#
# Notes:
# - Handles absolute or relative paths.
# - Excludes typical junk: locks, autosaves, VCS metadata, temp files, etc.
# - Renames ALL files and directories containing the old basename.
#   (Hierarchical sheets keep their filenames; change those later if you want.)
# - Creates <new>-backups/ empty folder in the new project.

echo "== dpx project forker v$VERSION =="


# Parse positional args and flags
SRC_DIR=""
NEW_BASE=""
DEST_PARENT=""
TAGLINE="sassy tagline goes here"
SHORTDESC="short description goes here to tease interest"
CHANGE_ABOUT=1
KEEP_ROADMAP=0
KEEP_INSTRUCTIONS=0
COPY_ARCHIVES=0
KEEP_PRODUCTION=0
KEEP_IMAGES=0
KEEP_TAGLINE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--version)
      echo "fork_kicad_project.sh v$VERSION"; exit 0;;
    -T)
      TAGLINE="$2"; shift 2;;
    -S)
      SHORTDESC="$2"; shift 2;;
    -D)
      CHANGE_ABOUT=0; shift;;
    -R)
      KEEP_ROADMAP=1; shift;;
    -I)
      KEEP_INSTRUCTIONS=1; shift;;
    -A)
      COPY_ARCHIVES=1; shift;;
    -P)
      KEEP_PRODUCTION=1; shift;;
    -M)
      KEEP_IMAGES=1; shift;;
    -W)
      KEEP_TAGLINE=1; shift;;
    -K)
      KEEP_PRODUCTION=1; KEEP_IMAGES=1; CHANGE_ABOUT=0; KEEP_ROADMAP=1; KEEP_INSTRUCTIONS=1; KEEP_TAGLINE=1; shift;;
    *)
      if [[ -z "$SRC_DIR" ]]; then SRC_DIR="$1";
      elif [[ -z "$NEW_BASE" ]]; then NEW_BASE="$1";
      elif [[ -z "$DEST_PARENT" ]]; then DEST_PARENT="$1";
      fi
      shift;;
  esac
done

# Strip leading/trailing slashes, dots, and spaces from NEW_BASE
NEW_BASE="${NEW_BASE#/}"
NEW_BASE="${NEW_BASE%/}"
NEW_BASE="${NEW_BASE#.}"
NEW_BASE="${NEW_BASE%.}"
NEW_BASE="${NEW_BASE// /}"

if [[ -z "$SRC_DIR" || -z "$NEW_BASE" ]]; then
  echo "Usage: $0 <source_project_dir> <new_project_basename> [<destination_parent_dir>] [flags]"
  echo ""
  echo "Flags:"
  echo "  -T 'tagline text'   Set custom tagline (default: placeholder text)"
  echo "  -S 'short desc'     Set custom short description (default: placeholder text)"
  echo "  -D                  Keep About section (don't reset)"
  echo "  -R                  Keep Roadmap section (don't clear)"
  echo "  -I                  Keep instructions (don't remove Getting Started, etc.)"
  echo "  -A                  Copy archive folders (normally excluded)"
  echo "  -P                  Keep production files (don't sanitize jlcpcb/)"
  echo "  -M                  Keep images (don't reset images/ folder)"
  echo "  -W                  Keep original tagline/shortdesc from source README"
  echo "  -K                  Keep ALL (= -D -R -I -P -M -W combined)"
  echo ""
  echo "Examples:"
  echo "  $0 ./esp32_wroom esp32_s3_wroom"
  echo "  $0 ./esp32_wroom esp32_s3_wroom ~/hw/forks"
  echo "  $0 ./my_project new_project -T 'blazing fast' -S 'improved version'"
  echo "  $0 ./my_project clean_project -D -R -I"
  exit 1
fi

# Resolve paths
if ! command -v realpath >/dev/null 2>&1; then
  # Fallback if realpath is missing (macOS default)
  realpath() { python3 - <<'PY'
import os, sys
print(os.path.abspath(sys.argv[1]))
PY
  }
fi

SRC_DIR_ABS="$(realpath "$SRC_DIR")"
if [[ -z "$DEST_PARENT" ]]; then
  DEST_PARENT_ABS="$(dirname "$SRC_DIR_ABS")"
else
  DEST_PARENT_ABS="$(realpath "$DEST_PARENT")"
fi

DEST_DIR_ABS="$DEST_PARENT_ABS/$(echo "$NEW_BASE" | tr '[:lower:]' '[:upper:]')"

echo "-- Source:      $SRC_DIR_ABS"
echo "-- New basename: $NEW_BASE"
echo "-- Destination: $DEST_DIR_ABS"
echo

# Basic checks
if [[ ! -d "$SRC_DIR_ABS" ]]; then
  echo "ERROR: Source directory does not exist."
  exit 2
fi
if [[ -e "$DEST_DIR_ABS" ]]; then
  echo "ERROR: Destination already exists: $DEST_DIR_ABS"
  exit 3
fi

# Find the old project basename - always use the folder name
echo ">> Detecting project files in source..."
OLD_BASE="$(basename "$SRC_DIR_ABS")"
echo "   Using folder name as project basename: $OLD_BASE"

# Convert to lowercase for file matching (files are typically lowercase)
OLD_BASE_LC="$(echo "$OLD_BASE" | tr '[:upper:]' '[:lower:]')"
echo "   Looking for files containing: $OLD_BASE_LC"

# Check for .kicad_pro files (for informational purposes only)
PRO_FILES=()
while IFS= read -r -d '' file; do
  PRO_FILES+=("$file")
done < <(find "$SRC_DIR_ABS" -name "*.kicad_pro" -print0 2>/dev/null)

if [[ ${#PRO_FILES[@]} -gt 0 ]]; then
  echo "   Found ${#PRO_FILES[@]} .kicad_pro file(s) (will be renamed with folder)"
fi

echo
echo ">> Copying project folder (excluding junk)..."

# Prefer rsync for selective copy
if command -v rsync >/dev/null 2>&1; then
  RSYNC_EXCLUDES=(
    # VCS metadata
    --exclude '.git/'
    --exclude '.svn/'
    --exclude '.hg/'
    # IDE/editor
    --exclude '.idea/'
    --exclude '.vscode/'
    # Build artifacts (code projects)
    --exclude 'build/'
    --exclude 'dist/'
    --exclude 'node_modules/'
    --exclude '.cache/'
    --exclude '*.o'
    --exclude '*.pyc'
    --exclude '__pycache__/'
    --exclude '.pio/'
    --exclude '.pioenvs/'
    # Temp/backup files
    --exclude '*.lock'
    --exclude '*-backups/'
    --exclude '*.kicad_sch-bak'
    --exclude '*~'
    --exclude '~*'
    --exclude '_*'
    --exclude '#*'
    --exclude '*_old'
    --exclude '*_old.*'
    --exclude '*.tmp'
    --exclude '*.bak'
    --exclude '*.autosave*'
  )
  
  # Exclude archive folders unless -A flag is used
  if [[ $COPY_ARCHIVES -eq 0 ]]; then
    RSYNC_EXCLUDES+=(--exclude '**/archive/' --exclude '**/archives/')
    echo "   Excluding archive folders (use -A to include)"
  fi
  
  rsync -av "${RSYNC_EXCLUDES[@]}" "$SRC_DIR_ABS"/ "$DEST_DIR_ABS"/
else
  echo "   rsync not found, using cp -R (less selective)."
  mkdir -p "$DEST_DIR_ABS"
  cp -R "$SRC_DIR_ABS"/. "$DEST_DIR_ABS"/
  echo "   Removing known junk from copy..."
  # VCS and IDE
  rm -rf "$DEST_DIR_ABS/.git" "$DEST_DIR_ABS/.svn" "$DEST_DIR_ABS/.hg" \
         "$DEST_DIR_ABS/.idea" "$DEST_DIR_ABS/.vscode" 2>/dev/null || true
  # Build artifacts
  rm -rf "$DEST_DIR_ABS/__pycache__" "$DEST_DIR_ABS/build" "$DEST_DIR_ABS/dist" \
         "$DEST_DIR_ABS/node_modules" "$DEST_DIR_ABS/.cache" \
         "$DEST_DIR_ABS/.pio" "$DEST_DIR_ABS/.pioenvs" 2>/dev/null || true
  find "$DEST_DIR_ABS" -name '*.o' -delete 2>/dev/null || true
  find "$DEST_DIR_ABS" -name '*.pyc' -delete 2>/dev/null || true
  # Temp/backup files
  find "$DEST_DIR_ABS" -name '*.lock' -delete 2>/dev/null || true
  find "$DEST_DIR_ABS" -name '*.kicad_sch-bak' -delete 2>/dev/null || true
  find "$DEST_DIR_ABS" -name '*~' -delete 2>/dev/null || true
  find "$DEST_DIR_ABS" -name '~*' -delete 2>/dev/null || true
  find "$DEST_DIR_ABS" -name '_*' -delete 2>/dev/null || true
  find "$DEST_DIR_ABS" -name '#*' -delete 2>/dev/null || true
  find "$DEST_DIR_ABS" -name '*_old' -delete 2>/dev/null || true
  find "$DEST_DIR_ABS" -name '*_old.*' -delete 2>/dev/null || true
  find "$DEST_DIR_ABS" -name '*.tmp' -delete 2>/dev/null || true
  find "$DEST_DIR_ABS" -name '*.bak' -delete 2>/dev/null || true
  find "$DEST_DIR_ABS" -name '*-backups' -type d -prune -exec rm -rf {} + 2>/dev/null || true
  
  # Remove archive folders unless -A flag is used
  if [[ $COPY_ARCHIVES -eq 0 ]]; then
    find "$DEST_DIR_ABS" -type d -name "archive" -exec rm -rf {} + 2>/dev/null || true
    find "$DEST_DIR_ABS" -type d -name "archives" -exec rm -rf {} + 2>/dev/null || true
    echo "   Removed archive folders (use -A to include)"
  fi
fi

echo
echo ">> Renaming ALL files and directories containing old basename..."

# Add dpx_ prefix to filenames if not already present - use lowercase for files
FILE_BASE_LC="$(echo "$NEW_BASE" | tr '[:upper:]' '[:lower:]')"
if [[ ! "$FILE_BASE_LC" =~ ^dpx[-_] ]]; then
  FILE_BASE="dpx_$FILE_BASE_LC"
  echo "   Adding dpx_ prefix to filenames: $FILE_BASE"
else
  FILE_BASE="$FILE_BASE_LC"
fi

# Lowercase old project name for matching
OLD_BASE_LC="$(echo "$OLD_BASE" | tr '[:upper:]' '[:lower:]')"

# Lowercase new project name for README replacement
NEW_BASE_LC="$(echo "$NEW_BASE" | tr '[:upper:]' '[:lower:]')"

# Function to rename all files and directories containing the old basename
rename_all_occurrences () {
  local found_count=0

  # First, rename directories (bottom-up to avoid path issues)
  echo "   Renaming directories..."
  while IFS= read -r -d '' dir_path; do
    if [[ -z "$dir_path" ]]; then continue; fi
    local parent_dir="$(dirname "$dir_path")"
    local old_name="$(basename "$dir_path")"

    # Skip archive folders - never rename them
    if [[ "$old_name" == "archive" || "$old_name" == "archives" ]]; then
      echo "     Skipping archive folder: $old_name"
      continue
    fi

    # Case-insensitive replacement using sed with | delimiter to avoid / conflicts
    local new_name=$(echo "$old_name" | sed "s|$OLD_BASE_LC|$FILE_BASE|gi")

    if [[ -n "$old_name" && -n "$new_name" && "$old_name" != "$new_name" ]]; then
      echo "     $old_name -> $new_name"
      mv "$dir_path" "$parent_dir/$new_name"
      ((found_count++))
    fi
  done < <(find "$DEST_DIR_ABS" -type d \( -iname "*$OLD_BASE_LC*" \) -print0 2>/dev/null | sort -z -r)

  # Then rename files
  echo "   Renaming files..."
  while IFS= read -r -d '' file_path; do
    if [[ -z "$file_path" ]]; then continue; fi
    local parent_dir="$(dirname "$file_path")"
    local old_name="$(basename "$file_path")"

    # Skip files in archive folders - never rename them
    if [[ "$file_path" == */archive/* || "$file_path" == */archives/* ]]; then
      echo "     Skipping file in archive folder: $old_name"
      continue
    fi

    # Case-insensitive replacement using sed with | delimiter to avoid / conflicts
    local new_name=$(echo "$old_name" | sed "s|$OLD_BASE_LC|$FILE_BASE|gi")

    if [[ -n "$old_name" && -n "$new_name" && "$old_name" != "$new_name" ]]; then
      echo "     $old_name -> $new_name"
      mv "$file_path" "$parent_dir/$new_name"
      ((found_count++))
    fi
  done < <(find "$DEST_DIR_ABS" -type f \( -iname "*$OLD_BASE_LC*" \) -print0 2>/dev/null)

  if [[ $found_count -eq 0 ]]; then
    echo "   (skip) No files or directories containing '$OLD_BASE_LC' found"
  else
    echo "   Renamed $found_count items"
  fi
}

rename_all_occurrences

echo
echo ">> Creating backups folder..."
mkdir -p "$DEST_DIR_ABS/${FILE_BASE}-backups"
echo "   Created: $DEST_DIR_ABS/${FILE_BASE}-backups"

echo
echo ">> Verifying common library assets..."
# This section doesn't change anything—just reports what's present so you know it copied.
declare -a LIB_HINTS=(
  "*.kicad_sym"
  "*.lib"
  "*.dcm"
  "*.kicad_footprint"
  "*.kicad_prl"
)
declare -a DIR_HINTS=(
  "*.pretty"
  "3d"
  "3D"
  "models"
  "library"
  "libs"
)

FOUND_ANY=0
for pat in "${LIB_HINTS[@]}"; do
  if compgen -G "$DEST_DIR_ABS/$pat" >/dev/null; then
    echo "   Found files matching: $pat"
    FOUND_ANY=1
  fi
done
for d in "${DIR_HINTS[@]}"; do
  if compgen -G "$DEST_DIR_ABS/$d" >/dev/null; then
    echo "   Found directory: $d"
    FOUND_ANY=1
  fi
done
if [[ $FOUND_ANY -eq 0 ]]; then
  echo "   No obvious local libraries detected (that's fine if you use global libs)."
fi

# === PRODUCTION SANITIZE (skipped with -P flag) ===
if [[ $KEEP_PRODUCTION -eq 0 ]]; then
  echo
  echo ">> Sanitizing production files..."
  # Find and empty jlcpcb folders (contents only, keep folder structure)
  while IFS= read -r -d '' jlcpcb_dir; do
    if [[ -d "$jlcpcb_dir" ]]; then
      echo "   Emptying: $jlcpcb_dir"
      rm -rf "$jlcpcb_dir"/*
    fi
  done < <(find "$DEST_DIR_ABS/hardware/src" -type d -name "jlcpcb" -print0 2>/dev/null)
  echo "   Production files sanitized."
fi

# === IMAGES RESET (skipped with -M flag) ===
if [[ $KEEP_IMAGES -eq 0 ]]; then
  echo
  echo ">> Resetting images and cleaning project assets..."
  
  # Part A: Clean stray image files from KiCad src folder
  echo "   Cleaning stray files from hardware/src/.../"
  while IFS= read -r -d '' src_dir; do
    # Only delete files at top level of src project folder, not in subdirs
    find "$src_dir" -maxdepth 1 -type f \( \
      -iname "*.svg" -o -iname "*.png" -o -iname "*.step" -o \
      -iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o \
      -iname "*.bmp" -o -iname "*.ai" \
    \) -print0 | while IFS= read -r -d '' stray_file; do
      echo "     Removing: $(basename "$stray_file")"
      rm -f "$stray_file"
    done
  done < <(find "$DEST_DIR_ABS/hardware/src" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
  
  # Part A2: Clean .step files from hardware/3d/ folder
  echo "   Cleaning .step files from hardware/3d/..."
  find "$DEST_DIR_ABS/hardware/3d" -type f -iname "*.step" -print0 2>/dev/null | while IFS= read -r -d '' step_file; do
    echo "     Removing: $(basename "$step_file")"
    rm -f "$step_file"
  done
  
  # Part B: Reset images/ folder from template
  echo "   Resetting images/ folder from template..."
  
  # Find the template images directory (same logic as dpx_newProject.sh)
  TEMPLATE_IMAGES_DIR=""
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  current_search="$SCRIPT_DIR"
  while [[ "$current_search" != "/" ]]; do
    if [[ "$(basename "$current_search")" == *"CIRCUIT_PROJECTS"* ]]; then
      if [[ -d "$current_search/_....DPX_BLANK_PROJECT_TEMPLATE/dpx_readme_template/images" ]]; then
        TEMPLATE_IMAGES_DIR="$current_search/_....DPX_BLANK_PROJECT_TEMPLATE/dpx_readme_template/images"
        break
      fi
    fi
    current_search="$(dirname "$current_search")"
  done
  
  if [[ -n "$TEMPLATE_IMAGES_DIR" && -d "$TEMPLATE_IMAGES_DIR" ]]; then
    # Delete existing images and copy fresh from template
    rm -rf "$DEST_DIR_ABS/images"/*
    cp -R "$TEMPLATE_IMAGES_DIR"/* "$DEST_DIR_ABS/images"/
    echo "   Images reset from: $TEMPLATE_IMAGES_DIR"
  else
    echo "   WARNING: Could not find template images directory, skipping reset."
  fi
  
  echo "   Images reset complete."
fi


# === README SANITIZATION ===
README_PATH="$DEST_DIR_ABS/README.md"
if [[ -f "$README_PATH" ]]; then
  echo
  echo ">> Sanitizing README.md..."
  
  # Debug output
  echo "   DEBUG: OLD_BASE='$OLD_BASE'"
  echo "   DEBUG: NEW_BASE='$NEW_BASE'"
  echo "   DEBUG: NEW_BASE_LC='$NEW_BASE_LC'"
  
  # 1. Replace all instances of old project name with new (lowercase) - simple approach like dpx_newProject.sh
  echo "   Replacing '$OLD_BASE' with '$NEW_BASE_LC' (lowercase)"
  sed -i '' "s|$OLD_BASE|$NEW_BASE_LC|gi" "$README_PATH"

  # 2a. Tagline under project name (h3 under h1) - skipped with -W
  if [[ $KEEP_TAGLINE -eq 0 ]]; then
    sed -i '' "0,/^<h3.*>.*<\/h3>/s//<h3 align=\"center\"><i>$TAGLINE<\/i><\/h3>/" "$README_PATH"
  fi

  # 2b. Short description (first <p align="center"> block) - skipped with -W
  if [[ $KEEP_TAGLINE -eq 0 ]]; then
    sed -i '' "0,/^  <p align=\"center\">.*$/s//  <p align=\"center\">\n    $SHORTDESC/" "$README_PATH"
  fi

  # 2c. About section
  if [[ $CHANGE_ABOUT -eq 1 ]]; then
    TODAY="$(date '+%Y-%m-%d')"
    sed -i '' "0,/^fork.*$/s||forked from project '$OLD_BASE' on $TODAY|" "$README_PATH"
  fi


  # 2d. Clear roadmap contents unless -R (leave header, insert '[ ] -')
  if [[ $KEEP_ROADMAP -eq 0 ]]; then
    awk 'BEGIN{roadmap=0} /^## Roadmap/{print;print "\n- [ ] -\n";roadmap=1;next} /^## /{roadmap=0} {if(!roadmap)print}' "$README_PATH" > "$README_PATH.tmp" && mv "$README_PATH.tmp" "$README_PATH"
  fi

  # 2e. Clear instructions (skipped with -I)
  if [[ $KEEP_INSTRUCTIONS -eq 0 ]]; then
    awk 'BEGIN{gs=0;inst=0} /^## Getting Started/{print;print "\n*\n";gs=1;next} /^## Installation/{print;print "\n*\n";inst=1;next} /^## Usage/{print;print "\n*\n";inst=1;next} /^## /{gs=0;inst=0} {if(!gs&&!inst)print}' "$README_PATH" > "$README_PATH.tmp" && mv "$README_PATH.tmp" "$README_PATH"
  fi

  echo "   README.md sanitized."
fi

echo
echo "== Done =="
echo "New project: $DEST_DIR_ABS"
