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

# Get pacticipant repo url
function get_repo_url {
	local pacticipant="$1"

	if ! result="$(pact-broker describe-pacticipant \
		--name "$pacticipant" \
		--output json)"; then
		log "Unable to describe-pacticipant ${pacticipant}"
		exit 1
	fi

	repo_url=$(jq -nr --argjson r "$result" '$r.repositoryUrl')
	if [ -z "$repo_url" ]; then
		log "Unable to find repository url"
		exit 1
	fi

	echo "$repo_url"
}

# Get providers needing verification
function get_providers_to_check {
	local -n prov="$1"
	local pacticipant="$2"
	local version="$3"
	local environment="$4"

	if ! result="$(pact-broker can-i-deploy \
		--pacticipant "$pacticipant" \
		--version "$version" \
		--to-environment "$environment" \
		--output json)"; then
		log "Summary: $(jq -nr --argjson result "$result" '$result.summary.reason')"

		# Find all provider services where this pacticipant is a consumer and
		# no verification results exist.
		readarray -t prov < <(jq -nr --argjson result "${result}" '$result.matrix | .[] | select(.consumer.name == '\""${pacticipant}"\"') | select(.verificationResult.success != true) | .provider.name')
		log "Providers needing re-verification:"
		log "${prov[@]}"
	fi
}

# Upsert pacticipant version
function upsert_pacticipant_version {
	local pacticipant=$1
	local version=$2

	pact-broker create-or-update-version \
		--pacticipant "$pacticipant" \
		--version "$version"
}
