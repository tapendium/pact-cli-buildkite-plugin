#!/usr/bin/env bash

set -eo pipefail

CWD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$CWD/utils.sh"
. "$CWD/pact.sh"

if [[ "${BUILDKITE_PLUGIN_PACT_CLI_DEBUG:-false}" =~ (true|on|1) ]]; then
	echo "~~~ :hammer: Enabling debug mode"
	set -x
fi

function update_pacts {
	assert_var PREFIX

	assert_var PACT_BROKER_USERNAME
	assert_var PACT_BROKER_PASSWORD
	assert_var PACT_BROKER_BASE_URL

	assert_var "${PREFIX}_ACTION"
	assert_var "${PREFIX}_PACTICIPANT"

	local action="$(plugin_get_var ACTION)"
	local pacticipant="$(plugin_get_var PACTICIPANT)"
	local repo_url="$(plugin_get_var REPO_URL $BUILDKITE_REPO)"
	assert_var repo_url
	local main_branch="$(plugin_get_var MAIN_BRANCH main)"
	local version="$(plugin_get_var VERSION $BUILDKITE_COMMIT)"
	assert_var version
	local branch="$(plugin_get_var BRANCH $BUILDKITE_BRANCH)"
	assert_var branch
	local environment="$(plugin_get_var ENVIRONMENT production)"
	local pact_dir="$(plugin_get_var PACTS_PATH pacts)"

	if [ "$action" == "pr" ]; then
		# Pull Request
		upsert_pacticipant "$pacticipant" "$main_branch" "$repo_url"
		publish_pacts "$version" "$pact_dir" "$branch"
	elif [ "$action" == "merge" ]; then
		publish_pacts "$version" "$pact_dir" "$branch"
		record_deployment "$pacticipant" "$version" "$environment"
	else
		log "Invalid action type. Must be \"pr\" or \"merge\""
		exit 2
	fi
}

update_pacts
