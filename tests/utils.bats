#!/usr/bin/env bats

setup() {
	load "$BATS_PLUGIN_PATH/load.bash"

	# Uncomment to enable stub debugging
	# export GIT_STUB_DEBUG=/dev/tty
}

utils=$PWD/lib/utils.sh

@test "Runs with no errors" {
	run "$utils"

	assert_success
}

@test "assert_var throws for non-existent variable" {
	source "$utils"

	run assert_var non_existent_variable

	assert_failure
	assert_output --partial "not set"
}

@test "assert_var does not throw for set variable" {
	source "$utils"

	export TEST_VAR="test value"
	run assert_var TEST_VAR

	assert_success
}

@test "plugin_get_var returns the correct value" {
	source $utils
	export BUILDKITE_PLUGIN_PACT_CLI_PACTICIPANT=test-participant

	run plugin_get_var PACTICIPANT
	assert_success
	assert_output test-participant
}

@test "plugin_get_var returns the default value when var is not set" {
	source "$utils"

	run plugin_get_var NONEXISTENT default-value
	assert_success
	assert_output default-value
}

@test "plugin_get_var returns default value pointing to env var" {
	source $utils

	export TEST_VAR=test-value
	run plugin_get_var NONEXISTENT $TEST_VAR
	assert_success
	assert_output test-value
}
