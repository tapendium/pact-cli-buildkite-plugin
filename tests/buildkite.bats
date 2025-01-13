#!/usr/bin/env bats

setup() {
	load "$BATS_PLUGIN_PATH/load.bash"

	# Uncomment to enable stub debugging
	# export CURL_STUB_DEBUG=/dev/tty
}

buildkite=$PWD/lib/buildkite.sh
prefix="BUILDKITE_PLUGIN_PACT_CLI"

@test "Can be sourced with no errors" {
	run source "$buildkite"

	assert_success
}

@test "get_verification_pipeline returns the correct pipeline slug" {
	stub curl "cat ./tests/fixtures/buildkite-pipelines.json"

	source "$buildkite"

	run get_verification_pipeline "git@github.com:owner/repo-name.git" "https://graphql.buildkite.com/v1" token
	assert_success
	assert_output service-a-validate

	unstub curl
}

@test "generate_trigger_step produces the correct output" {
	source "$buildkite"
	export BUILDKITE_BUILD_URL="https://buildkite.com/build-url"
	run generate_trigger_step provider-service consumer-service provider-pipeline-slug

	assert_success
	assert_output "$(
		cat <<-EOF
			  - label: ":pact: Trigger provider verification for provider-service"
			    trigger: "provider-pipeline-slug"
			    build:
			      branch: main
			      env:
			        PACT_PACTICIPANT: "consumer-service"
			        TRIGGER_REASON: "pact_contract_requires_verification" 
			        TRIGGER_BUILD_URL: "https://buildkite.com/build-url"
			        STEP_KEYWORD: pact
		EOF
	)"
}
