# Copilot Coding Agent Instructions for DPX_FORK_KICAD

> **Trust these instructions.** Only search the codebase if information here is incomplete or found to be incorrect.

## Repository Summary

**DPX_FORK_KICAD** is a bash script utility for forking KiCad hardware project folders. It copies a source KiCad project directory, excludes junk files (locks, autosaves, VCS metadata, temp files), renames all files/directories containing the old project basename to a new one, and sanitizes the README.md with customizable content.

| Attribute | Value |
|-----------|-------|
| **Type** | CLI bash script utility |
| **Language** | Bash (100%) |
| **Target Runtime** | macOS/Linux with bash 4+, zsh compatible |
| **Size** | ~15 files, small repository |
| **License** | Unlicense (public domain) |

## Build & Validation Commands

### Syntax Validation (ALWAYS run before committing)
```bash
bash -n src/fork_kicad_project.sh
```
Exit code 0 = valid syntax. Any other exit code indicates a syntax error with line number.

### Running the Script
```bash
# Make executable (one-time)
chmod +x src/fork_kicad_project.sh

# Show usage/help
./src/fork_kicad_project.sh

# Basic usage
./src/fork_kicad_project.sh <source_project_dir> <new_basename> [destination_dir] [flags]

# Example with flags
./src/fork_kicad_project.sh ./ESP32_PROJECT new_project -T 'tagline' -S 'description'
```

### Available Flags
| Flag | Description |
|------|-------------|
| `-T 'text'` | Custom tagline in README |
| `-S 'text'` | Custom short description in README |
| `-D` | Do not change About section |
| `-R` | Do not change Roadmap section |
| `-I` | Remove instruction sections |
| `-A` | Include archive folders (normally excluded) |

### No Build/Test/Lint Steps
This is a standalone bash script with no package manager, build system, or test framework. Validation is syntax checking only.

## Project Layout

```
DPX_FORK_KICAD/
├── src/
│   └── fork_kicad_project.sh    # MAIN SCRIPT - all logic here
├── reference/
│   └── dpx_newProject.sh        # Reference script (similar project creator)
├── .github/
│   ├── ISSUE_TEMPLATE/          # Bug report and feature request templates
│   └── copilot-instructions.md  # This file
├── images/
│   ├── logo.png                 # Project logo
│   └── front.png                # Product image
├── README.md                    # User-facing documentation
├── LICENSE.txt                  # Unlicense
├── _config.yml                  # Jekyll config for GitHub Pages
├── .gitignore                   # KiCad-specific ignores
└── .gitattributes               # Git attributes
```

### Key File: `src/fork_kicad_project.sh`

This is the **only source file** requiring modification for feature changes. Structure:

1. **Lines 1-90**: Header, usage docs, flag descriptions
2. **Lines 91-130**: Argument parsing and flag handling
3. **Lines 131-180**: Path resolution, source/destination validation
4. **Lines 180-220**: rsync/cp file copying with exclusions
5. **Lines 220-300**: `rename_all_occurrences()` function for file/folder renaming
6. **Lines 300-end**: README sanitization with sed/awk

### Critical Code Patterns

**Case-insensitive renaming** (files may be lowercase, folders uppercase):
```bash
OLD_BASE_LC="$(echo "$OLD_BASE" | tr '[:upper:]' '[:lower:]')"
new_name="${new_name//${OLD_BASE}/${FILE_BASE_LC}}"
new_name="${new_name//${OLD_BASE_LC}/${FILE_BASE_LC}}"
```

**macOS sed requires empty string for in-place edit**:
```bash
sed -i '' "s|old|new|gi" "$file"  # Correct for macOS
sed -i "s|old|new|gi" "$file"     # WRONG on macOS
```

**Pipe-based iteration (avoid process substitution for compatibility)**:
```bash
find "$DIR" -type f | while IFS= read -r file; do
  # process file
done
```

## Known Issues & Workarounds

### Syntax Errors
The script has had recurring syntax issues from nested function definitions and unclosed braces. **ALWAYS validate with `bash -n`** after editing.

### Case Sensitivity
KiCad projects often have uppercase folder names (e.g., `ESP32_WROOM/`) but lowercase filenames (`esp32_wroom.kicad_pro`). The rename logic handles both, but test with mixed-case projects.

### Archive Folders
Folders named `archive/` or `archives/` are intentionally skipped during renaming to preserve backups.

### DPX Prefix
Files are automatically prefixed with `dpx_` if not already present (e.g., `project.sch` → `dpx_project.sch`).

## Validation Checklist

Before any PR or commit:
1. ✅ Run `bash -n src/fork_kicad_project.sh` — must exit 0
2. ✅ Run `./src/fork_kicad_project.sh` with no args — must show usage
3. ✅ If modifying rename logic, test with a real KiCad project folder
4. ✅ Verify macOS `sed -i ''` syntax is used (not GNU sed)

## Coding Conventions

- **No modifications to working code without explicit request**
- **Comprehensive commenting** of all code; preserve existing comments
- **Small, incremental changes** to maintain stability
- **Document all changes** in comments when modifying the script
- Use `echo ">> Step..."` for user-facing progress messages
- Use `echo "   ..."` for sub-step details
- Use `echo "   DEBUG: ..."` for debug output (can be removed later)

## Dependencies

| Tool | Purpose | Required |
|------|---------|----------|
| `bash` 4+ | Script execution | Yes |
| `rsync` | Selective file copying | Preferred (falls back to `cp`) |
| `sed` (BSD) | Text replacement in README | Yes |
| `awk` | Section clearing in README | Yes |
| `find` | File/directory discovery | Yes |
| `realpath` or Python 3 | Path resolution | One of these |

## GitHub Workflows

**None configured.** There are no CI/CD pipelines. Validation is manual via `bash -n`.

## Session Context (from prior debugging)

The script underwent extensive debugging for:
- Case-insensitive file/folder matching
- Syntax errors from nested function definitions
- Process substitution compatibility issues
- macOS-specific sed behavior

The `rename_all_occurrences()` function is the most complex part and most likely to need fixes if renaming doesn't work correctly.

---

## Active Task: Fix rename_all_occurrences() Function

### Problem Summary (December 2025)
Commit `c2f91cd` ("fixed rename issues") broke the script. An edit intended to improve the rename function was **pasted inside an `if` block**, creating a nested function definition and deleting critical code.

### Git History Reference
| Commit | Status | Notes |
|--------|--------|-------|
| `6fc3906` | ✅ Working | Original case-sensitivity fixes, uses process substitution |
| `d487603` | ✅ Working | Added input sanitization, changed sed delimiter to `\|` |
| `c2f91cd` | ❌ BROKEN | Attempted pipe-based rewrite, catastrophically malformed |

### Repair Plan (Two Phases)

**Phase A — Restore to working state:**
1. Restore `src/fork_kicad_project.sh` to commit `d487603`
2. Add the expanded input sanitization from c2f91cd (the good part):
   ```bash
   NEW_BASE="${NEW_BASE#/}"
   NEW_BASE="${NEW_BASE%/}"
   NEW_BASE="${NEW_BASE#.}"
   NEW_BASE="${NEW_BASE%.}"
   NEW_BASE="${NEW_BASE// /}"
   ```
3. Validate with `bash -n src/fork_kicad_project.sh`
4. Test with a real KiCad project folder

**Phase B — Improve with pipe-based approach (optional, after A works):**
1. Rewrite `rename_all_occurrences()` using pipes instead of process substitution
2. Use `find -depth -type d | while read` for bottom-up directory traversal
3. Use `awk '{IGNORECASE=1; gsub(old, new)}'` for case-insensitive replacement
4. Ensure proper `while`/`done`, `if`/`fi`, and `}` closures
5. Note: `found_count` won't persist outside pipe subshell (cosmetic issue only)

### What Was Deleted in c2f91cd (must restore)
- `continue` and `fi` after archive folder check
- Rest of directory rename logic with `mv`
- File rename `while` loop
- Function closing `}`
- `rename_all_occurrences` function call
- "Creating backups folder" section
- "Verifying common library assets" echo header

### Key Variables for Rename Logic
- `OLD_BASE` — original folder name (may be uppercase, e.g., `ESP32_WROOM`)
- `OLD_BASE_LC` — lowercase version for matching
- `FILE_BASE` — new filename base with `dpx_` prefix (lowercase)
- `FILE_BASE_LC` — same as FILE_BASE (already lowercase)
- `NEW_BASE_LC` — lowercase new base for README replacement
