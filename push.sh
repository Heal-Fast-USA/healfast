#!/bin/bash
# Commit and push HealFast branding. Run from healfast-branding.
# Usage:
#   ./push.sh              # push existing commits to default remote (healfast)
#   ./push.sh origin       # push to origin
#   ./push.sh --commit "message"   # add all, commit, then push to healfast
#   ./push.sh --commit "message" origin   # add all, commit, push to origin
#   ./push.sh --commit "message" both     # add all, commit, push to origin and healfast

set -e

HEALFAST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HEALFAST"

COMMIT_MSG=""
REMOTE="healfast"

while [ -n "$1" ]; do
  case "$1" in
    --commit)
      COMMIT_MSG="$2"
      shift 2
      ;;
    both)
      REMOTE="both"
      shift
      ;;
    origin|healfast)
      REMOTE="$1"
      shift
      ;;
    *)
      echo "Usage: $0 [--commit \"message\"] [origin|healfast|both]"
      exit 1
      ;;
  esac
done

if [ -n "$COMMIT_MSG" ]; then
  git add -A
  git status
  git commit -m "$COMMIT_MSG"
fi

push_one() {
  local r="$1"
  echo "Pushing to $r..."
  git push "$r" main 2>/dev/null || git push "$r" master 2>/dev/null || git push "$r" 2>/dev/null || { echo "Push to $r failed."; return 1; }
}

if [ "$REMOTE" = "both" ]; then
  push_one origin
  push_one healfast
else
  push_one "$REMOTE"
fi

echo "Done."
