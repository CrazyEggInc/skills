#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SCHEMA_GRAPHQL="$SKILL_DIR/assets/schema.graphql"
SCHEMA_JSON="$SKILL_DIR/assets/schema.json"
CRAZYEGG_GQL_URL="${CRAZYEGG_GQL_URL:-https://api.crazyegg.com/api}"
CRAZYEGG_CONFIG_DIR="${CRAZYEGG_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/crazyegg}"
CRAZYEGG_PAT_FILE="${CRAZYEGG_PAT_FILE:-$CRAZYEGG_CONFIG_DIR/pat}"

die() {
	echo "error: $*" >&2
	exit 1
}

install_hint() {
	local cmd="$1"
	local package="$cmd"

	case "$cmd" in
	rg) package="ripgrep" ;;
	esac

	case "$(uname -s)" in
	Darwin)
		printf 'install it with Homebrew: brew install %s' "$package"
		;;
	MINGW* | MSYS* | CYGWIN*)
		case "$cmd" in
		rg) printf 'install it with winget: winget install BurntSushi.ripgrep.MSVC' ;;
		jq) printf 'install it with winget: winget install jqlang.jq' ;;
		*) printf 'install it with winget or the package manager for your current OS' ;;
		esac
		;;
	Linux)
		if [[ -r /etc/os-release ]]; then
			# shellcheck source=/dev/null
			. /etc/os-release
			case "${ID:-}" in
			ubuntu | debian)
				printf 'install it with apt: sudo apt-get update && sudo apt-get install -y %s' "$package"
				;;
			fedora)
				printf 'install it with dnf: sudo dnf install -y %s' "$package"
				;;
			arch)
				printf 'install it with pacman: sudo pacman -S --needed %s' "$package"
				;;
			opensuse* | sles)
				printf 'install it with zypper: sudo zypper install -y %s' "$package"
				;;
			*)
				printf 'install it with your distro package manager'
				;;
			esac
		else
			printf 'install it with your distro package manager'
		fi
		;;
	*)
		printf 'install it with the package manager for your current OS'
		;;
	esac
}

need_cmd() {
	command -v "$1" >/dev/null 2>&1 || die "missing required command: $1; $(install_hint "$1")"
}

require_schema() {
	[[ -f "$SCHEMA_GRAPHQL" ]] || die "missing schema file: $SCHEMA_GRAPHQL"
	[[ -f "$SCHEMA_JSON" ]] || die "missing schema file: $SCHEMA_JSON"
}

validate_pat() {
	local token="${1:-}"
	[[ -n "$token" ]] || die "missing Crazy Egg personal access token"
	[[ "$token" == ce_pat_* ]] || die "Crazy Egg personal access token must start with ce_pat_"
}

load_saved_pat() {
	if [[ -n "${CRAZYEGG_PAT:-}" ]]; then
		validate_pat "$CRAZYEGG_PAT"
		return 0
	fi

	[[ -f "$CRAZYEGG_PAT_FILE" ]] || return 0

	CRAZYEGG_PAT="$(tr -d '\r\n' <"$CRAZYEGG_PAT_FILE")"
	[[ -n "$CRAZYEGG_PAT" ]] || die "saved PAT file is empty: $CRAZYEGG_PAT_FILE"
	validate_pat "$CRAZYEGG_PAT"
	export CRAZYEGG_PAT
}

require_auth() {
	load_saved_pat
	[[ -n "${CRAZYEGG_PAT:-}" ]] || die "no Crazy Egg PAT found. Ask whether the user already has a Crazy Egg account. If not, use the crazyegg-signup skill. After signup or PAT creation, save it with: bash scripts/crazyegg.sh pat-save ce_pat_..."
}

read_query_arg() {
	local value="${1:-}"
	[[ -n "$value" ]] || die "missing query"

	if [[ -f "$value" ]]; then
		cat "$value"
	else
		printf '%s' "$value"
	fi
}

read_json_arg() {
	local value="${1:-}"

	if [[ -z "$value" ]]; then
		printf '{}'
	elif [[ -f "$value" ]]; then
		cat "$value"
	else
		printf '%s' "$value"
	fi
}

read_pat_arg() {
	local value="${1:-}"
	[[ -n "$value" ]] || die "missing personal access token"

	if [[ -f "$value" ]]; then
		tr -d '\r\n' <"$value"
	else
		printf '%s' "$value"
	fi
}

pat_status() {
	need_cmd jq

	local source="none"

	if [[ -n "${CRAZYEGG_PAT:-}" ]]; then
		validate_pat "$CRAZYEGG_PAT"
		source="environment"
	elif [[ -f "$CRAZYEGG_PAT_FILE" ]]; then
		local saved_pat
		saved_pat="$(tr -d '\r\n' <"$CRAZYEGG_PAT_FILE")"

		if [[ -n "$saved_pat" ]]; then
			validate_pat "$saved_pat"
			source="saved_file"
		fi
	fi

	jq -n \
		--arg source "$source" \
		--arg patFile "$CRAZYEGG_PAT_FILE" \
		'{hasPat: ($source != "none"), source: $source, patFile: $patFile}'
}

save_pat() {
	local token
	token="$(read_pat_arg "${1:-}")"
	validate_pat "$token"

	mkdir -p "$CRAZYEGG_CONFIG_DIR"
	umask 077
	printf '%s\n' "$token" >"$CRAZYEGG_PAT_FILE"

	printf 'saved Crazy Egg PAT to %s\n' "$CRAZYEGG_PAT_FILE"
}

usage() {
	cat <<EOF
Usage:
  crazyegg.sh help
  crazyegg.sh pat-status
  crazyegg.sh pat-save PAT_OR_FILE
  crazyegg.sh schema-summary
  crazyegg.sh root query|mutation|subscription
  crazyegg.sh type TYPE_NAME
  crazyegg.sh field FIELD_NAME
  crazyegg.sh search PATTERN
  crazyegg.sh gql QUERY_OR_FILE [VARIABLES_JSON_OR_FILE]

Commands:
  pat-status       Show whether a PAT is available from env or saved config
  pat-save         Save a PAT to the local config file with owner-only perms
  schema-summary   Show root type names and schema counts from assets/schema.json
  root             Show one root type using the local schema JSON
  type             Show one type definition from the local schema JSON
  field            Find a field across all object/interface types
  search           Grep assets/schema.graphql for fast text lookup
  gql              Execute a GraphQL request against \$CRAZYEGG_GQL_URL

Environment:
  CRAZYEGG_PAT     Optional override for gql. Get it from https://auth.app.crazyegg.com/settings
  CRAZYEGG_GQL_URL Optional. Defaults to https://api.crazyegg.com/api
  CRAZYEGG_PAT_FILE Optional. Defaults to \$XDG_CONFIG_HOME/crazyegg/pat or ~/.config/crazyegg/pat

Examples:
  crazyegg.sh pat-status
  crazyegg.sh pat-save ce_pat_...
  crazyegg.sh schema-summary
  crazyegg.sh root query
  crazyegg.sh type Site
  crazyegg.sh field recordingsList
  crazyegg.sh search recordingsCriteriaDefinition
  crazyegg.sh gql 'query { sites { id name } }'
  crazyegg.sh gql query.graphql variables.json
EOF
}

# shellcheck disable=SC2016
jq_type_helpers='
def type_ref:
  if . == null then null
  elif .kind == "NON_NULL" then ((.ofType | type_ref) + "!")
  elif .kind == "LIST" then ("[" + (.ofType | type_ref) + "]")
  else .name
  end;

def simplify_type($t):
  {
    kind: $t.kind,
    name: $t.name,
    description: $t.description,
    fields: [
      ($t.fields // [])[] | {
        name,
        description,
        type: (.type | type_ref),
        args: [
          (.args // [])[] | {
            name,
            description,
            type: (.type | type_ref),
            defaultValue
          }
        ],
        isDeprecated,
        deprecationReason
      }
    ],
    inputFields: [
      ($t.inputFields // [])[] | {
        name,
        description,
        type: (.type | type_ref),
        defaultValue
      }
    ],
    enumValues: [
      ($t.enumValues // [])[] | {
        name,
        description,
        isDeprecated,
        deprecationReason
      }
    ],
    possibleTypes: [($t.possibleTypes // [])[] | (. | type_ref)]
  };
'

schema_summary() {
	require_schema
	need_cmd jq

	jq '{
    queryType: .data.__schema.queryType.name,
    mutationType: .data.__schema.mutationType.name,
    subscriptionType: .data.__schema.subscriptionType.name,
    typeCount: (.data.__schema.types | length),
    objectCount: (.data.__schema.types | map(select(.kind == "OBJECT")) | length),
    inputObjectCount: (.data.__schema.types | map(select(.kind == "INPUT_OBJECT")) | length),
    enumCount: (.data.__schema.types | map(select(.kind == "ENUM")) | length)
  }' "$SCHEMA_JSON"
}

root_type() {
	require_schema
	need_cmd jq

	local which="${1:-}"
	[[ -n "$which" ]] || die "root requires query, mutation, or subscription"

	local root_name
	case "$which" in
	query) root_name="$(jq -r '.data.__schema.queryType.name' "$SCHEMA_JSON")" ;;
	mutation) root_name="$(jq -r '.data.__schema.mutationType.name // empty' "$SCHEMA_JSON")" ;;
	subscription) root_name="$(jq -r '.data.__schema.subscriptionType.name // empty' "$SCHEMA_JSON")" ;;
	*) die "root must be query, mutation, or subscription" ;;
	esac

	[[ -n "$root_name" ]] || die "schema does not define a $which root type"
	type_details "$root_name"
}

type_details() {
	require_schema
	need_cmd jq

	local name="${1:-}"
	[[ -n "$name" ]] || die "type requires a type name"

	jq --arg name "$name" "$jq_type_helpers
    .data.__schema.types
    | map(select(.name == \$name))
    | if length == 0 then
        error(\"type not found: \" + \$name)
      else
        simplify_type(.[0])
      end
  " "$SCHEMA_JSON"
}

field_details() {
	require_schema
	need_cmd jq

	local field_name="${1:-}"
	[[ -n "$field_name" ]] || die "field requires a field name"

	jq --arg field_name "$field_name" "$jq_type_helpers
    [
      .data.__schema.types[]
      | select((.kind == \"OBJECT\" or .kind == \"INTERFACE\") and (.fields != null))
      | . as \$type
      | (.fields[] | select(.name == \$field_name) | {
          parentType: \$type.name,
          name,
          description,
          type: (.type | type_ref),
          args: [
            (.args // [])[] | {
              name,
              description,
              type: (.type | type_ref),
              defaultValue
            }
          ],
          isDeprecated,
          deprecationReason
        })
    ]
    | if length == 0 then
        error(\"field not found: \" + \$field_name)
      else
        .
      end
  " "$SCHEMA_JSON"
}

search_schema() {
	require_schema
	need_cmd rg

	local pattern="${1:-}"
	[[ -n "$pattern" ]] || die "search requires a pattern"

	rg -n -i --context 2 --color never "$pattern" "$SCHEMA_GRAPHQL"
}

gql() {
	need_cmd jq
	need_cmd curl
	require_auth

	local query_arg="${1:-}"
	local variables_arg="${2:-}"
	local query variables payload

	query="$(read_query_arg "$query_arg")"
	variables="$(read_json_arg "$variables_arg")"
	payload="$(jq -cn --arg query "$query" --argjson variables "$variables" '{query: $query, variables: $variables}')"

	curl --silent --show-error --fail-with-body \
		"$CRAZYEGG_GQL_URL" \
		-H "Authorization: Bearer $CRAZYEGG_PAT" \
		-H "Content-Type: application/json" \
		--data "$payload"
}

main() {
	local cmd="${1:-help}"
	shift || true

	case "$cmd" in
	help | -h | --help) usage ;;
	pat-status) pat_status ;;
	pat-save) save_pat "${1:-}" ;;
	schema-summary) schema_summary ;;
	root) root_type "${1:-}" ;;
	type) type_details "${1:-}" ;;
	field) field_details "${1:-}" ;;
	search) search_schema "${1:-}" ;;
	gql) gql "${1:-}" "${2:-}" ;;
	*) die "unknown command: $cmd" ;;
	esac
}

main "$@"
