#!/usr/bin/env bash

set -euo pipefail

# Get validate pipeline from Buildkite Graphql API
function get_verification_pipeline {
	local repo="$1"
	local api_url="$2"
	local token="$3"
	local queryData='{"query":"{organization(slug:\"tapendium\"){pipelines(first:10,repository:{url:\"'"${repo}"'\"}){count edges{node{name slug}}}}}"}'

	if ! response=$(
		curl -s "$api_url" \
			--request POST \
			--header "Content-Type: application/json" \
			--header "Authorization: Bearer $token" \
			--data-raw "${queryData}"
	); then
		log "Unable to fetch Buildkite Validate pipeline"
		exit 1
	fi

	slug="$(jq -nr --argjson r "${response}" '$r.data.organization.pipelines.edges | .[] | select(.node.slug | test("validate")) | .node.slug')"

	echo "$slug"
}

# Generate a trigger step for pipeline
function generate_trigger_step {
	local provider="$1"
	local pacticipant="$2"
	local pipelineSlug="$3"

	cat <<EOF
  - label: ":pact: Trigger provider verification for $provider"
    trigger: "$pipelineSlug"
    build:
      branch: main
      env:
        PACT_PACTICIPANT: "${pacticipant}"
        TRIGGER_REASON: "pact_contract_requires_verification" 
        TRIGGER_BUILD_URL: "${BUILDKITE_BUILD_URL}"
        STEP_KEYWORD: pact

EOF
}
