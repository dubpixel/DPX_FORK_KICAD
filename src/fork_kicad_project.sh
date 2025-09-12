#!/usr/bin/env bash
set -euo pipefail

# fork_kicad_project.sh
# Copy a KiCad project folder, exclude junk, and rename main files to a new basename.
# Usage:
#   ./fork_kicad_project.sh <source_project_dir> <new_project_basename> [<destination_parent_dir>] [flags]
#
# Flags:
#   -T 'tagline text'   Set custom tagline under project name
#   -S 'short desc'     Set custom short description under tagline
#   -D                  Do not change About section
#   -R                  Do Not Change Roadmap section
#   -I                  Remove instructions (Getting Started, Installation, Usage)
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

echo "== KiCad Project Forker v0.5 =="


# Parse positional args and flags
SRC_DIR=""
NEW_BASE=""
DEST_PARENT=""
TAGLINE="sassy tagline goes here"
SHORTDESC="short description goes here to tease interest"
CHANGE_ABOUT=1
KEEP_ROADMAP=0
REMOVE_INSTRUCTIONS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -T)
      TAGLINE="$2"; shift 2;;
    -S)
      SHORTDESC="$2"; shift 2;;
    -D)
      CHANGE_ABOUT=0; shift;;
    -R)
      KEEP_ROADMAP=1; shift;;
    -I)
      REMOVE_INSTRUCTIONS=1; shift;;
    *)
      if [[ -z "$SRC_DIR" ]]; then SRC_DIR="$1";
      elif [[ -z "$NEW_BASE" ]]; then NEW_BASE="$1";
      elif [[ -z "$DEST_PARENT" ]]; then DEST_PARENT="$1";
      fi
      shift;;
  esac
done

if [[ -z "$SRC_DIR" || -z "$NEW_BASE" ]]; then
  echo "Usage: $0 <source_project_dir> <new_project_basename> [<destination_parent_dir>] [flags]"
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

DEST_DIR_ABS="$DEST_PARENT_ABS/$NEW_BASE"

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

# Find the old project basename (search for .kicad_pro files anywhere in the project)
echo ">> Detecting project files in source..."
PRO_FILES=()
while IFS= read -r -d '' file; do
  PRO_FILES+=("$file")
done < <(find "$SRC_DIR_ABS" -name "*.kicad_pro" -print0 2>/dev/null)

OLD_BASE=""
if [[ ${#PRO_FILES[@]} -eq 1 ]]; then
  OLD_BASE="$(basename "${PRO_FILES[0]}" .kicad_pro)"
  echo "   Detected project basename: $OLD_BASE"
elif [[ ${#PRO_FILES[@]} -gt 1 ]]; then
  echo "   Found ${#PRO_FILES[@]} .kicad_pro files. Using the first one as main project."
  OLD_BASE="$(basename "${PRO_FILES[0]}" .kicad_pro)"
  echo "   Using project basename: $OLD_BASE"
else
  echo "   Could not find any .kicad_pro files."
  echo "   Falling back to directory name as basename."
  OLD_BASE="$(basename "$SRC_DIR_ABS")"
fi

echo
echo ">> Copying project folder (excluding junk)..."

# Prefer rsync for selective copy
if command -v rsync >/dev/null 2>&1; then
  rsync -av \
    --exclude '.git/' \
    --exclude '.svn/' \
    --exclude '.hg/' \
    --exclude '.idea/' \
    --exclude '.vscode/' \
    --exclude '__pycache__/' \
    --exclude '*.lock' \
    --exclude '*-backups/' \
    --exclude '*.kicad_sch-bak' \
    --exclude '*~' \
    --exclude '~*' \
    --exclude '_*' \
    --exclude '#*' \
    --exclude '*_old' \
    --exclude '*_old.*' \
    --exclude '*.tmp' \
    --exclude '*.bak' \
    --exclude '*.autosave*' \
    "$SRC_DIR_ABS"/ "$DEST_DIR_ABS"/
else
  echo "   rsync not found, using cp -R (less selective)."
  mkdir -p "$DEST_DIR_ABS"
  cp -R "$SRC_DIR_ABS"/. "$DEST_DIR_ABS"/
  echo "   Removing known junk from copy..."
  rm -rf "$DEST_DIR_ABS/.git" "$DEST_DIR_ABS/.svn" "$DEST_DIR_ABS/.hg" \
         "$DEST_DIR_ABS/.idea" "$DEST_DIR_ABS/.vscode" "$DEST_DIR_ABS/__pycache__" 2>/dev/null || true
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
fi

echo
echo ">> Renaming ALL files and directories containing old basename..."

# Add DPX- prefix to filenames if not already present
FILE_BASE="$NEW_BASE"
if [[ ! "$NEW_BASE" =~ ^DPX[-_] ]]; then
  FILE_BASE="DPX-$NEW_BASE"
  echo "   Adding DPX- prefix to filenames: $FILE_BASE"
fi

# Lowercase new project name for README replacement
NEW_BASE_LC="$(echo "$NEW_BASE" | tr '[:upper:]' '[:lower:]')"

# Function to rename all files and directories containing the old basename
rename_all_occurrences () {
  local found_count=0
  
  # First, rename directories (bottom-up to avoid path issues)
  echo "   Renaming directories..."
  while IFS= read -r -d '' dir_path; do
    local parent_dir="$(dirname "$dir_path")"
    local old_name="$(basename "$dir_path")"
    local new_name="${old_name/$OLD_BASE/$FILE_BASE}"
    
    if [[ "$old_name" != "$new_name" ]]; then
      echo "     $old_name -> $new_name"
      mv "$dir_path" "$parent_dir/$new_name"
      ((found_count++))
    fi
  done < <(find "$DEST_DIR_ABS" -type d -name "*$OLD_BASE*" -print0 2>/dev/null | sort -z -r)
  
  # Then rename files
  echo "   Renaming files..."
  while IFS= read -r -d '' file_path; do
    local parent_dir="$(dirname "$file_path")"
    local old_name="$(basename "$file_path")"
    local new_name="${old_name/$OLD_BASE/$FILE_BASE}"
    
    if [[ "$old_name" != "$new_name" ]]; then
      echo "     $old_name -> $new_name"
      mv "$file_path" "$parent_dir/$new_name"
      ((found_count++))
    fi
  done < <(find "$DEST_DIR_ABS" -type f -name "*$OLD_BASE*" -print0 2>/dev/null)
  
  if [[ $found_count -eq 0 ]]; then
    echo "   (skip) No files or directories containing '$OLD_BASE' found"
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


# === README SANITIZATION ===
README_PATH="$DEST_DIR_ABS/README.md"
if [[ -f "$README_PATH" ]]; then
  echo
  echo ">> Sanitizing README.md..."
  # 1. Replace all instances of old project name with new (lowercase)
  sed -i.bak "s/$OLD_BASE/$NEW_BASE_LC/gI" "$README_PATH"

  # 2a. Tagline under project name (h3 under h1)
  sed -i "0,/^<h3.*>.*<\/h3>/s//<h3 align=\"center\"><i>$TAGLINE<\/i><\/h3>/" "$README_PATH"

  # 2b. Short description (first <p align="center"> block)
  sed -i "0,/^  <p align=\"center\">.*$/s//  <p align=\"center\">\n    $SHORTDESC/" "$README_PATH"

  # 2c. About section
  if [[ $CHANGE_ABOUT -eq 1 ]]; then
    TODAY="$(date '+%Y-%m-%d')"
    sed -i "0,/^fork.*$/s//forked from project '$OLD_BASE' on $TODAY/" "$README_PATH"
  fi


  # 2d. Clear roadmap contents unless -R (leave header, insert '[ ] -')
  if [[ $KEEP_ROADMAP -eq 0 ]]; then
    awk 'BEGIN{roadmap=0} /^## Roadmap/{print;print "\n- [ ] -\n";roadmap=1;next} /^## /{roadmap=0} {if(!roadmap)print}' "$README_PATH" > "$README_PATH.tmp" && mv "$README_PATH.tmp" "$README_PATH"
  fi

  # 2e. Clear instructions if -I (leave headers, insert '*')
  if [[ $REMOVE_INSTRUCTIONS -eq 1 ]]; then
    awk 'BEGIN{gs=0;inst=0} /^## Getting Started/{print;print "\n*\n";gs=1;next} /^## Installation/{print;print "\n*\n";inst=1;next} /^## Usage/{print;print "\n*\n";inst=1;next} /^## /{gs=0;inst=0} {if(!gs&&!inst)print}' "$README_PATH" > "$README_PATH.tmp" && mv "$README_PATH.tmp" "$README_PATH"
  fi

  echo "   README.md sanitized."
fi

echo
echo "== Done =="
echo "New project: $DEST_DIR_ABS"
