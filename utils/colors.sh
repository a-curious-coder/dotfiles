#!/usr/bin/env bash

# Color definitions and message functions
# --------------------------------------

COLOR_INFO='\033[1;34m'
COLOR_SUCCESS='\033[1;32m'
COLOR_WARNING='\033[1;33m'
COLOR_ERROR='\033[1;31m'
COLOR_RESET='\033[0m'

function info_msg() {
    echo -e "${COLOR_INFO}ℹ️  $1${COLOR_RESET}"
}

function success_msg() {
    echo -e "${COLOR_SUCCESS}✅  $1${COLOR_RESET}"
}

function warning_msg() {
    echo -e "${COLOR_WARNING}⚠️  $1${COLOR_RESET}"
}

function error_msg() {
    echo -e "${COLOR_ERROR}❌  $1${COLOR_RESET}"
}

