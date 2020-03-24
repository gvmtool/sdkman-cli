#!/usr/bin/env bash

#
#   Copyright 2017 Marco Vermeulen
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

function __sdkman_path_contains {
	[[ "${PATH}" =~ "${1}" ]]
	return "${?}"
}

function __sdkman_set_candidate_home {
	local candidate version upper_candidate

	candidate="${1}"
	version="${2}"

	upper_candidate=$(echo "${candidate}" | tr '[:lower:]' '[:upper:]')
	export "${upper_candidate}_HOME"="${SDKMAN_CANDIDATES_DIR}/${candidate}/${version}"
}

function __sdkman_export_candidate_home {
	local candidate_name="${1}"
	local candidate_dir="${2}"
	local candidate_home_var="$(echo ${candidate_name} | tr '[:lower:]' '[:upper:]')_HOME"
	export $(echo "${candidate_home_var}")="${candidate_dir}"
}

function __sdkman_prepend_candidate_to_path {
	local candidate_bin_dir
	candidate_bin_dir="$(__sdkman_determine_candidate_bin_dir "${SDKMAN_CANDIDATES_DIR}/${1}/current")"
	__sdkman_path_contains "${candidate_bin_dir}" || PATH="${candidate_bin_dir}:${PATH}"
}

function __sdkman_determine_candidate_bin_dir {
	local candidate_dir="${1}"
	if [[ -d "${candidate_dir}/bin" ]]; then
		echo "${candidate_dir}/bin"
	else
		echo "${candidate_dir}"
	fi
}

function __sdkman_link_candidate_version {
	local candidate version

	candidate="${1}"
	version="${2}"

	# Change the 'current' symlink for the candidate, hence affecting all shells.
	if [[ -d "${SDKMAN_CANDIDATES_DIR}/${candidate}/current" ]]; then
		rm -rf "${SDKMAN_CANDIDATES_DIR}/${candidate}/current"
	fi

	ln -s "${SDKMAN_CANDIDATES_DIR}/${candidate}/${version}" "${SDKMAN_CANDIDATES_DIR}/${candidate}/current"
}
