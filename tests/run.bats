#!/usr/bin/env bats

setup() {
	load "$BATS_PLUGIN_PATH/load.bash"

	# Uncomment to enable stub debugging
	# export PACT_BROKER_STUB_DEBUG=/dev/tty
}

runscript=$PWD/lib/run.sh
prefix="BUILDKITE_PLUGIN_PACT_CLI"
export PACT_BROKER_USERNAME=pact_user
export PACT_BROKER_PASSWORD=pact_pass
export PACT_BROKER_BASE_URL=pact_url

@test "run.sh runs to completion" {
	stub pact-broker \
		"'create-or-update-pacticipant' '--name' 'service' '--main-branch' 'main' '--repository-url' 'repo' : echo 'stubbing works'"

	source $runscript
	export "${prefix}_ACTION"=pr
	export "${prefix}_PACTICIPANT"=service
	export BUILDKITE_REPO=repo
	export BUILDKITE_COMMIT=somehash

	run update_pacts

	assert_success
}
