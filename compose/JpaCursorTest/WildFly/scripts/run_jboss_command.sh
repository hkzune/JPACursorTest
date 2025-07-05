#!/bin/bash

WF_MANAGEMENT_USER=${WF_MANAGEMENT_USER:-"admin"}
WF_MANAGEMENT_PASSWORD=${WF_MANAGEMENT_PASSWORD:-"Admin"}
JBOSS_CLI_ARGS=(-u="${WF_MANAGEMENT_USER}" -p="${WF_MANAGEMENT_PASSWORD}" -c --controller=localhost:9990)

run_jboss_command() {
	local cli_args=("${JBOSS_CLI_ARGS[@]}" --commands="$1")
    "${JBOSS_HOME}/bin/jboss-cli.sh" "${cli_args[@]}"
}

run_jboss_command "$@"