#!/usr/bin/env bash

CWD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$CWD/constants.sh"

# Read plugin property value from its name
function plugin_get_var {
	local name="${PREFIX}_${1}"
	local default="${2:-}"
	echo "${!name:-$default}"
}

# Echo to standard error
function log {
	echo "$@" 1>&2
}

# Asserts the variable supplied is defined/non-null
function assert_var {
	if [ -z "${!1:-}" ]; then
		log "Variable $1 is not set"
		exit 1
	fi
}

# Print the value of a variable
function print_var {
	local varName="$1"
	local key="${2:-$varName}"
	echo "$key: ${!varName}"
}

# Mask the content of a variable with *
function mask() {
	local varName="${!1}"
	count=${#varName}

	for ((i = 0; i < "$count"; ++i)); do
		printf "*"
	done
}

# Checks if command can be found in PATH
function command_exists {
	local cmdName=$1
	if ! command -v "$cmdName" &>/dev/null; then
		echo "The '$cmdName' command could not be found. Please ensure it has been installed"
		exit 1
	fi
}
