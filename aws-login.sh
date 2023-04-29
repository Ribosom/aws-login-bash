#!/usr/bin/bash

function display_help() {
  cat << EOF
Usage: aws-login.sh [OPTIONS] name

This script adds temporary session tokens to the aws credential file, so you don't have to write your permanent secret access key to the aws credential file.
For the first run of a new provided name, it will ask for aws_access_key_id, aws_secret_access_key and mfa_serial_arn and encrypt these to a file with a password you provide.
The file with the encrypted text will be saved next to the credential file as <name>_ciphertext.

If you use aws-login.sh again, you will be asked for your password you provided before and then it will get session token from aws and put those in your credential file:

[<name>-session-token-profile]
aws_access_key_id = *
aws_secret_access_key = *
aws_session_token = *

You can also use this profile as a source profile from where you want to switch roles.

[other-profile]
role_arn=arn:aws:iam::*:role/*
source_profile=<name>-session-token-profile

Options:
  -h, --help    Show this help message and exit

EOF
}

# Check if the first argument is '--help' or '-h'
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  display_help
  exit 0
fi

# Check if the 'aws' command is available
if ! command -v aws >/dev/null 2>&1; then
  echo "Error: The AWS CLI is not installed or not in your PATH." >&2
  exit 1
fi

# Find directory where aws credentials file is located
if [[ -n "$AWS_SHARED_CREDENTIALS_FILE" ]]; then
  aws_credentials_dir="$(dirname "$AWS_SHARED_CREDENTIALS_FILE")"
else
  aws_credentials_dir="$HOME/.aws"
fi

# Check if at least one argument is provided
if [[ $# -lt 1 ]]; then
  echo "Error: No argument provided."
  exit 1
fi

# Check if the argument contains only letters, numbers, dash, or underscore
# and does not start with an underscore or a dash
if [[ ! $1 =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]]; then
  echo "Error: The provided argument is not valid. It must contain only letters, numbers, dash, or underscore, and cannot start with an underscore or a dash."
  exit 1
fi

name=$1

function get_cipher_text_file_name() {
  echo "${name}_ciphertext"
}

function get_cipher_text_file_path() {
  echo "${aws_credentials_dir}/$(get_cipher_text_file_name)"
}

function build_cipher_text_file() {
  # TODO
  local user
  read -p "hi" user
}

function put_session_token_to_credential_file() {
  # TODO
  echo "hi"
}

get_cipher_text_file_path

if [[ -f $(get_cipher_text_file_path) ]]; then
  put_session_token_to_credential_file
else
  build_cipher_text_file
fi

read -p "Username: " username
echo "Blub: ${username}"
echo "Blub: ${user}"
echo "The path to the parent directory of the AWS CLI credential file is: $aws_credentials_dir"
