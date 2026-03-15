#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-.}"
cd "$ROOT_DIR"

failures=0

err() {
  echo "[SEO FAIL] $1"
  failures=$((failures + 1))
}

extract_meta_content() {
  local file="$1"
  local name="$2"
  perl -0777 -ne 'if (/<meta\s+[^>]*name="'"$name"'"[^>]*content="([^"]+)"[^>]*>/is) { print $1; }' "$file"
}

extract_link_href() {
  local file="$1"
  local rel="$2"
  perl -0777 -ne 'if (/<link\s+[^>]*rel="'"$rel"'"[^>]*href="([^"]+)"[^>]*>/is) { print $1; }' "$file"
}

# Required root crawl files
[[ -f robots.txt ]] || err "Missing robots.txt at repo root"
[[ -f sitemap.xml ]] || err "Missing sitemap.xml at repo root"

while IFS= read -r -d '' file; do
  title_text="$(perl -0777 -ne 'if (/<title>([^<]+)<\/title>/is) { my $t=$1; $t =~ s/^\s+|\s+$//g; print $t; }' "$file")"
  if [[ -z "$title_text" ]]; then
    err "$file: Missing <title>"
  elif [[ "$title_text" == "Untitled" ]]; then
    err "$file: Empty/invalid <title>"
  fi

  desc="$(extract_meta_content "$file" description)"
  if [[ -z "$desc" ]]; then
    err "$file: Missing meta description"
  elif [[ ${#desc} -lt 50 ]]; then
    err "$file: Meta description too short (${#desc} chars)"
  fi

  canonical="$(extract_link_href "$file" canonical)"
  if [[ -z "$canonical" ]]; then
    err "$file: Missing canonical link"
  elif [[ ! "$canonical" =~ ^https:// ]]; then
    err "$file: Canonical must start with https://"
  fi

  robots="$(extract_meta_content "$file" robots)"
  if [[ -z "$robots" ]]; then
    err "$file: Missing meta name=robots"
  fi
done < <(find . -type f -name '*.html' \
  -not -path './node_modules/*' \
  -not -path './.git/*' \
  -not -path './.venv/*' \
  -not -path './.pytest_cache/*' \
  -print0)

while IFS= read -r -d '' md; do
  first_line="$(head -n1 "$md" || true)"
  [[ "$first_line" == "---" ]] || { err "$md: Missing YAML front matter"; continue; }
  for key in title description date tags categories author canonical_url; do
    grep -qE "^${key}:" "$md" || err "$md: Missing front matter key '${key}'"
  done
done < <(find . -type f -name '*.md' \
  -not -path './node_modules/*' \
  -not -path './.git/*' \
  -not -path './.venv/*' \
  -not -path './.pytest_cache/*' \
  -print0)

if [[ -f sitemap.xml ]]; then
  mapfile -t urls < <(grep -oE '<loc>[^<]+' sitemap.xml | sed 's/<loc>//')
  for url in "${urls[@]}"; do
    code="$(curl --silent --head --max-redirs 0 --output /dev/null --write-out '%{http_code}' "$url" || echo 000)"
    [[ "$code" == "200" ]] || err "sitemap.xml URL failed: $url (HTTP $code)"
  done
fi

if [[ "$failures" -gt 0 ]]; then
  echo "SEO lint failed with $failures issue(s)."
  exit 1
fi

echo "SEO lint passed."
