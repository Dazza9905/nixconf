#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: ze [Mozilla add-on URL or short ID]"
}

if (( $# > 1 )); then
  usage >&2
  exit 1
fi
if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then
  usage
  exit 0
fi

addon="${1:-}"
if [[ -z "$addon" ]]; then
  printf 'Mozilla add-on URL or short ID: ' >&2
  IFS= read -r addon
fi

url_pattern='^https?://addons\.mozilla\.org/([A-Za-z-]+/)?firefox/addon/([A-Za-z0-9_-]+)(/)?([?#].*)?$'
if [[ "$addon" =~ $url_pattern ]]; then
  addon="${BASH_REMATCH[2]}"
elif [[ ! "$addon" =~ ^[A-Za-z0-9_-]+$ ]]; then
  echo "Expected an addons.mozilla.org Firefox add-on URL or a short ID, such as darkreader." >&2
  exit 1
fi

if ! metadata=$(curl --fail --silent --show-error --location \
  --connect-timeout 10 --max-time 30 \
  "https://addons.mozilla.org/api/v5/addons/addon/$addon/"); then
  echo "Could not fetch Mozilla add-on metadata for: $addon" >&2
  exit 1
fi

# JSON quoting also needs Nix interpolation escaped.
jq --exit-status --raw-output '
  def nix_string: tojson | split("$" + "{") | join("\\" + "$" + "{");
  if (.slug | type) == "string" and (.guid | type) == "string"
     and (.slug | length) > 0 and (.guid | length) > 0 then
    "(extension " + (.slug | nix_string) + " " + (.guid | nix_string) + ")"
  else
    error("Mozilla response is missing the add-on slug or GUID")
  end
' <<< "$metadata"
