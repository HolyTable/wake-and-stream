#!/bin/bash
# check-private.sh – stops personal data from ending up in this repository.
#
#   tools/check-private.sh --staged   check what is about to be committed (used by the pre-commit hook)
#   tools/check-private.sh --all      check every file in the working tree
#
# Checks:
#   1. your personal blocklist (default: ~/.wake-and-stream-blocklist.txt, or $WAS_BLOCKLIST)
#      – one text per line, case-insensitive; keep this file OUTSIDE the repo
#   2. generic patterns: private IPs (except the 192.168.1.x examples), MAC addresses (except
#      AA:BB:CC:DD:EE:FF), e-mail addresses (except example/noreply), private keys, SSH public keys
#   3. --staged only: the commit author e-mail must be a GitHub noreply address
set -u
MODE="${1:---staged}"
BLOCKLIST="${WAS_BLOCKLIST:-$HOME/.wake-and-stream-blocklist.txt}"
cd "$(git rev-parse --show-toplevel)" || exit 2
FOUND=0

report() { echo "  ✗ $1: $2"; FOUND=1; }

if [ "$MODE" = "--staged" ]; then
  FILES=$(git diff --cached --name-only --diff-filter=ACMR)
  content() { git show ":$1" 2>/dev/null; }
  EMAIL=$(git config user.email)
  case "$EMAIL" in
    SET-ME@*|"") report "git identity" "user.email is not set – use your GitHub noreply address" ;;
    *@users.noreply.github.com) ;;
    *) report "git identity" "user.email is not a GitHub noreply address" ;;
  esac
else
  FILES=$(git ls-files -co --exclude-standard)
  content() { cat "$1" 2>/dev/null; }
fi

# blocklist entries (comments and empty lines removed)
PATTERNS=""
if [ -f "$BLOCKLIST" ]; then
  PATTERNS=$(grep -v -E '^\s*(#|$)' "$BLOCKLIST" | tr -d '\r')
else
  echo "  ! no personal blocklist found at $BLOCKLIST – only generic checks run"
fi

IP_RE='\b(10\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])|192\.168)\.[0-9]{1,3}\.[0-9]{1,3}\b'
MAC_RE='\b([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}\b'
MAIL_RE='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
KEY_RE='-----BEGIN [A-Z ]*PRIVATE KEY-----|ssh-(ed25519|rsa|ecdsa)[a-z0-9-]* AAAA[0-9A-Za-z+/]{20,}'

while IFS= read -r f; do
  [ -z "$f" ] && continue
  text=$(content "$f" | tr -d '\r\000')   # also drop NUL bytes of binary files (images)
  if [ -n "$PATTERNS" ]; then
    hit=$(printf '%s\n' "$text" | grep -a -i -o -F -f <(printf '%s\n' "$PATTERNS") | sort -u | head -n 3 | tr '\n' ' ')
    [ -n "$hit" ] && report "$f" "blocklist match: $hit"
  fi
  # also check the file name itself against the blocklist
  if [ -n "$PATTERNS" ] && printf '%s\n' "$f" | grep -q -i -F -f <(printf '%s\n' "$PATTERNS"); then
    report "$f" "file name matches blocklist"
  fi
  ips=$(printf '%s\n' "$text" | grep -a -o -E "$IP_RE" | grep -v -E '^192\.168\.1\.[0-9]{1,3}$' | sort -u | head -n 3 | tr '\n' ' ')
  [ -n "$ips" ] && report "$f" "private IP address(es): $ips"
  macs=$(printf '%s\n' "$text" | grep -a -o -E "$MAC_RE" | grep -v -i -E '^AA[:-]BB[:-]CC[:-]DD[:-]EE[:-]FF$' | sort -u | head -n 3 | tr '\n' ' ')
  [ -n "$macs" ] && report "$f" "MAC address(es): $macs"
  mails=$(printf '%s\n' "$text" | grep -a -o -E "$MAIL_RE" \
          | grep -v -i -E '@(example\.(com|org|net)|[a-z0-9.-]*\.invalid|users\.noreply\.github\.com)$' | sort -u | head -n 3 | tr '\n' ' ')
  [ -n "$mails" ] && report "$f" "e-mail address(es): $mails"
  printf '%s\n' "$text" | grep -a -q -E -e "$KEY_RE" && report "$f" "private key or SSH public key"
done <<< "$FILES"

if [ $FOUND -ne 0 ]; then
  echo "✗ Personal data check FAILED – nothing was committed. Fix the files above and try again."
  exit 1
fi
echo "✓ Personal data check passed."
exit 0
