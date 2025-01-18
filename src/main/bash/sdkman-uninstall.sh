#!/usr/bin/env bash

#
#   Copyright 2021 Marco Vermeulen
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

function __sdk_uninstall() {
	__sdkman_deprecation_notice "uninstall"
	local candidate version current

	candidate="$1"
	version="$2"
	__sdkman_check_candidate_present "$candidate" || return 1
	__sdkman_check_version_present "$version" || return 1

	current=$(readlink "${SDKMAN_CANDIDATES_DIR}/${candidate}/current" | sed "s!${SDKMAN_CANDIDATES_DIR}/${candidate}/!!g")
	if [[ -L "${SDKMAN_CANDIDATES_DIR}/${candidate}/current" && "$version" == "$current" ]]; then
		echo ""
		__sdkman_echo_green "Deselecting ${candidate} ${version}..."
		unlink "${SDKMAN_CANDIDATES_DIR}/${candidate}/current"
	fi

	echo ""

	if [[ -d "${SDKMAN_CANDIDATES_DIR}/${candidate}/${version}" || -L "${SDKMAN_CANDIDATES_DIR}/${candidate}/${version}" ]]; then
		__sdkman_echo_green "Uninstalling ${candidate} ${version}..."
		rm -rf "${SDKMAN_CANDIDATES_DIR}/${candidate}/${version}"
	else
		__sdkman_echo_red "${candidate} ${version} is not installed."
	fi
}
