#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# validate_license.sh
#
# Validates that the UPSTREAM license of the exact release/tag being packaged
# permits paid / commercial redistribution (e.g. MIT). The license file is
# downloaded fresh for that specific release; if the license does not allow
# paid distribution -- or cannot be identified -- the build FAILS (exit 1).
#
# Usage:
#   ./validate_license.sh <VERSION>
#
# Optional environment overrides:
#   LICENSE_REPO_URL  Upstream repo URL (default: 'Source:' in debian/copyright)
#   LICENSE_REF       Exact git ref/tag to check (default: derived from VERSION)
#   GITHUB_TOKEN      GitHub API token (avoids rate limiting; optional)
# ---------------------------------------------------------------------------
set -euo pipefail

VERSION="${1:-}"

# --- Licenses that PERMIT paid/commercial redistribution (allowlist) --------
# fail-closed: anything not matched here (or explicitly denied below) fails.
ALLOWED_SPDX=$(cat <<'EOF'
0BSD
AGPL-3.0
AGPL-3.0-only
AGPL-3.0-or-later
Apache-2.0
Artistic-2.0
BSD-2-Clause
BSD-3-Clause
BSD-3-Clause-Clear
BSD-4-Clause
BSL-1.0
CC0-1.0
EPL-2.0
EUPL-1.2
GPL-2.0
GPL-2.0-only
GPL-2.0-or-later
GPL-3.0
GPL-3.0-only
GPL-3.0-or-later
ISC
LGPL-2.1
LGPL-2.1-only
LGPL-2.1-or-later
LGPL-3.0
LGPL-3.0-only
LGPL-3.0-or-later
MIT
MIT-0
MPL-1.1
MPL-2.0
NCSA
OFL-1.1
PostgreSQL
Python-2.0
Unlicense
Vim
WTFPL
X11
Zlib
EOF
)

# --- Licenses that explicitly FORBID paid/commercial redistribution ---------
DENIED_SPDX=$(cat <<'EOF'
BUSL-1.1
CC-BY-NC-1.0
CC-BY-NC-2.0
CC-BY-NC-2.5
CC-BY-NC-3.0
CC-BY-NC-4.0
CC-BY-NC-ND-4.0
CC-BY-NC-SA-4.0
CC-BY-ND-4.0
Elastic-2.0
PolyForm-Noncommercial-1.0.0
PolyForm-Small-Business-1.0.0
Prosperity-3.0.0
SSPL-1.0
EOF
)

fail()  { echo "❌ $*" >&2; exit 1; }
info()  { echo "🔎 $*"; }

# --- Resolve upstream repository -------------------------------------------
REPO_URL="${LICENSE_REPO_URL:-}"
if [ -z "$REPO_URL" ] && [ -f debian/copyright ]; then
  REPO_URL="$(grep -m1 -iE '^Source:' debian/copyright | sed -E 's/^[Ss]ource:[[:space:]]*//; s#[[:space:]]*$##; s#/+$##')"
fi
[ -n "$REPO_URL" ] || fail "Cannot determine upstream repo URL (set LICENSE_REPO_URL or debian/copyright Source)."

stripped="${REPO_URL#http://}"; stripped="${stripped#https://}"; stripped="${stripped%.git}"
HOST="${stripped%%/*}"
rest="${stripped#*/}"
OWNER="${rest%%/*}"
REPO="${rest#*/}"; REPO="${REPO%%/*}"
[ -n "$HOST" ] && [ -n "$OWNER" ] && [ -n "$REPO" ] || fail "Could not parse owner/repo from '$REPO_URL'."

info "Upstream: host=$HOST owner=$OWNER repo=$REPO"

# --- Candidate refs (versioned tag preferred; default branch last resort) ---
declare -a REFS=()
if [ -n "${LICENSE_REF:-}" ]; then
  REFS+=("$LICENSE_REF")
elif [ -n "$VERSION" ]; then
  REFS+=("v$VERSION" "$VERSION")
fi
REFS+=("")   # "" == upstream default branch (fallback for nightly/dev builds)

LICENSE_TEXT=""
SPDX=""
USED_REF=""
USED_FALLBACK=0

gh_auth=()
[ -n "${GITHUB_TOKEN:-}" ] && gh_auth=(-H "Authorization: Bearer $GITHUB_TOKEN")

LICENSE_FILENAMES="LICENSE LICENSE.md LICENSE.txt LICENCE LICENCE.md \
COPYING COPYING.md COPYING.txt LICENSE-MIT LICENSE-APACHE LICENSE-GPL \
LICENSE-AGPL LICENSE.APACHE LICENSE.MIT UNLICENSE license COPYRIGHT"

fetch_github() { # $1 = ref  (GitHub license API -> detects file + SPDX)
  local ref="$1" url resp fname raw
  url="https://api.github.com/repos/$OWNER/$REPO/license"
  [ -n "$ref" ] && url="$url?ref=$ref"
  resp="$(curl -fsSL --max-time 30 -H "Accept: application/vnd.github+json" \
                -H "X-GitHub-Api-Version: 2022-11-28" "${gh_auth[@]}" "$url" 2>/dev/null)" || resp=""
  if [ -n "$resp" ]; then
    SPDX="$(printf '%s' "$resp" | jq -r '.license.spdx_id // empty')"
    LICENSE_TEXT="$(printf '%s' "$resp" | jq -r '.content // empty' | tr -d '\n' | base64 -d 2>/dev/null || true)"
    { [ -n "$SPDX" ] && [ "$SPDX" != "NOASSERTION" ]; } || [ -n "$LICENSE_TEXT" ] && return 0
  fi
  # Multi-license repos (e.g. dual MIT/Apache) make the license API 404 at a
  # tag -- fetch the raw license file directly at this exact ref instead.
  [ -n "$ref" ] || return 1
  for fname in $LICENSE_FILENAMES; do
    raw="$(curl -fsSL --max-time 30 "https://raw.githubusercontent.com/$OWNER/$REPO/$ref/$fname" 2>/dev/null)" || continue
    [ -n "$raw" ] && { LICENSE_TEXT="$raw"; SPDX=""; return 0; }
  done
  return 1
}

fetch_gitea() { # $1 = ref  (Gitea/Forgejo raw API)
  local ref="$1" fname url
  for fname in $LICENSE_FILENAMES; do
    url="https://$HOST/api/v1/repos/$OWNER/$REPO/raw/$fname"
    [ -n "$ref" ] && url="$url?ref=$ref"
    LICENSE_TEXT="$(curl -fsSL --max-time 30 "$url" 2>/dev/null)" || continue
    [ -n "$LICENSE_TEXT" ] && { SPDX=""; return 0; }
  done
  return 1
}

for ref in "${REFS[@]}"; do
  if [ "$HOST" = "github.com" ]; then
    fetch_github "$ref" && { USED_REF="$ref"; break; }
  else
    fetch_gitea  "$ref" && { USED_REF="$ref"; break; }
  fi
done

[ -n "$LICENSE_TEXT" ] || [ -n "$SPDX" ] || fail "Could not download a LICENSE for any ref of $OWNER/$REPO (tried: ${REFS[*]/#/tag })."

if [ -z "$USED_REF" ]; then
  USED_FALLBACK=1
  echo "⚠️  No license found on a versioned tag; validated the upstream default branch instead."
fi
info "License downloaded from ref: '${USED_REF:-<default-branch>}'"

# --- Classify the downloaded license text ----------------------------------
lc="$(printf '%s' "$LICENSE_TEXT" | tr '[:upper:]' '[:lower:]')"

# Restrictive add-ons / source-available licenses are checked FIRST because
# clauses such as "Commons Clause" are appended on top of an otherwise
# permissive (e.g. MIT) license and must still fail the build.
deny_reason=""
if   printf '%s' "$lc" | grep -q "commons clause";                     then deny_reason="Commons Clause (forbids selling)"
elif printf '%s' "$lc" | grep -q "business source license";            then deny_reason="Business Source License (BUSL)"
elif printf '%s' "$lc" | grep -q "server side public license";         then deny_reason="Server Side Public License (SSPL)"
elif printf '%s' "$lc" | grep -q "elastic license";                    then deny_reason="Elastic License (ELv2)"
elif printf '%s' "$lc" | grep -q "polyform noncommercial";             then deny_reason="PolyForm Noncommercial"
elif printf '%s' "$lc" | grep -q "prosperity public license";          then deny_reason="Prosperity Public License (noncommercial)"
elif printf '%s' "$lc" | grep -qE "attribution[- ]noncommercial";      then deny_reason="Creative Commons NonCommercial"
elif printf '%s' "$lc" | grep -qE "for non[- ]?commercial (use|purpose)"; then deny_reason="Noncommercial-only license"
fi
[ -n "$deny_reason" ] && fail "License forbids paid distribution: $deny_reason. Build blocked."

# Trust an explicit SPDX id from the GitHub API when present.
verdict=""
detected="$SPDX"
if [ -n "$SPDX" ] && [ "$SPDX" != "NOASSERTION" ]; then
  if grep -qxF "$SPDX" <<<"$DENIED_SPDX"; then verdict="deny"
  elif grep -qxF "$SPDX" <<<"$ALLOWED_SPDX"; then verdict="allow"
  fi
fi

# Otherwise (or if SPDX unknown) classify from the license text itself.
if [ -z "$verdict" ]; then
  if   printf '%s' "$lc" | grep -q "permission is hereby granted, free of charge"; then detected="MIT"; verdict="allow"
  elif printf '%s' "$lc" | grep -q "apache license" && printf '%s' "$lc" | grep -q "version 2.0"; then detected="Apache-2.0"; verdict="allow"
  elif printf '%s' "$lc" | grep -q "gnu affero general public license";  then detected="AGPL"; verdict="allow"
  elif printf '%s' "$lc" | grep -q "gnu lesser general public license";  then detected="LGPL"; verdict="allow"
  elif printf '%s' "$lc" | grep -q "gnu general public license";         then detected="GPL"; verdict="allow"
  elif printf '%s' "$lc" | grep -q "mozilla public license";             then detected="MPL"; verdict="allow"
  elif printf '%s' "$lc" | grep -q "redistribution and use in source and binary forms"; then detected="BSD"; verdict="allow"
  elif printf '%s' "$lc" | grep -q "permission to use, copy, modify, and/or distribute this software"; then detected="ISC"; verdict="allow"
  elif printf '%s' "$lc" | grep -q "permission to use, copy, modify, and distribute this software and its documentation"; then detected="PostgreSQL/MIT-style"; verdict="allow"
  elif printf '%s' "$lc" | grep -q "this is free and unencumbered software released into the public domain"; then detected="Unlicense"; verdict="allow"
  elif printf '%s' "$lc" | grep -qE "cc0 1\.0|creative commons zero|creative commons legal code"; then detected="CC0-1.0"; verdict="allow"
  elif printf '%s' "$lc" | grep -q "boost software license";             then detected="BSL-1.0"; verdict="allow"
  elif printf '%s' "$lc" | grep -q "do what the fuck you want";           then detected="WTFPL"; verdict="allow"
  elif printf '%s' "$lc" | grep -q "altered source versions must be plainly marked"; then detected="Zlib"; verdict="allow"
  fi
fi

case "$verdict" in
  allow)
    echo "✅ Upstream license '${detected:-unknown}' permits paid distribution."
    exit 0
    ;;
  deny)
    fail "Upstream license '${detected:-$SPDX}' does NOT permit paid distribution. Build blocked."
    ;;
  *)
    echo "----- license text (first 40 lines) -----" >&2
    printf '%s\n' "$LICENSE_TEXT" | head -40 >&2
    echo "-----------------------------------------" >&2
    fail "Could not confirm the upstream license (SPDX='${SPDX:-none}') permits paid distribution. Failing closed."
    ;;
esac
