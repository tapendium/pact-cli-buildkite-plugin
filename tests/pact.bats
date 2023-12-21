#!/usr/bin/env bats

setup() {
	load "$BATS_PLUGIN_PATH/load.bash"

	# Uncomment to enable stub debugging
	# export PACT_BROKER_STUB_DEBUG=/dev/tty
}

pact=$PWD/lib/pact.sh
utils=$PWD/lib/utils.sh
prefix="BUILDKITE_PLUGIN_PACT_CLI"

@test "Can be sourced with no errors" {
	run source "$pact"

	assert_success
}

@test "get_providers_to_check returns an array of providers" {
	stub pact-broker "cat ./tests/fixtures/can-i-deploy-false.json && exit 1"

	source "$utils"
	source "$pact"

	declare -a providers=()
	run get_providers_to_check providers service somehash production

	assert_success
	assert_output --partial "$(
		cat <<-EOF
			Providers needing re-verification:
			provider-service
		EOF
	)"

	unstub pact-broker
}

@test "get_repo_url returns repo url" {
	stub pact-broker \
		"describe-pacticipant --name provider-service --output json : cat ./tests/fixtures/describe-pacticipant.json"

	source "$utils"
	source "$pact"

	run get_repo_url provider-service

	assert_success
	assert_output git@github.com:owner/repo-name.git

	unstub pact-broker
}
