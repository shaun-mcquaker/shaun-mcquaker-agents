#!/usr/bin/env bash
set -euo pipefail

# Research Export Script
# Concatenates all Logseq pages for a research topic into a single clean Markdown file.
#
# Usage: ./export.sh <TopicName>
# Example: ./export.sh EcommercePulse
#
# Output: ~/Documents/Logseq/exports/<TopicName>_export_<YYYY-MM-DD>.md

TOPIC="${1:?Usage: export.sh <TopicName>}"
PAGES_DIR="$HOME/Documents/Logseq/pages"
EXPORT_DIR="$HOME/Documents/Logseq/exports"
DATE=$(date +%Y-%m-%d)
OUTPUT_FILE="$EXPORT_DIR/${TOPIC}_export_${DATE}.md"

# Verify source files exist
shopt -s nullglob
FILES=("$PAGES_DIR"/Research___"${TOPIC}"*.md)
shopt -u nullglob

if [ ${#FILES[@]} -eq 0 ]; then
    echo "Error: No files found matching Research___${TOPIC}*.md in $PAGES_DIR" >&2
    exit 1
fi

# Create export directory
mkdir -p "$EXPORT_DIR"

# Sort files: index first, then by round number
sort_files() {
    local index_file=""
    local round_files=()

    for f in "${FILES[@]}"; do
        basename=$(basename "$f")
        if [[ "$basename" == "Research___${TOPIC}.md" ]]; then
            index_file="$f"
        else
            round_files+=("$f")
        fi
    done

    # Print index first
    if [ -n "$index_file" ]; then
        echo "$index_file"
    fi

    # Sort round files by extracting round number
    for f in "${round_files[@]}"; do
        # Extract round number from filename
        round_num=$(echo "$(basename "$f")" | grep -oE 'Round [0-9]+' | grep -oE '[0-9]+' || echo "999")
        echo "$round_num $f"
    done | sort -n | cut -d' ' -f2-
}

# Convert Logseq outliner format to standard Markdown
convert_logseq_to_markdown() {
    local file="$1"

    while IFS= read -r line; do
        # Skip Logseq property lines (key:: value format at top of file)
        if [[ "$line" =~ ^[a-z][a-z-]*:: ]]; then
            continue
        fi

        # Skip empty lines that follow properties (before content starts)
        if [ -z "$line" ]; then
            echo ""
            continue
        fi

        # Strip wikilink brackets: [[Some/Page]] -> Some/Page
        line=$(echo "$line" | sed 's/\[\[\([^]]*\)\]\]/\1/g')

        # Convert outliner bullets to standard Markdown
        # Match leading spaces + "- " pattern
        if [[ "$line" =~ ^(\ *)-\ (.*) ]]; then
            indent="${BASH_REMATCH[1]}"
            content="${BASH_REMATCH[2]}"
            indent_level=$(( ${#indent} / 2 ))

            # Check if content starts with ## heading
            if [[ "$content" =~ ^(\#+)\ (.*) ]]; then
                # It's a heading — output as standard Markdown heading
                echo "$content"
            elif [[ "$content" =~ ^TODO\ (.*) ]]; then
                # It's a Logseq TODO — convert to Markdown checkbox
                task_text="${BASH_REMATCH[1]}"
                printf '%*s- [ ] %s\n' $((indent_level * 2)) '' "$task_text"
            elif [[ "$content" =~ ^DONE\ (.*) ]]; then
                # It's a completed Logseq task
                task_text="${BASH_REMATCH[1]}"
                printf '%*s- [x] %s\n' $((indent_level * 2)) '' "$task_text"
            else
                # Regular content — determine if it's a list item or paragraph
                if [ "$indent_level" -eq 0 ]; then
                    # Top-level bullet becomes a paragraph
                    echo "$content"
                    echo ""
                elif [ "$indent_level" -eq 1 ]; then
                    # First-level indent — paragraph under heading
                    echo "$content"
                    echo ""
                else
                    # Deeper indent — becomes a bullet list
                    printf '%*s- %s\n' $(( (indent_level - 2) * 2 )) '' "$content"
                fi
            fi
        else
            # Non-bullet line (e.g., code block content, table continuation)
            # Strip leading indentation that was for Logseq nesting
            echo "$line" | sed 's/^  *//'
        fi
    done < "$file"
}

# Build the export
{
    # Document header
    echo "# Research: ${TOPIC}"
    echo ""
    echo "*Exported on ${DATE} from Logseq deep research artifacts.*"
    echo "*Source: ${#FILES[@]} files*"
    echo ""
    echo "---"
    echo ""

    first=true
    while IFS= read -r file; do
        if [ "$first" = true ]; then
            first=false
        else
            # Separator between sections
            echo ""
            echo "---"
            echo ""
        fi

        convert_logseq_to_markdown "$file"
    done < <(sort_files)

} > "$OUTPUT_FILE"

echo "Exported ${#FILES[@]} files to: $OUTPUT_FILE"
