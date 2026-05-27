#!/usr/bin/env bash
# Apple Notes CLI — requires macOS with Notes app

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<EOF
Apple Notes CLI

Usage:
  notes.sh list-folders
  notes.sh list [folder]
  notes.sh read <title> [folder]
  notes.sh write <title> <body> [folder]
  notes.sh delete <title> [folder]

Examples:
  notes.sh list-folders
  notes.sh list
  notes.sh list "Work"
  notes.sh read "Meeting Notes"
  notes.sh write "Shopping List" "Milk, Eggs, Bread"
  notes.sh write "Todo" "Fix bug" "Work"
  notes.sh delete "Old Note"
EOF
}

check_macos() {
  if [[ "$(uname)" != "Darwin" ]]; then
    echo "Error: Apple Notes is only available on macOS." >&2
    exit 1
  fi
}

case "$1" in
  list-folders)
    check_macos
    osascript "$SCRIPT_DIR/list_folders.applescript"
    ;;
  list)
    check_macos
    if [[ -n "$2" ]]; then
      osascript "$SCRIPT_DIR/read_notes.applescript" "$2"
    else
      osascript "$SCRIPT_DIR/read_notes.applescript"
    fi
    ;;
  read)
    check_macos
    if [[ -z "$2" ]]; then
      echo "Error: 'read' requires a note title." >&2
      usage; exit 1
    fi
    folder="${3:-}"
    osascript "$SCRIPT_DIR/read_notes.applescript" "$folder" 2>/dev/null | \
      awk -v title="$2" 'BEGIN{found=0} /^=== /{found=($0=="=== "title" ===")} found{print} /^---$/{if(found)exit}'
    ;;
  write)
    check_macos
    if [[ -z "$2" || -z "$3" ]]; then
      echo "Error: 'write' requires a title and body." >&2
      usage; exit 1
    fi
    if [[ -n "$4" ]]; then
      osascript "$SCRIPT_DIR/write_note.applescript" "$2" "$3" "$4"
    else
      osascript "$SCRIPT_DIR/write_note.applescript" "$2" "$3"
    fi
    ;;
  delete)
    check_macos
    if [[ -z "$2" ]]; then
      echo "Error: 'delete' requires a note title." >&2
      usage; exit 1
    fi
    if [[ -n "$3" ]]; then
      osascript "$SCRIPT_DIR/delete_note.applescript" "$2" "$3"
    else
      osascript "$SCRIPT_DIR/delete_note.applescript" "$2"
    fi
    ;;
  *)
    usage
    ;;
esac
