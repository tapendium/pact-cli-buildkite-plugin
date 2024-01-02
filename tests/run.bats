#!/usr/bin/env bats

setup() {
	load "$BATS_PLUGIN_PATH/load.bash"

	# Uncomment to enable stub debugging
	# export PACT_BROKER_STUB_DEBUG=/dev/tty

	# stub curl "cat ./tests/fixtures/buildkite-pipelines.json"
	stub buildkite-agent ""
}

teardown() {
	unstub buildkite-agent
}

runscript=$PWD/lib/run.sh
prefix="BUILDKITE_PLUGIN_PACT_CLI"
export PACT_BROKER_USERNAME=pact_user
export PACT_BROKER_PASSWORD=pact_pass
export PACT_BROKER_BASE_URL=pact_url
export BUILDKITE_GRAPHQL_API_TOKEN=token
export BUILDKITE_BUILD_URL=https://buildkite.com/build-url

@test "run.sh runs to completion" {
	stub curl "cat ./tests/fixtures/buildkite-pipelines.json"
	# stub buildkite-agent ""
	stub pact-broker \
		"create-or-update-pacticipant --name service --main-branch main --repository-url repo : echo 'creating/updating pacticipant'" \
		"publish pacts --consumer-app-version somehash --branch branch pacts : echo 'publishing pacts'" \
		"can-i-deploy --pacticipant service --version somehash --to-environment production --output json : cat ./tests/fixtures/can-i-deploy-false.json && exit 1" \
		"describe-pacticipant --name provider-service --output json : cat ./tests/fixtures/describe-pacticipant.json"

	export "${prefix}_PACTICIPANT"=service
	export BUILDKITE_REPO=repo
	export BUILDKITE_COMMIT=somehash
	export BUILDKITE_BRANCH=branch
	export BUILDKITE_PIPELINE_NAME="service test: validate"

	run $runscript

	assert_success

	unstub pact-broker
	unstub curl
}

@test "skip_publish option skips publishing pacts" {
	stub curl "cat ./tests/fixtures/buildkite-pipelines.json"
	stub pact-broker \
		"create-or-update-pacticipant --name service --main-branch main --repository-url repo : echo 'creating/updating pacticipant'" \
		"can-i-deploy --pacticipant service --version somehash --to-environment production --output json : cat ./tests/fixtures/can-i-deploy-false.json && exit 1" \
		"describe-pacticipant --name provider-service --output json : cat ./tests/fixtures/describe-pacticipant.json"

	export "${prefix}_PACTICIPANT"=service
	export "${prefix}_SKIP_PUBLISH"=true
	export "${prefix}_DEBUG"=true
	export BUILDKITE_REPO=repo
	export BUILDKITE_COMMIT=somehash
	export BUILDKITE_BRANCH=branch
	export BUILDKITE_PIPELINE_NAME="service test: validate"

	run $runscript

	assert_success
	assert_output --partial "Skipping publishing of pacts"

	unstub pact-broker
	unstub curl
}
