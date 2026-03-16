#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-.}"
cd "$ROOT_DIR"

failures=0
warnings=0

err() {
  printf '[SEO FAIL] %s\n' "$1"
  failures=$((failures + 1))
}

warn() {
  printf '[SEO WARN] %s\n' "$1"
  warnings=$((warnings + 1))
}

info() {
  printf '[SEO INFO] %s\n' "$1"
}

require_tool() {
  local tool="$1"
  command -v "$tool" >/dev/null 2>&1 || {
    printf '[SEO FAIL] Missing required tool: %s\n' "$tool"
    exit 1
  }
}

extract_meta_content() {
  local file="$1"
  local name="$2"
  SEO_META_NAME="$name" perl -0777 -ne '
    my $name = quotemeta $ENV{SEO_META_NAME};
    if (/<meta\b(?=[^>]*\bname=["\x27]$name["\x27])(?=[^>]*\bcontent=["\x27]([^"\x27]+)["\x27])[^>]*>/is) {
      print $1;
    }
  ' "$file"
}

extract_link_href() {
  local file="$1"
  local rel="$2"
  SEO_LINK_REL="$rel" perl -0777 -ne '
    my $rel = quotemeta $ENV{SEO_LINK_REL};
    if (/<link\b(?=[^>]*\brel=["\x27]$rel["\x27])(?=[^>]*\bhref=["\x27]([^"\x27]+)["\x27])[^>]*>/is) {
      print $1;
    }
  ' "$file"
}

extract_title() {
  local file="$1"
  perl -0777 -ne '
    if (/<title>(.*?)<\/title>/is) {
      my $title = $1;
      $title =~ s/^\s+|\s+$//g;
      $title =~ s/\s+/ /g;
      print $title;
    }
  ' "$file"
}

extract_front_matter() {
  local file="$1"
  perl -0777 -ne 'if (/\A---\s*\n(.*?)\n---\s*(?:\n|\z)/s) { print $1; }' "$file"
}

extract_sitemap_urls() {
  local file="$1"
  perl -0777 -ne 'while (/<loc>\s*([^<\s]+)\s*<\/loc>/g) { print "$1\n"; }' "$file"
}

extract_robots_sitemap_urls() {
  local file="$1"
  sed -nE 's/^[[:space:]]*[Ss]itemap:[[:space:]]*(https:\/\/[^[:space:]]+)[[:space:]]*$/\1/p' "$file"
}

strip_wrapping_quotes() {
  local value="$1"

  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"

  case "$value" in
    \"*\")
      value="${value:1:-1}"
      ;;
    \'*\')
      value="${value:1:-1}"
      ;;
  esac

  printf '%s' "$value"
}

front_matter_value() {
  local front_matter="$1"
  local key="$2"

  grep -m1 -E "^${key}:[[:space:]]*.+$" <<<"$front_matter" | sed -E "s/^${key}:[[:space:]]*//" || true
}

is_repository_doc_markdown() {
  local path="$1"
  local basename
  basename="$(basename "$path")"

  case "${basename,,}" in
    readme.md|contributing.md|security.md|changelog.md|code_of_conduct.md)
      return 0
      ;;
  esac

  return 1
}

should_check_http() {
  local setting="${SEO_LINT_CHECK_HTTP:-auto}"

  case "${setting,,}" in
    1|true|yes|on)
      return 0
      ;;
    0|false|no|off)
      return 1
      ;;
    auto)
      [[ -n "${CI:-}" ]]
      return
      ;;
    *)
      warn "Unknown SEO_LINT_CHECK_HTTP value '${setting}'; defaulting to auto mode"
      [[ -n "${CI:-}" ]]
      return
      ;;
  esac
}

http_200() {
  local url="$1"
  local attempt
  local code

  for attempt in 1 2 3; do
    code="$(curl --silent --show-error --head --connect-timeout 8 --max-time 20 \
      --output /dev/null --write-out '%{http_code}' "$url" || echo 000)"
    if [[ "$code" == "200" ]]; then
      return 0
    fi
    sleep "$attempt"
  done

  return 1
}

find_html_files() {
  find . -type f -name '*.html' \
    -not -path './node_modules/*' \
    -not -path './.git/*' \
    -not -path './.github/*' \
    -not -path './.vscode/*' \
    -not -path './.venv/*' \
    -not -path './.pytest_cache/*' \
    -not -path './coverage/*' \
    -not -path './dist/*' \
    -not -name 'google*.html' \
    -print0
}

find_markdown_files() {
  find . -type f -name '*.md' \
    -not -path './node_modules/*' \
    -not -path './.git/*' \
    -not -path './.github/*' \
    -not -path './.vscode/*' \
    -not -path './.venv/*' \
    -not -path './.pytest_cache/*' \
    -not -path './coverage/*' \
    -not -path './dist/*' \
    -print0
}

validate_robots_txt() {
  local sitemap_url
  local sitemap_urls=()

  [[ -f robots.txt ]] || {
    err "Missing robots.txt at repo root"
    return
  }

  grep -qiE '^User-agent:[[:space:]]*\*' robots.txt || err "robots.txt: Missing wildcard User-agent directive"
  grep -qiE '^Sitemap:[[:space:]]*https://' robots.txt || err "robots.txt: Missing HTTPS Sitemap directive"

  mapfile -t sitemap_urls < <(extract_robots_sitemap_urls robots.txt)
  if [[ "${#sitemap_urls[@]}" -eq 0 ]]; then
    err "robots.txt: No sitemap URLs found"
    return
  fi

  for sitemap_url in "${sitemap_urls[@]}"; do
    [[ "$sitemap_url" =~ ^https:// ]] || err "robots.txt: Sitemap URL must start with https:// ($sitemap_url)"
  done

  if ! should_check_http; then
    info "Skipping live robots.txt sitemap URL checks outside CI (set SEO_LINT_CHECK_HTTP=1 to enable)"
    return
  fi

  require_tool curl
  info "Checking robots.txt sitemap URLs"

  for sitemap_url in "${sitemap_urls[@]}"; do
    http_200 "$sitemap_url" || err "robots.txt sitemap URL failed after retries: $sitemap_url"
  done
}

validate_sitemap_xml() {
  local url
  local urls=()

  [[ -f sitemap.xml ]] || {
    err "Missing sitemap.xml at repo root"
    return
  }

  mapfile -t urls < <(extract_sitemap_urls sitemap.xml)
  if [[ "${#urls[@]}" -eq 0 ]]; then
    err "sitemap.xml: Missing <loc> URLs"
    return
  fi

  for url in "${urls[@]}"; do
    [[ "$url" =~ ^https:// ]] || err "sitemap.xml: URL must start with https:// ($url)"
  done

  if ! should_check_http; then
    info "Skipping live sitemap URL checks outside CI (set SEO_LINT_CHECK_HTTP=1 to enable)"
    return
  fi

  require_tool curl
  info "Checking sitemap URL status codes"

  for url in "${urls[@]}"; do
    http_200 "$url" || err "sitemap.xml URL failed after retries: $url"
  done
}

scan_html_files() {
  local file
  local title_text
  local desc
  local canonical
  local robots

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
  done < <(find_html_files)
}

scan_markdown_files() {
  local md
  local first_line
  local front_matter
  local key
  local desc
  local canonical_url

  info "Scanning Markdown front matter"

  while IFS= read -r -d '' md; do
    IFS= read -r first_line < "$md" || first_line=""

    if [[ "$first_line" != "---" ]]; then
      if is_repository_doc_markdown "$md"; then
        info "$md: Skipping repository docs without front matter"
      else
        warn "$md: Markdown file has no YAML front matter; skipping"
      fi
      continue
    fi

    front_matter="$(extract_front_matter "$md")"
    if [[ -z "$front_matter" ]]; then
      err "$md: YAML front matter is not closed properly"
      continue
    fi

    for key in title description date tags categories author canonical_url; do
      grep -qE "^${key}:[[:space:]]*.+$" <<<"$front_matter" || err "$md: Missing front matter key '${key}'"
    done

    desc="$(front_matter_value "$front_matter" description)"
    desc="$(strip_wrapping_quotes "$desc")"
    if [[ -n "$desc" && ${#desc} -lt 50 ]]; then
      err "$md: Front matter description too short (${#desc} chars)"
    fi

    canonical_url="$(front_matter_value "$front_matter" canonical_url)"
    canonical_url="$(strip_wrapping_quotes "$canonical_url")"
    if [[ -n "$canonical_url" && ! "$canonical_url" =~ ^https:// ]]; then
      err "$md: canonical_url must start with https://"
    fi
  done < <(find_markdown_files)
}

require_tool find
require_tool grep
require_tool perl
require_tool sed

validate_robots_txt
validate_sitemap_xml
scan_html_files
scan_markdown_files

if [[ "$failures" -gt 0 ]]; then
  printf 'SEO lint failed with %d issue(s).\n' "$failures"
  exit 1
fi

if [[ "$warnings" -gt 0 ]]; then
  printf 'SEO lint passed with %d warning(s).\n' "$warnings"
else
  echo "SEO lint passed."
fi
