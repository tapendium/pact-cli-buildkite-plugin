#!/usr/bin/env bash

set -euo pipefail

# Create or update participant in Pact broker
function upsert_pacticipant {
	local pacticipant=$1
	local main_branch=$2
	local repo_url=$3

	pact-broker create-or-update-pacticipant \
		--name "$pacticipant" \
		--main-branch "$main_branch" \
		--repository-url "$repo_url"
}

# Record deployment
function record_deployment {
	local pacticipant=$1
	local version=$2
	local environment=$3

	pact-broker record-deployment \
		--pacticipant "$pacticipant" \
		--version "$version" \
		--environment "$environment"
}

# Publish pacts
function publish_pacts {
	local version=$1
	local pact_dir=$2
	local branch=$3

	pact-broker publish pacts \
		--consumer-app-version "$version" \
		--branch "$branch" \
		"$pact_dir"
}
