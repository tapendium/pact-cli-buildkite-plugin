#!/usr/bin/env bash

set -eo pipefail

CWD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/utils.sh
. "$CWD/utils.sh"

# shellcheck source=lib/pact.sh
. "$CWD/pact.sh"

# shellcheck source=lib/buildkite.sh
. "$CWD/buildkite.sh"

if [[ "${BUILDKITE_PLUGIN_PACT_CLI_DEBUG:-false}" =~ (true|on|1) ]]; then
	echo "~~~ :hammer: Enabling debug mode"
	set -x
fi

function update_pacts {
	assert_var PREFIX

	assert_var PACT_BROKER_USERNAME
	assert_var PACT_BROKER_PASSWORD
	assert_var PACT_BROKER_BASE_URL

	assert_var "${PREFIX}_PACTICIPANT"

	local action_guess
	action_guess="$(get_pipeline_type "$BUILDKITE_PIPELINE_NAME")"
	local action
	action="$(plugin_get_var ACTION "$action_guess")"
	assert_var action

	local pacticipant
	pacticipant="$(plugin_get_var PACTICIPANT)"

	local repo_url
	repo_url="$(plugin_get_var REPO_URL "$BUILDKITE_REPO")"
	assert_var repo_url

	local main_branch
	main_branch="$(plugin_get_var MAIN_BRANCH main)"

	local version
	version="$(plugin_get_var VERSION "$BUILDKITE_COMMIT")"
	assert_var version

	local branch
	branch="$(plugin_get_var BRANCH "$BUILDKITE_BRANCH")"
	assert_var branch

	local environment
	environment="$(plugin_get_var ENVIRONMENT production)"

	local pact_dir
	pact_dir="$(plugin_get_var PACTS_PATH pacts)"

	local skip_publish
	skip_publish="$(plugin_get_var SKIP_PUBLISH "false")"

	upsert_pacticipant "$pacticipant" "$main_branch" "$repo_url"

	if [ "$action" == "pr" ]; then
		# PR pipeline

		if [ "$skip_publish" = "true" ]; then
			log "Skipping publishing of pacts"
		else
			publish_pacts "$version" "$pact_dir" "$branch"

			# Access to Buildkite Graphql API is needed for retrieving verification pipelines
			local bk_gql_url
			bk_gql_url="$(plugin_get_var GRAPHQL_URL "https://graphql.buildkite.com/v1")"
			assert_var BUILDKITE_GRAPHQL_API_TOKEN
			assert_var BUILDKITE_BUILD_URL

			declare -a providers=()
			get_providers_to_check providers "$pacticipant" "$version" "$environment"

			for provider in "${providers[@]}"; do
				log "Reading repository url for $provider from Pact broker"
				url="$(get_repo_url "$provider")"
				log "Repo url for provider $provider: $url"
				pipeline="$(get_verification_pipeline "$url" "$bk_gql_url" "$BUILDKITE_GRAPHQL_API_TOKEN")"
				log "Found pipeline $pipeline"

				trigger="$(generate_trigger_step "$provider" "$pacticipant" "$pipeline")"
				echo "$trigger" | buildkite-agent pipeline upload
			done
		fi

	elif [ "$action" == "merge" ]; then
		if [ "$skip_publish" = "true" ]; then
			log "Skipping publishing of pacts"
			# Pacticipant version needs to be manually created before recording deployment
			# when pacts are not published
			upsert_pacticipant_version "$pacticipant" "$version"
		else
			publish_pacts "$version" "$pact_dir" "$branch"
		fi

		record_deployment "$pacticipant" "$version" "$environment"
	else
		log "Invalid action type. Must be \"pr\" or \"merge\""
		exit 2
	fi
}

update_pacts
