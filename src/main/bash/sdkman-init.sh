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

# set env vars if not set
if [ -z "$SDKMAN_CANDIDATES_API" ]; then
	export SDKMAN_CANDIDATES_API="@SDKMAN_CANDIDATES_API@"
fi

if [ -z "$SDKMAN_DIR" ]; then
	export SDKMAN_DIR="$HOME/.sdkman"
fi

# Load the sdkman config if it exists.
if [ -f "${SDKMAN_DIR}/etc/config" ]; then
	source "${SDKMAN_DIR}/etc/config"
fi

# Read the platform file
SDKMAN_PLATFORM="$(cat "${SDKMAN_DIR}/var/platform")"
export SDKMAN_PLATFORM

# OS specific support (must be 'true' or 'false').
cygwin=false
darwin=false
solaris=false
freebsd=false
SDKMAN_KERNEL="$(uname -s)"
case "${SDKMAN_KERNEL}" in
	CYGWIN*)
		cygwin=true
		;;
	Darwin*)
		darwin=true
		;;
	SunOS*)
		solaris=true
		;;
	FreeBSD*)
		freebsd=true
esac

# Determine shell
zsh_shell=false
bash_shell=false

if [[ -n "$ZSH_VERSION" ]]; then
	zsh_shell=true
elif [[ -n "$BASH_VERSION" ]]; then
	bash_shell=true
fi

# Source sdkman module scripts and extension files.
#
# Extension files are prefixed with 'sdkman-' and found in the ext/ folder.
# Use this if extensions are written with the functional approach and want
# to use functions in the main sdkman script. For more details, refer to
# <https://github.com/sdkman/sdkman-extensions>.
OLD_IFS="$IFS"
IFS=$'\n'
scripts=($(find -L "${SDKMAN_DIR}/src" "${SDKMAN_DIR}/ext" -type f -name 'sdkman-*.sh'))
for f in "${scripts[@]}"; do
	source "$f"
done
IFS="$OLD_IFS"
unset OLD_IFS scripts f

# Create upgrade delay file if it doesn't exist
if [[ ! -f "${SDKMAN_DIR}/var/delay_upgrade" ]]; then
	touch "${SDKMAN_DIR}/var/delay_upgrade"
fi

# set curl connect-timeout and max-time
if [[ -z "$sdkman_curl_connect_timeout" ]]; then sdkman_curl_connect_timeout=7; fi
if [[ -z "$sdkman_curl_max_time" ]]; then sdkman_curl_max_time=10; fi

# set curl retry
if [[ -z "${sdkman_curl_retry}" ]]; then sdkman_curl_retry=0; fi

# set curl retry max time in seconds
if [[ -z "${sdkman_curl_retry_max_time}" ]]; then sdkman_curl_retry_max_time=60; fi

# set curl to continue downloading automatically
if [[ -z "${sdkman_curl_continue}" ]]; then sdkman_curl_continue=true; fi

# read list of candidates and set array
SDKMAN_CANDIDATES_CACHE="${SDKMAN_DIR}/var/candidates"
SDKMAN_CANDIDATES_CSV=$(<"$SDKMAN_CANDIDATES_CACHE")
__sdkman_echo_debug "Setting candidates csv: $SDKMAN_CANDIDATES_CSV"
if [[ "$zsh_shell" == 'true' ]]; then
	SDKMAN_CANDIDATES=(${(s:,:)SDKMAN_CANDIDATES_CSV})
else
	IFS=',' read -a SDKMAN_CANDIDATES <<< "${SDKMAN_CANDIDATES_CSV}"
fi

export SDKMAN_CANDIDATES_DIR="${SDKMAN_DIR}/candidates"

for candidate_name in "${SDKMAN_CANDIDATES[@]}"; do
	candidate_dir="${SDKMAN_CANDIDATES_DIR}/${candidate_name}/current"
	if [[ -h "$candidate_dir" || -d "${candidate_dir}" ]]; then
		__sdkman_export_candidate_home "$candidate_name" "$candidate_dir"
		__sdkman_prepend_candidate_to_path "$candidate_dir"
	fi
done
unset candidate_name candidate_dir
export PATH

# source completion scripts
if [[ "$sdkman_auto_complete" == 'true' ]]; then
	if [[ "$zsh_shell" == 'true' ]]; then
		# initialize zsh completions (if not already done)
		if ! (( $+functions[compdef] )) ; then
			autoload -Uz compinit
			if [[ $ZSH_DISABLE_COMPFIX == 'true' ]]; then
				compinit -u -C
			else
				compinit
			fi
		fi
		autoload -U bashcompinit
		bashcompinit
		source "${SDKMAN_DIR}/contrib/completion/bash/sdk"
		__sdkman_echo_debug "ZSH completion script loaded..."
	elif [[ "$bash_shell" == 'true' ]]; then
		source "${SDKMAN_DIR}/contrib/completion/bash/sdk"
		__sdkman_echo_debug "Bash completion script loaded..."
	else
		__sdkman_echo_debug "No completion scripts found for $SHELL"
	fi
fi

if [[ "$sdkman_auto_env" == "true" ]]; then
	if [[ "$zsh_shell" == "true" ]]; then
		function sdkman_auto_env() {
			if [[ -n $SDKMAN_ENV ]] && [[ ! $PWD =~ ^$SDKMAN_ENV ]]; then
				sdk env clear
			fi
			if [[ -f .sdkmanrc ]]; then
				sdk env
			fi
		}

		chpwd_functions+=(sdkman_auto_env)
	else
		function sdkman_auto_env() {
			if [[ -n $SDKMAN_ENV ]] && [[ ! $PWD =~ ^$SDKMAN_ENV ]]; then
				sdk env clear
			fi
			if [[ "$SDKMAN_OLD_PWD" != "$PWD" ]] && [[ -f ".sdkmanrc" ]]; then
				sdk env
			fi

			export SDKMAN_OLD_PWD="$PWD"
		}
		
		trimmed_prompt_command="${PROMPT_COMMAND%"${PROMPT_COMMAND##*[![:space:]]}"}"
		[[ -z "$trimmed_prompt_command" ]] && PROMPT_COMMAND="sdkman_auto_env" || PROMPT_COMMAND="${trimmed_prompt_command%\;};sdkman_auto_env"
	fi

	sdkman_auto_env
fi
