#!/usr/bin/env bats

setup() {
	load "$BATS_PLUGIN_PATH/load.bash"

	TEST_PACTS_DIR="$(temp_make)"
	# Uncomment to enable stub debugging
	# export PACT_BROKER_STUB_DEBUG=/dev/tty
}

teardown() {
	temp_del "$TEST_PACTS_DIR"
}

runscript=$PWD/lib/run.sh
prefix="BUILDKITE_PLUGIN_PACT_CLI"
export PACT_BROKER_USERNAME=pact_user
export PACT_BROKER_PASSWORD=pact_pass
export PACT_BROKER_BASE_URL=pact_url
export BUILDKITE_GRAPHQL_API_TOKEN=token
export BUILDKITE_BUILD_URL=https://buildkite.com/build-url
export BUILDKITE_AGENT_ACCESS_TOKEN=bk_token
export BUILDKITE_REPO=git@github.com:tapendium/service.git

@test "run.sh runs to completion" {
	stub curl "cat ./tests/fixtures/buildkite-pipelines.json"
	stub buildkite-agent ""
	stub pact-broker \
		"create-or-update-pacticipant --name service --main-branch main --repository-url git@github.com:tapendium/service.git : echo 'creating/updating pacticipant'" \
		"publish pacts --consumer-app-version somehash --branch branch $TEST_PACTS_DIR : echo 'publishing pacts'" \
		"can-i-deploy --pacticipant service --version somehash --to-environment production --output json : cat ./tests/fixtures/can-i-deploy-false.json && exit 1" \
		"describe-pacticipant --name provider-service --output json : cat ./tests/fixtures/describe-pacticipant.json"

	export "${prefix}_PACTS_PATH"="$TEST_PACTS_DIR"
	export BUILDKITE_COMMIT=somehash
	export BUILDKITE_BRANCH=branch
	export BUILDKITE_PIPELINE_NAME="service test: validate"

	run $runscript

	assert_success

	unstub pact-broker
	unstub buildkite-agent
	unstub curl
}

@test "run.sh runs to completion for merge pipelines" {
	stub pact-broker \
		"create-or-update-pacticipant --name service --main-branch main --repository-url git@github.com:tapendium/service.git : echo 'creating/updating pacticipant'" \
		"publish pacts --consumer-app-version somehash --branch branch $TEST_PACTS_DIR : echo 'publishing pacts'" \
		"record-deployment --pacticipant service --version somehash --environment production : echo 'recording deployment'"

	export "${prefix}_PACTS_PATH"="$TEST_PACTS_DIR"
	export BUILDKITE_COMMIT=somehash
	export BUILDKITE_BRANCH=branch
	export BUILDKITE_PIPELINE_NAME="service test: deploy"

	run $runscript

	assert_success

	unstub pact-broker
}

@test "skip_publish option skips publishing pacts" {
	stub pact-broker \
		"create-or-update-pacticipant --name service --main-branch main --repository-url git@github.com:tapendium/service.git : echo 'creating/updating pacticipant'" \
		"can-i-deploy --pacticipant service --version somehash --to-environment production --output json : cat ./tests/fixtures/can-i-deploy-false.json && exit 1" \
		"describe-pacticipant --name provider-service --output json : cat ./tests/fixtures/describe-pacticipant.json"
	stub buildkite-agent ""

	export "${prefix}_SKIP_PUBLISH"=true
	export "${prefix}_PACTS_PATH"="$TEST_PACTS_DIR"
	export BUILDKITE_COMMIT=somehash
	export BUILDKITE_BRANCH=branch
	export BUILDKITE_PIPELINE_NAME="service test: validate"

	run $runscript

	assert_success
	assert_line "Skipping publishing of pacts"

	unstub buildkite-agent
	unstub pact-broker
}

@test "skip_verify option skips verification of pacts in pr pipeline" {
	stub pact-broker \
		"create-or-update-pacticipant --name service --main-branch main --repository-url git@github.com:tapendium/service.git : echo 'creating/updating pacticipant'" \
		"publish pacts --consumer-app-version somehash --branch branch $TEST_PACTS_DIR : echo 'publishing pacts'"

	export "${prefix}_SKIP_VERIFY"=true
	export "${prefix}_PACTS_PATH"="$TEST_PACTS_DIR"
	export BUILDKITE_COMMIT=somehash
	export BUILDKITE_BRANCH=branch
	export BUILDKITE_PIPELINE_NAME="service test: validate"

	run $runscript

	assert_success
	assert_line "Skipping verification of pacts"

	unstub pact-broker

}

@test "run.sh skips publish when pacts directory is not found" {
	stub curl "cat ./tests/fixtures/buildkite-pipelines.json"
	stub buildkite-agent ""
	stub pact-broker \
		"create-or-update-pacticipant --name service --main-branch main --repository-url git@github.com:tapendium/service.git : echo 'creating/updating pacticipant'" \
		"can-i-deploy --pacticipant service --version somehash --to-environment production --output json : cat ./tests/fixtures/can-i-deploy-false.json && exit 1" \
		"describe-pacticipant --name provider-service --output json : cat ./tests/fixtures/describe-pacticipant.json"

	export BUILDKITE_COMMIT=somehash
	export BUILDKITE_BRANCH=branch
	export BUILDKITE_PIPELINE_NAME="service test: validate"

	run $runscript

	assert_success
	assert_line "Pacts directory \"pacts\" not found"

	unstub pact-broker
	unstub buildkite-agent
	unstub curl
}

@test "run.sh skips publish for merge pipeline when pacts directory is not found" {
	stub pact-broker \
		"create-or-update-pacticipant --name service --main-branch main --repository-url git@github.com:tapendium/service.git : echo 'creating/updating pacticipant'" \
		"create-or-update-version --pacticipant service --version somehash : echo 'creating/updating pacticipant version'" \
		"record-deployment --pacticipant service --version somehash --environment production : echo 'recording deployment'"

	export BUILDKITE_COMMIT=somehash
	export BUILDKITE_BRANCH=branch
	export BUILDKITE_PIPELINE_NAME="service test: deploy"

	run $runscript

	assert_success
	assert_line "Pacts directory \"pacts\" not found"

	unstub pact-broker
}

@test "run.sh uses pacticipant name when supplied" {
	stub curl "cat ./tests/fixtures/buildkite-pipelines.json"
	stub buildkite-agent ""
	stub pact-broker \
		"create-or-update-pacticipant --name service --main-branch main --repository-url git@github.com:tapendium/other-repo.git : echo 'creating/updating pacticipant'" \
		"publish pacts --consumer-app-version somehash --branch branch $TEST_PACTS_DIR : echo 'publishing pacts'" \
		"can-i-deploy --pacticipant service --version somehash --to-environment production --output json : cat ./tests/fixtures/can-i-deploy-false.json && exit 1" \
		"describe-pacticipant --name provider-service --output json : cat ./tests/fixtures/describe-pacticipant.json"

	export BUILDKITE_REPO=git@github.com:tapendium/other-repo.git
	export "${prefix}_PACTICIPANT"=service
	export "${prefix}_PACTS_PATH"="$TEST_PACTS_DIR"
	export BUILDKITE_COMMIT=somehash
	export BUILDKITE_BRANCH=branch
	export BUILDKITE_PIPELINE_NAME="service test: validate"

	run $runscript

	assert_success

	unstub pact-broker
	unstub buildkite-agent
	unstub curl

}
