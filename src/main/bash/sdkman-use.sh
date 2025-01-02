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

function __sdk_use() {
	local candidate version install

	candidate="$1"
	version="$2"
	__sdkman_check_version_present "$version" || return 1
	__sdkman_check_candidate_present "$candidate" || return 1

	major_version=$(echo $version | cut -d. -f1)
	if [[ "$major_version" == "$version" ]]; then
        count=0
        
        for dir in "${SDKMAN_CANDIDATES_DIR}/${candidate}"/*; do
            if [ -d "$dir" ] && [[ "$(basename "$dir")" == "${major_version}"* ]];
            then
                ((count++))
            fi
        done
        if [[ ${count} -eq 0 ]]
        then
			echo ""
			__sdkman_echo_red "Stop! No matching version found."
			echo ""
        elif [[ ${count} -eq 1 ]]
		then
			version=$(basename $(ls -d "${SDKMAN_CANDIDATES_DIR}/${candidate}/${major_version}"*))
			__sdkman_change_candidate_in_path "$candidate"
			__sdkman_echo_green "Using ${candidate} version ${version} in this shell."
		else
			echo ""
			__sdkman_echo_red "Stop! Cannot decide which version to use."
			echo ""
			__sdkman_echo_yellow
        fi
	else
		if [[ ! -d "${SDKMAN_CANDIDATES_DIR}/${candidate}/${version}" ]]; then
			echo ""
			__sdkman_echo_red "Stop! Candidate version is not installed."
			echo ""
			__sdkman_echo_yellow "Tip: Run the following to install this version"
			echo ""
			__sdkman_echo_yellow "$ sdk install ${candidate} ${version}"
			return 1
		fi
	
		# Just update the *_HOME and PATH for this shell.
		__sdkman_set_candidate_home "$candidate" "$version"
	
		__sdkman_change_candidate_in_path "$candidate"
		if [[ ! (-L "${SDKMAN_CANDIDATES_DIR}/${candidate}/current" || -d "${SDKMAN_CANDIDATES_DIR}/${candidate}/current") ]]; then
			__sdkman_echo_green "Setting ${candidate} version ${version} as default."
			__sdkman_link_candidate_version "$candidate" "$version"
		fi
	
		echo ""
		__sdkman_echo_green "Using ${candidate} version ${version} in this shell."
	fi
}

function __sdkman_change_candidate_in_path() {
	if [[ $PATH =~ ${SDKMAN_CANDIDATES_DIR}/${1}/([^/]+) ]]; then
		local matched_version

		if [[ "$zsh_shell" == "true" ]]; then
			matched_version=${match[1]}
		else
			matched_version=${BASH_REMATCH[1]}
		fi

		export PATH=${PATH//${SDKMAN_CANDIDATES_DIR}\/${candidate}\/${matched_version}/${SDKMAN_CANDIDATES_DIR}\/${candidate}\/${version}}
	fi
}
