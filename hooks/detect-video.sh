#!/bin/bash
# Detect video/GIF file paths in user prompt and inject /video directive

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

# Exit silently if no prompt
[ -z "$PROMPT" ] && exit 0

# Trim whitespace
TRIMMED=$(echo "$PROMPT" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# Check if the prompt contains a path ending in a video/GIF extension
# Handles both bare paths and paths with surrounding text
if echo "$TRIMMED" | grep -qiE '\.(mp4|mov|gif|webm|avi|mkv|m4v|flv)(\s|$|")'; then
  # Extract the file path (first token that looks like a video file)
  FILE_PATH=$(echo "$TRIMMED" | grep -oiE '(/[^ "]+\.(mp4|mov|gif|webm|avi|mkv|m4v|flv)|"[^"]+\.(mp4|mov|gif|webm|avi|mkv|m4v|flv)")' | head -1 | tr -d '"')

  # Only inject if we found a valid path
  if [ -n "$FILE_PATH" ]; then
    cat <<ENDJSON
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "<user-prompt-submit-hook>The user dropped a video/GIF file into the terminal. Automatically run the /video skill with argument: ${FILE_PATH}\nDo NOT ask the user for confirmation - just invoke the skill immediately.</user-prompt-submit-hook>"
  }
}
ENDJSON
    exit 0
  fi
fi

exit 0
