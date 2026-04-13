#!/usr/bin/env bash

set -euo pipefail

readonly CRAZYEGG_SIGNUP_URL="https://auth.app.crazyegg.com/signup"

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

usage() {
	cat <<'EOF'
Usage:
  crazyegg-signup.sh EMAIL [FIRST_NAME] [LAST_NAME] [PAT_NAME] [--site SITE_URL] [--open]

Behavior:
  Uses the fixed signup page URL:
    https://auth.app.crazyegg.com/signup
  Constructs a browser signup URL with optional prefill query params:
    email
    first_name
    last_name
    site
    pat_name
  Prints the final URL to stdout.
  If --open is passed, attempts to open the URL with xdg-open or open.
EOF
}

open_url() {
	local url="$1"

	if command -v xdg-open >/dev/null 2>&1; then
		xdg-open "$url" >/dev/null 2>&1 &
		return 0
	fi

	if command -v open >/dev/null 2>&1; then
		open "$url" >/dev/null 2>&1 &
		return 0
	fi

	die "could not find a browser opener; install xdg-open or use the printed URL"
}

main() {
	local email="${1:-}"
	local first_name=""
	local last_name=""
	local pat_name=""
	local site=""
	local maybe_open=""
	local query
	local final_url

	[[ "$email" == "" ]] && usage && exit 1
	shift

	if [[ $# -gt 0 && "${1:-}" != --* ]]; then
		first_name="$1"
		shift
	fi

	if [[ $# -gt 0 && "${1:-}" != --* ]]; then
		last_name="$1"
		shift
	fi

	if [[ $# -gt 0 && "${1:-}" != --* ]]; then
		pat_name="$1"
		shift
	fi

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--site)
			shift
			[[ $# -gt 0 ]] || die "--site requires a value"
			site="$1"
			;;
		--open)
			maybe_open="--open"
			;;
		*)
			die "unknown argument: $1"
			;;
		esac
		shift
	done

	need_cmd jq

	query="$(
		jq -rn \
			--arg email "$email" \
			--arg first_name "$first_name" \
			--arg last_name "$last_name" \
			--arg site "$site" \
			--arg pat_name "$pat_name" \
			'
      {
        email: $email,
        first_name: $first_name,
        last_name: $last_name,
        site: $site,
        pat_name: $pat_name
      }
      | with_entries(select(.value != ""))
      | to_entries
      | map("\(.key)=\(.value|@uri)")
      | join("&")
      '
	)"

	if [[ "$query" == "" ]]; then
		final_url="$CRAZYEGG_SIGNUP_URL"
	elif [[ "$CRAZYEGG_SIGNUP_URL" == *\?* ]]; then
		final_url="${CRAZYEGG_SIGNUP_URL}&${query}"
	else
		final_url="${CRAZYEGG_SIGNUP_URL}?${query}"
	fi

	printf '%s\n' "$final_url"

	if [[ "$maybe_open" == "--open" ]]; then
		open_url "$final_url"
	fi
}

main "$@"
