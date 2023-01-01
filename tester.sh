#!/usr/bin/env bash

# MIT License

# Copyright (c) 2022-2023 Jason Scheunemann <jason.scheunemann@gmail.com>

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

SCRIPT_FULL_PATH=$(realpath ${0})
SCRIPT_DIRNAME=$(dirname ${SCRIPT_FULL_PATH})
SCRIPT_FILENAME=$(basename ${0})
SCRIPT_FRIENDLY_NAME=${SCRIPT_FILENAME%.*}

VERSION="0.1.0"

source ${SCRIPT_DIRNAME}/logger.sh

function set_global_log() {
	bash_logger_set_error_logfile "${SCRIPT_DIRNAME}/global.error.log"
	bash_logger_set_info_logfile "${SCRIPT_DIRNAME}/global.info.log"
	bash_logger_set_debug_logfile "${SCRIPT_DIRNAME}/global.debug.log"

	log2stdout "DEBUG"
}

function set_ui_log() {
	bash_logger_set_error_logfile "${SCRIPT_DIRNAME}/ui.error.log"
	bash_logger_set_info_logfile "${SCRIPT_DIRNAME}/ui.info.log"
	bash_logger_set_debug_logfile "${SCRIPT_DIRNAME}/ui.debug.log"

	BASH_LOGGER_BASE_DIR="/Users/jason/Projects/bash_logger"

	log2stdout 'INFO'
}

function log_global_info() {
	set_global_log
	log_info "${@}"
}

function log_global_error() {
	set_global_log
	log_error "${@}"
}

function log_global_debug() {
	set_global_log
	log_debug "${@}"
}

function log_ui_info() {
	set_ui_log
	log_info "${@}"
}

function log_ui_error() {
	set_ui_log
	log_error "${@}"
}

function log_ui_debug() {
	set_ui_log
	log_debug "${@}"
}

log_global_debug "Enetering 'now' \n filewatcher"
log_global_error "Unable to load gc"
log_global_debug "Exiting filewatcher" -s "fakesource.sh" -l 202
log_global_info "Here I am"
log_ui_debug "This is my debug" --attribute "action=execute" --attribute "subject=read_logs"
log_ui_debug "$(cat ${0})" --attribute "filename=tester.sh"
