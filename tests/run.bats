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
export BUILDKITE_GRAPHQL_API_TOKEN=token
export BUILDKITE_BUILD_URL=https://buildkite.com/build-url

@test "run.sh runs to completion" {
	stub pact-broker \
		"create-or-update-pacticipant --name service --main-branch main --repository-url repo : echo 'creating/updating pacticipant'" \
		"publish pacts --consumer-app-version somehash --branch branch pacts : echo 'publishing pacts'" \
		"can-i-deploy --pacticipant service --version somehash --to-environment production --output json : cat ./tests/fixtures/can-i-deploy-false.json && exit 1" \
		"describe-pacticipant --name provider-service --output json : cat ./tests/fixtures/describe-pacticipant.json"
	stub curl "cat ./tests/fixtures/buildkite-pipelines.json"

	stub buildkite-agent ""

	export "${prefix}_PACTICIPANT"=service
	export BUILDKITE_REPO=repo
	export BUILDKITE_COMMIT=somehash
	export BUILDKITE_BRANCH=branch
	export BUILDKITE_PIPELINE_NAME="service test: validate"

	run $runscript

	assert_success

	unstub pact-broker
	unstub buildkite-agent
	unstub curl
}
