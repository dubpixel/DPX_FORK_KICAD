# ================================================================================
# PROJECT DOCUMENTATION
# ================================================================================
#
# This project includes AI-generated code assistance provided by GitHub Copilot.
# 
# GitHub Copilot is an AI programming assistant that helps developers write code
# more efficiently by providing suggestions and completing code patterns.
#
# Ground Rules for AI Assistance:
# - No modifications to working code without explicit request
# - Comprehensive commenting of all code and preservation of existing comments (remove comments that become false/obsolete)
# - Small, incremental changes to maintain code stability
# - Verification before implementation of any suggestions
# - Stay focused on the current task - do not jump ahead or suggest next steps
# - Answer only what is asked, do not anticipate or propose additional work
# - ALL user prompts and AI solutions must be documented in the change log comments
#   Format: User prompt as single line, followed by itemized solution with → bullet
#
# The AI assistant will follow these directives to ensure code quality,
# maintainability, and collaborative development practices.
#
# ================================================================================
# DPX NEW PROJECT CREATOR
# ================================================================================
#
# Script Name: dpx_newProject.sh
# Architect: dubpixel / Joshua Fleitell
# Purpose: Automated project template generator for software and hardware projects
#
# FUNCTIONALITY OVERVIEW:
# 1) Template Copying: Recursively copies the DPX_BLANK_PROJECT_TEMPLATE folder
#    - Includes all files and directories (including hidden files/folders)
#    - Excludes .git folder to avoid version control conflicts
#    - Copies everything that is there except .git folder
#    - Supports both software and hardware project templates
#
# 2) Project Type Selection and File Processing:
#    - Hardware projects: README-hardware_template.md → README.md
#    - Software projects: README-software_template.md → README.md
#    - CHANGELOG-dpx-template.md → CHANGELOG.md (always copied and renamed)
#    - dpx_release_note_template.md → dpx_release_note_template.md (always copied as-is)
#    - LICENSE.txt → LICENSE.txt (always copied as-is)
#    - .gitignore → .gitignore (always copied as-is)
#    - .gitattributes → .gitattributes (always copied as-is)
#    - _config.yml → _config.yml (always copied as-is)
#
# 3) Root Level File Handling:
#    - Only specific files from root are copied (listed above)
#    - All template README variants are excluded from final project
#    - Other root files (like README.md, CHANGELOG.md, etc.) are not copied
#
# 4) Folder Structure Copying:
#    - All folders except .git are copied recursively and untouched
#    - Includes: images/, hardware/, firmware/, ibom/, .github/, .idea/, etc.
#    - No renaming of folders - copied as-is with full contents
#
#    KEY FILES TO COPY AS-IS:
#     - LICENSE.txt
#     - .gitignore
#     - .gitattributes
#     - _config.yml
#     - dpx_release_note_template.md
#
#   FOLDERS TO COPY RECURSIVELY (excluding .git and .idea):
#     - images/ (project images and assets)
#     - hardware/ (3d/, production_files_RTG/, schematic/, spec/, src/)
#     - firmware/ (firmware code structure)
#     - ibom/ (interactive BOM files)
#     - .github/ (GitHub templates and workflows)
#
#     ** Note: All folders copied as-is with full contents, no renaming
#
# 5) String Replacement: Post-copy processing to customize template files
#    - Updates project-specific strings in key files (README.md, etc.)
#    - Replaces placeholder text with actual project information
#    - Ensures project-specific customization after template deployment
#
# TEMPLATE FOLDER ANALYSIS:
# Based on the path structure, the template folder contains:
# 
# KEY FILES TO COPY AND RENAME:
# - README-hardware_template.md (becomes README.md for hardware projects)
# - README-software_template.md (becomes README.md for software projects)
# - CHANGELOG-dpx-template.md (becomes CHANGELOG.md)
#
# 
#
# ================================================================================
#
# CHANGE LOG:
# 
# User: "lets now write the script : it takes two arguments to start: first argument is the name of the new project and the second argument is the flag for hardware or software -H or -S - the script should encompas steps 1-4 for now and not step number 5"
#   → Added bash script implementation with argument parsing, path validation, and file copying logic
# 
# User: "ok make it work" (after copy errors for .github files)
#   → Fixed by adding mkdir -p before copying files to ensure parent directories exist
# 
# User: "ok so can u also echo wtf its doing?"
#   → Added detailed echo statements for all operations
# 
# User: "ok edit it to take a third argument -V for that level of verbosity otherwise just echo paths"
#   → Modified to accept 3rd argument -V for verbose mode, otherwise show only paths/steps
# 
# User: "can you actually inlcude verbatim what my prompt was? also lets move that section to around line 91-92 in the code."
#   → Moved change log to line ~91 and added verbatim user prompts
#
# User: "oh i want verbatim user prompts as one line and your solution itemized underneath if ui cam pls pagenate like that would be great thx"
#   → Reformatted change log with user prompts as single lines and solutions itemized underneath
#
# User: "ok so this looks like it works good so far lets put the last step into play -step 5. lets write a separate function to search and replace the string in the README.md file. This is pretty straightforwartd i usually do it manually in sublimetext - basically find and replace all."
#   → Added string replacement function for README.md file using sed to replace placeholder strings
#
# User: "ok so now heres a fun side quest. Take this shell script. leave the directives about how to be a good AI and make a programming file template in the firmware/src directory of te current project were working in?"
#   → Created programming file template with AI directives in firmware/src directory
#
# User: "ok make a variant of that, which is a shell script tamplate."
#   → Created shell script template variant in firmware/src directory
#
# User: "ok so here is a twist on step #5. Id like the project name to always be searched and replaced in all lower case regardless of how its typed in as an argument can u do that?"
#   → Modified string replacement function to convert project name to lowercase before replacement
#
#
# User: "theres also a gemfile that we need to copy. - .ideas should have had files ithem idk what happened to them theyre back now."
#   → Need to add Gemfile to list of root files to copy and verify .idea files are being copied properly
#
# User: "im not even sure we need .idea. i thoght it had to do with something i configured to do with how the githuib pages formatting works"
#   → Added Gemfile to root files copy list, .idea folder may not be necessary (IDE-specific files)
#
# User: "ok lets exclude copying it for now but we can revisit it later"
#   → Modified folder copying to exclude .idea folder (like .git exclusion)
#
# User: "can you init this as a git repo"
#   → Will initialize the dpx_new_project folder as a git repository
#
# User: "ok so here is a twist on step #5. Id like the project name to always be searched and replaced in all lower case regardless of how its typed in as an argument can u do that?"
#   → Modified string replacement function to convert project name to lowercase before replacement
#
# User: "ok so somehwo youre still wokring in the old file can e just consolodate to the one version in one folder please"
#   → Consolidated to work only in dpx_new_project folder going forward
#
# User: "ok lets get rid of old file llease"
#   → Removed old script file from create_new_project_script folder
#
# User: "yep. looks good. lets make another change please. can the program find the template folder to copy based on the new location? can u update the file paths that this is correct and easier depending on hwere i move the template folder?"
#   → Updated path logic to search for template folder relative to script location and handle different locations
#
# User: "ok it needs to create the new project one more folder higher than it did. need to beef up that logic as well. always should be in the folder abouve ...DPX_BLANK etc."
#   → Updated destination directory logic to create projects in the folder above DPX_BLANK_PROJECT_TEMPLATE
#
# User: "can we add some features for the arguments - can they be in any order? also can there be a -M 'messsage goes here' where that message is the sassy tagline ? also want to add a feature where -C ' is the longer comment under about the project' do u understand that and this?"
#   → Added flexible argument parsing with -M for sassy tagline and -C for project description, allowing arguments in any order
#
# User: "yes upldate the string replacement part too please"
#   → Updated string replacement function to replace sassy tagline and project description placeholders in README
#
# User: "ok lets also make a change about folder for the -S flag. with the -S flag we dont care about hardware or firmware. we just care instead about making a folder called src instead."
#   → Modified folder copying logic to exclude hardware and firmware folders for software projects, create src folder instead
#
# User: "well thats close there isnt a src in the priject root - i just want u to make one isntead of coputing hardware and fimrware. does that make more sense>?"
#   → Fixed logic to create src folder instead of copying hardware/firmware folders for software projects
#
# User: "if i symlink this script to bin can i execute it? I thinkthat we need to be more specifct about how we define the location of a) where new proects get created b) where the template dir is located"
#   → Added symlink resolution logic, environment variable overrides (DPX_TEMPLATE_DIR, DPX_PROJECTS_DIR, DPX_ROOT), improved path detection
#
# User: "ok that was a little too much at a time remember out rules?"
#   → Acknowledged violation of "small, incremental changes" rule
#
# User: "no lets just keep it the way that it is. - u did a mostly fine job. i think that root should probaly stop at _...CIRCUIT_PROJECTS/... because tats rteally the dpx root.....if u think about it. from there all the project files are one leaf down and the template folders are there as well. dont u think that makes a bit more sense?"
#   → Updated destination directory logic to use _...CIRCUIT_PROJECTS as DPX root instead of going one level above DPX_BLANK_PROJECT_TEMPLATE
#
# User: "are ypu sure that youve fixed all the path stuf to work with these changes? what does it do by default. check that behavior too - shit neets to be 10000% working"
#   → Updated template directory search logic to be consistent with CIRCUIT_PROJECTS root approach
#
# User: "also why arent u adding these prompts to the comments . thats a rule. if its not in the rules add it tothe rules (and put it in the comments)"
#   → Added rule requiring all user prompts and solutions be documented in change log comments
#
# User: "can you also notate the formatting? then update the rules to our template files located in sub folders inside dpx_readme_template"
#   → Added formatting notation to rule (User prompt as single line, solution with → bullet)
#   → Updated programming_template.c and script_template.sh with new documentation rule
#
# User: "youre the best. let me see about doing that sym link and environment variable can u write up some instructions pls? and then add them to the readme where the instructions for usage go"
#   → Created comprehensive symlink and environment variable setup instructions
#   → Added detailed usage section to README.md with basic usage, global installation, and environment variables
#
# User: "can you please fix this" (DPX_ROOT environment variable not finding template directory)
#   → Fixed DPX_ROOT path logic to look for template at $DPX_ROOT/_....DPX_BLANK_PROJECT_TEMPLATE/dpx_readme_template
#

# ================================================================================

#!/bin/bash

# Script implementation - Steps 1-5

# Function to perform string replacement in README.md
replace_readme_strings() {
    local readme_file="$1"
    local project_name="$2"
    local sassy_tagline="$3"
    local project_description="$4"
    
    # Convert project name to lowercase
    local project_name_lower=$(echo "$project_name" | tr '[:upper:]' '[:lower:]')
    
    if [ ! -f "$readme_file" ]; then
        echo "Error: README.md file not found at $readme_file"
        return 1
    fi
    
    echo "Step 5: Performing string replacement in README.md..."
    if [ "$VERBOSE" = true ]; then
        echo "  Replacing 'dpx_replace_projectName' with '$project_name_lower' (lowercase)"
    fi
    
    # Use sed to replace all instances of dpx_replace_projectName with the actual project name in lowercase
    sed -i '' "s/dpx_replace_projectName/$project_name_lower/g" "$readme_file"
    
    # Replace sassy tagline if provided
    if [ -n "$sassy_tagline" ]; then
        if [ "$VERBOSE" = true ]; then
            echo "  Replacing 'a sassy project tag line here' with '$sassy_tagline'"
        fi
        sed -i '' "s/a sassy project tag line here/$sassy_tagline/g" "$readme_file"
    fi
    
    # Replace project description if provided
    if [ -n "$project_description" ]; then
        if [ "$VERBOSE" = true ]; then
            echo "  Replacing '...a short description to tease interest' with '$project_description'"
        fi
        sed -i '' "s/\.\.\.a short description to tease interest/$project_description/g" "$readme_file"
    fi
    
    if [ "$VERBOSE" = true ]; then
        echo "  String replacement completed"
    fi
}

# Check for correct number of arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <project_name> <-H|-S> [-V] [-M 'sassy tagline'] [-C 'project description']"
    echo "  project_name: Name of the new project"
    echo "  -H: Hardware project"
    echo "  -S: Software project"
    echo "  -V: Verbose output (optional)"
    echo "  -M 'message': Sassy tagline for the project (optional)"
    echo "  -C 'comment': Longer description for the project (optional)"
    echo ""
    echo "Arguments can be in any order except project_name must be first"
    echo ""
    echo "Environment Variables (optional):"
    echo "  DPX_TEMPLATE_DIR: Override template directory location"
    echo "  DPX_PROJECTS_DIR: Override where new projects are created"
    echo "  DPX_ROOT: Base directory containing dpx_readme_template folder"
    echo ""
    echo "Examples:"
    echo "  $0 my_project -H                    # Create hardware project"
    echo "  $0 my_app -S -V                     # Create software project with verbose output"
    echo "  DPX_PROJECTS_DIR=~/projects $0 my_project -H  # Create in specific directory"
    exit 1
fi

# Initialize variables
PROJECT_NAME="$1"
shift # Remove project name from arguments
PROJECT_TYPE=""
VERBOSE=false
SASSY_TAGLINE=""
PROJECT_DESCRIPTION=""

# Parse remaining arguments in any order
while [[ $# -gt 0 ]]; do
    case $1 in
        -H|-S)
            if [ -n "$PROJECT_TYPE" ]; then
                echo "Error: Cannot specify both -H and -S"
                exit 1
            fi
            PROJECT_TYPE="$1"
            shift
            ;;
        -V)
            VERBOSE=true
            shift
            ;;
        -M)
            if [ -z "$2" ] || [[ "$2" == -* ]]; then
                echo "Error: -M requires a message argument"
                exit 1
            fi
            SASSY_TAGLINE="$2"
            shift 2
            ;;
        -C)
            if [ -z "$2" ] || [[ "$2" == -* ]]; then
                echo "Error: -C requires a description argument"
                exit 1
            fi
            PROJECT_DESCRIPTION="$2"
            shift 2
            ;;
        *)
            echo "Error: Unknown option $1"
            exit 1
            ;;
    esac
done

# Validate project type flag
if [ -z "$PROJECT_TYPE" ]; then
    echo "Error: Must specify either -H (hardware) or -S (software)"
    exit 1
elif [ "$PROJECT_TYPE" != "-H" ] && [ "$PROJECT_TYPE" != "-S" ]; then
    echo "Error: Project type must be -H (hardware) or -S (software)"
    exit 1
fi

# Resolve actual script location (handle symlinks)
if [ -L "${BASH_SOURCE[0]}" ]; then
    # Script is a symlink, resolve to actual location
    ACTUAL_SCRIPT="$(readlink "${BASH_SOURCE[0]}")"
    if [[ "$ACTUAL_SCRIPT" != /* ]]; then
        # Relative symlink, make it absolute
        ACTUAL_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd "$(dirname "$ACTUAL_SCRIPT")" && pwd)/$(basename "$ACTUAL_SCRIPT")"
    fi
else
    # Script is not a symlink
    ACTUAL_SCRIPT="${BASH_SOURCE[0]}"
fi

SCRIPT_DIR="$(cd "$(dirname "$ACTUAL_SCRIPT")" && pwd)"

# Environment variable overrides (for flexibility when symlinked or moved)
if [ -n "$DPX_TEMPLATE_DIR" ]; then
    TEMPLATE_DIR="$DPX_TEMPLATE_DIR"
    echo "Using template directory from DPX_TEMPLATE_DIR: $TEMPLATE_DIR"
elif [ -n "$DPX_ROOT" ]; then
    TEMPLATE_DIR="$DPX_ROOT/_....DPX_BLANK_PROJECT_TEMPLATE/dpx_readme_template"
    echo "Using template directory from DPX_ROOT: $TEMPLATE_DIR"
else
    # Search for template directory - first try to find CIRCUIT_PROJECTS root, then look for template there
    current_search="$SCRIPT_DIR"
    while [ "$current_search" != "/" ]; do
        if [[ "$(basename "$current_search")" == *"CIRCUIT_PROJECTS"* ]]; then
            # Found the DPX root, look for template there
            if [ -d "$current_search/_....DPX_BLANK_PROJECT_TEMPLATE/dpx_readme_template" ]; then
                TEMPLATE_DIR="$current_search/_....DPX_BLANK_PROJECT_TEMPLATE/dpx_readme_template"
                break
            fi
        fi
        current_search="$(dirname "$current_search")"
    done
    
    # If not found via CIRCUIT_PROJECTS search, try relative paths from script location
    if [ -z "$TEMPLATE_DIR" ]; then
        TEMPLATE_LOCATIONS=(
            "$SCRIPT_DIR/../../dpx_readme_template"                    # From DPX_NEW_PROJECT/src/
            "$SCRIPT_DIR/../dpx_readme_template"                       # From dpx_new_project/
            "$SCRIPT_DIR/../../../dpx_readme_template"                 # One level up from project
        )

        for location in "${TEMPLATE_LOCATIONS[@]}"; do
            if [ -d "$location" ]; then
                TEMPLATE_DIR="$location"
                break
            fi
        done
    fi

    # If still not found, try searching up the directory tree from script location
    if [ -z "$TEMPLATE_DIR" ]; then
        current_dir="$SCRIPT_DIR"
        while [ "$current_dir" != "/" ]; do
            if [ -d "$current_dir/dpx_readme_template" ]; then
                TEMPLATE_DIR="$current_dir/dpx_readme_template"
                break
            fi
            current_dir="$(dirname "$current_dir")"
        done
    fi
fi

# Determine destination directory
if [ -n "$DPX_PROJECTS_DIR" ]; then
    DEST_DIR="$DPX_PROJECTS_DIR/$PROJECT_NAME"
    echo "Using projects directory from DPX_PROJECTS_DIR: $DPX_PROJECTS_DIR"
else
    # Find the _...CIRCUIT_PROJECTS folder (the DPX root)
    current_search="$SCRIPT_DIR"
    while [ "$current_search" != "/" ]; do
        if [[ "$(basename "$current_search")" == *"CIRCUIT_PROJECTS"* ]]; then
            # Found the DPX root, create projects here
            DEST_DIR="$current_search/$PROJECT_NAME"
            break
        fi
        current_search="$(dirname "$current_search")"
    done

    # Fallback if CIRCUIT_PROJECTS not found in path
    if [ -z "$DEST_DIR" ]; then
        # Default behavior - create project in current working directory
        DEST_DIR="$(pwd)/$PROJECT_NAME"
        echo "Warning: Could not locate _...CIRCUIT_PROJECTS folder, creating project in current directory"
    fi
fi

echo "Debug info:"
echo "  Script location: $ACTUAL_SCRIPT"
echo "  Script directory: $SCRIPT_DIR"
echo "  Template directory: $TEMPLATE_DIR"
echo "  Destination directory: $DEST_DIR"
if [ "$VERBOSE" = true ]; then
    echo "  Verbose mode: ON"
else
    echo "  Verbose mode: OFF"
fi
if [ -n "$SASSY_TAGLINE" ]; then
    echo "  Sassy tagline: $SASSY_TAGLINE"
fi
if [ -n "$PROJECT_DESCRIPTION" ]; then
    echo "  Project description: $PROJECT_DESCRIPTION"
fi

# Check if template directory exists
if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "Error: Template directory not found at $TEMPLATE_DIR"
    exit 1
fi

# Check if destination already exists
if [ -d "$DEST_DIR" ]; then
    echo "Error: Project directory $DEST_DIR already exists"
    echo "Please remove it first or choose a different project name"
    exit 1
fi

echo "Creating new project: $PROJECT_NAME"
echo "Project type: $([ "$PROJECT_TYPE" = "-H" ] && echo "Hardware" || echo "Software")"

# Step 1: Create destination directory
echo "Step 1: Creating destination directory..."
mkdir -p "$DEST_DIR"
if [ "$VERBOSE" = true ]; then
    echo "  Created: $DEST_DIR"
fi

# Step 2: Copy all folders recursively (excluding .git)
echo "Step 2: Copying folder structure..."
find "$TEMPLATE_DIR" -type d -name ".git" -prune -o -name ".idea" -prune -o -type d -print | while read dir; do
    if [[ "$dir" != *".git"* ]] && [[ "$dir" != *".idea"* ]]; then
        rel_path="${dir#$TEMPLATE_DIR/}"
        if [ "$rel_path" != "$TEMPLATE_DIR" ]; then
            # For software projects (-S), skip hardware and firmware folders
            if [ "$PROJECT_TYPE" = "-S" ]; then
                if [[ "$rel_path" == "hardware"* ]] || [[ "$rel_path" == "firmware"* ]]; then
                    if [ "$VERBOSE" = true ]; then
                        echo "  Skipping directory (software project): $rel_path"
                    fi
                    continue
                fi
            fi
            
            if [ "$VERBOSE" = true ]; then
                echo "  Creating directory: $rel_path"
            fi
            mkdir -p "$DEST_DIR/$rel_path"
        fi
    fi
done

# Copy all files in folders (excluding .git)
echo "Step 2: Copying files in folders..."
find "$TEMPLATE_DIR" -type f | while read file; do
    if [[ "$file" != *".git/"* ]] && [[ "$file" != *".idea/"* ]]; then
        rel_path="${file#$TEMPLATE_DIR/}"
        # Skip root level files - they'll be handled separately
        if [[ "$rel_path" == *"/"* ]]; then
            # For software projects (-S), skip hardware and firmware files
            if [ "$PROJECT_TYPE" = "-S" ]; then
                if [[ "$rel_path" == "hardware/"* ]] || [[ "$rel_path" == "firmware/"* ]]; then
                    if [ "$VERBOSE" = true ]; then
                        echo "  Skipping file (software project): $rel_path"
                    fi
                    continue
                fi
            fi
            
            if [ "$VERBOSE" = true ]; then
                echo "  Copying file: $rel_path"
            fi
            # Ensure parent directory exists
            mkdir -p "$(dirname "$DEST_DIR/$rel_path")"
            cp "$file" "$DEST_DIR/$rel_path"
        fi
    fi
done

# For software projects, create a src folder instead of hardware/firmware
if [ "$PROJECT_TYPE" = "-S" ]; then
    echo "Step 2: Creating src folder for software project (instead of hardware/firmware)..."
    mkdir -p "$DEST_DIR/src"
    if [ "$VERBOSE" = true ]; then
        echo "  Created src/ directory for software project (replacing hardware/firmware folders)"
    fi
fi

# Step 3: Copy specific root level files as-is
echo "Step 3: Copying root level files..."
if [ "$VERBOSE" = true ]; then
    echo "  Copying LICENSE.txt"
fi
cp "$TEMPLATE_DIR/LICENSE.txt" "$DEST_DIR/LICENSE.txt"
if [ "$VERBOSE" = true ]; then
    echo "  Copying .gitignore"
fi
cp "$TEMPLATE_DIR/.gitignore" "$DEST_DIR/.gitignore"
if [ "$VERBOSE" = true ]; then
    echo "  Copying .gitattributes"
fi
cp "$TEMPLATE_DIR/.gitattributes" "$DEST_DIR/.gitattributes"
if [ "$VERBOSE" = true ]; then
    echo "  Copying _config.yml"
fi
cp "$TEMPLATE_DIR/_config.yml" "$DEST_DIR/_config.yml"
if [ "$VERBOSE" = true ]; then
    echo "  Copying dpx_release_note_template.md"
fi
cp "$TEMPLATE_DIR/dpx_release_note_template.md" "$DEST_DIR/dpx_release_note_template.md"
if [ "$VERBOSE" = true ]; then
    echo "  Copying Gemfile"
fi
cp "$TEMPLATE_DIR/Gemfile" "$DEST_DIR/Gemfile"

# Step 4: Copy and rename template-specific files based on project type
echo "Step 4: Setting up project-specific files..."

# Copy and rename CHANGELOG template
if [ "$VERBOSE" = true ]; then
    echo "  Copying and renaming CHANGELOG-dpx-template.md to CHANGELOG.md"
fi
cp "$TEMPLATE_DIR/CHANGELOG-dpx-template.md" "$DEST_DIR/CHANGELOG.md"

# Copy and rename README template based on project type
if [ "$PROJECT_TYPE" = "-H" ]; then
    if [ "$VERBOSE" = true ]; then
        echo "  Copying and renaming README-hardware_template.md to README.md"
    fi
    cp "$TEMPLATE_DIR/README-hardware_template.md" "$DEST_DIR/README.md"
    echo "Using hardware README template"
else
    if [ "$VERBOSE" = true ]; then
        echo "  Copying and renaming README-software_template.md to README.md"
    fi
    cp "$TEMPLATE_DIR/README-software_template.md" "$DEST_DIR/README.md"
    echo "Using software README template"
fi

echo "Project $PROJECT_NAME created successfully at $DEST_DIR"

# Step 5: Call string replacement function
replace_readme_strings "$DEST_DIR/README.md" "$PROJECT_NAME" "$SASSY_TAGLINE" "$PROJECT_DESCRIPTION"

echo "Project setup complete!"