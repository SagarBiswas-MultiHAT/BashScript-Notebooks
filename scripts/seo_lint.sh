#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-.}"
cd "$ROOT_DIR"

failures=0

err() {
  echo "[SEO FAIL] $1"
  failures=$((failures + 1))
}

info() {
  echo "[SEO INFO] $1"
}

extract_meta_content() {
  local file="$1"
  local name="$2"
  perl -0777 -ne 'if (/<meta\s+[^>]*name=["\x27]'"$name"'["\x27][^>]*content=["\x27]([^"\x27]+)["\x27][^>]*>/is) { print $1; }' "$file"
}

extract_link_href() {
  local file="$1"
  local rel="$2"
  perl -0777 -ne 'if (/<link\s+[^>]*rel=["\x27]'"$rel"'["\x27][^>]*href=["\x27]([^"\x27]+)["\x27][^>]*>/is) { print $1; }' "$file"
}

extract_title() {
  local file="$1"
  perl -0777 -ne 'if (/<title>([^<]+)<\/title>/is) { my $t=$1; $t =~ s/^\s+|\s+$//g; print $t; }' "$file"
}

extract_sitemap_urls() {
  local file="$1"
  perl -0777 -ne 'while (/<loc>\s*([^<\s]+)\s*<\/loc>/g) { print "$1\n"; }' "$file"
}

http_200() {
  local url="$1"
  local attempt
  for attempt in 1 2 3; do
    local code
    code="$(curl --silent --head --show-error --location --max-redirs 0 --connect-timeout 8 --max-time 20 \
      --output /dev/null --write-out '%{http_code}' "$url" || echo 000)"
    if [[ "$code" == "200" ]]; then
      return 0
    fi
    sleep "$attempt"
  done
  return 1
}

# Required root crawl files
[[ -f robots.txt ]] || err "Missing robots.txt at repo root"
[[ -f sitemap.xml ]] || err "Missing sitemap.xml at repo root"

info "Scanning HTML metadata checks"

while IFS= read -r -d '' file; do
  title_text="$(extract_title "$file")"
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
  -not -path './.github/*' \
  -not -path './.vscode/*' \
  -not -path './.venv/*' \
  -not -path './.pytest_cache/*' \
  -not -name 'google*.html' \
  -print0)

info "Scanning Markdown front matter"

while IFS= read -r -d '' md; do
  first_line="$(head -n1 "$md" || true)"
  [[ "$first_line" == "---" ]] || { err "$md: Missing YAML front matter"; continue; }
  for key in title description date tags categories author canonical_url; do
    grep -qE "^${key}:" "$md" || err "$md: Missing front matter key '${key}'"
  done
done < <(find . -type f -name '*.md' \
  -not -path './node_modules/*' \
  -not -path './.git/*' \
  -not -path './.github/*' \
  -not -path './.vscode/*' \
  -not -path './.venv/*' \
  -not -path './.pytest_cache/*' \
  -print0)

if [[ -f sitemap.xml ]]; then
  info "Checking sitemap URL status codes"
  mapfile -t urls < <(extract_sitemap_urls sitemap.xml)
  for url in "${urls[@]}"; do
    http_200 "$url" || err "sitemap.xml URL failed after retries: $url"
  done
fi

if [[ "$failures" -gt 0 ]]; then
  echo "SEO lint failed with $failures issue(s)."
  exit 1
fi

echo "SEO lint passed."
