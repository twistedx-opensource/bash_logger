#!/usr/bin/env bash

# MIT License

# Copyright (c) 2022 jscheunemann

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

source ${SCRIPT_DIRNAME}/logger.sh

function set_global_log() {
	set_error_logfile "${SCRIPT_DIRNAME}/global.error.log"
	set_info_logfile "${SCRIPT_DIRNAME}/global.info.log"
	set_debug_logfile "${SCRIPT_DIRNAME}/global.debug.log"

	log2stdout "INFO"
}

function set_ui_log() {
	set_error_logfile "${SCRIPT_DIRNAME}/ui.error.log"
	set_info_logfile "${SCRIPT_DIRNAME}/ui.info.log"
	set_debug_logfile "${SCRIPT_DIRNAME}/ui.debug.log"

	log2stdout "INFO"
}

function log_global_info() {
	set_global_log
	log_info "${1}"
}

function log_global_error() {
	set_global_log
	log_error "${1}"
}

function log_global_debug() {
	set_global_log
	log_debug "${1}"
}

function log_ui_info() {
	set_ui_log
	log_info "${1}"
}

function log_ui_error() {
	set_ui_log
	log_error "${1}"
}

function log_ui_debug() {
	set_ui_log
	log_debug "${1}"
}

log_global_error "I have a problem with you"
log_global_info "Here I am"
log_ui_debug "This is my debug"
log_ui_debug "The contents of ${0}: $(cat ${0})"
