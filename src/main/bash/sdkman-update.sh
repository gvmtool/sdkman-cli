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

function __sdk_update {
	local candidates_uri="${SDKMAN_CANDIDATES_API}/candidates/all"
	__sdkman_echo_debug "Using candidates endpoint: $candidates_uri"

	local fetched_candidates_csv=$(__sdkman_secure_curl_with_timeouts "$candidates_uri")
	local detect_html="$(echo "$fetched_candidates" | grep -i 'html')"

	local fetched_candidates=("")
	local cached_candidates=("")

	if [[ "$zsh_shell" == 'true' ]]; then
		fetched_candidates=(${(s:,:)fetched_candidates_csv})
		cached_candidates=(${(s:,:)SDKMAN_CANDIDATES_CSV})
	else
		OLD_IFS="$IFS"
		IFS=","
		fetched_candidates=(${fetched_candidates_csv})
		cached_candidates=(${SDKMAN_CANDIDATES_CSV})
		IFS="$OLD_IFS"
	fi

	__sdkman_echo_debug "Local candidates:   $SDKMAN_CANDIDATES_CSV"
	__sdkman_echo_debug "Fetched candidates: $fetched_candidates_csv"

	if [[ -n "$fetched_candidates_csv" && -z "$detect_html" ]]; then
		# legacy bash workaround
		if [[ "$bash_shell" == 'true' && "$BASH_VERSINFO" -lt 4 ]]; then
			__sdkman_legacy_bash_message
			echo "$fetched_candidates_csv" > "$SDKMAN_CANDIDATES_CACHE"
			return 0
		fi

		__sdkman_echo_debug "Fetched and cached candidate lengths: ${#fetched_candidates_csv} ${#SDKMAN_CANDIDATES_CSV}"

		local combined_candidates=("${fetched_candidates[@]}" "${cached_candidates[@]}")

		local diff_candidates=($(printf $'%s\n' "${combined_candidates[@]}" | sort | uniq -u))

		if ((${#diff_candidates[@]})); then
			echo ""
			__sdkman_echo_green "Setting candidate list to: ${fetched_candidates_csv//,/ }"
			echo "$fetched_candidates_csv" > "$SDKMAN_CANDIDATES_CACHE"
			echo ""
			__sdkman_echo_yellow "Please open a new terminal now..."
		else
			touch "$SDKMAN_CANDIDATES_CACHE"
			__sdkman_echo_green "No new candidates found at this time."
		fi
	fi
}
