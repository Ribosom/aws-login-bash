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

function get_profile_name() {
  echo "${name}-session-token-profile"
}

function build_cipher_text_file() {
  local aws_access_key_id
  local aws_secret_access_key
  local mfa_serial_arn
  local login_session_seconds
  local password
  read -p 'aws_access_key_id: ' aws_access_key_id
  read -p 'aws_secret_access_key: ' -s aws_secret_access_key
  echo
  read -p 'mfa_serial_arn: ' mfa_serial_arn
  read -p 'login_session_seconds: ' login_session_seconds
  read -p 'password: ' -s password
  echo
  local params="aws_access_key_id=${aws_access_key_id}"$'\n'"aws_secret_access_key=${aws_secret_access_key}"$'\n'"mfa_serial_arn=${mfa_serial_arn}"$'\n'"login_session_seconds=${login_session_seconds}"$'\n'
  echo "Write file $(get_cipher_text_file_path)"
  echo "$params" | openssl enc -aes-256-cbc -salt -a -pbkdf2 -iter 1000000 -pass pass:${password} > $(get_cipher_text_file_path)
}

function put_session_token_to_credential_file() {
  local password
  local token_code
  local decrypted_content
  read -p 'Enter password: ' -s password
  echo "Load file $(get_cipher_text_file_path)"
  decrypted_content=$(openssl enc -aes-256-cbc -d -a -pbkdf2 -iter 1000000 -pass pass:"${password}" -in "$(get_cipher_text_file_path)")
  # Check if an error occurred during decryption
  if [ $? -ne 0 ]; then
    echo "Error: Decryption failed." >&2
    exit 1
  fi
  # Source the decrypted content
  source <(echo "$decrypted_content")
  read -p "Enter MFA: " token_code
  export AWS_ACCESS_KEY_ID=${aws_access_key_id}
  export AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}
  local session_tokens
  session_tokens=$(aws sts get-session-token --serial-number "$mfa_serial_arn" --token-code "$token_code" --duration-seconds "$login_session_seconds")
  # Check if an error occurred during decryption
  if [ $? -ne 0 ]; then
    echo "Error: aws sts get-session-token failed." >&2
    exit 1
  fi
  local access_key_id=$(echo "$session_tokens" | awk '{print $2}')
  local secret_access_key=$(echo "$session_tokens" | awk '{print $4}')
  local session_token=$(echo "$session_tokens" | awk '{print $5}')
  aws configure set aws_access_key_id "${access_key_id}" --profile "$(get_profile_name)"
  aws configure set aws_secret_access_key "${secret_access_key}" --profile "$(get_profile_name)"
  aws configure set aws_session_token "${session_token}" --profile "$(get_profile_name)"
  echo "$(get_profile_name) configured in .aws/credentials"
}

if [[ -f $(get_cipher_text_file_path) ]]; then
  put_session_token_to_credential_file
else
  build_cipher_text_file
fi
