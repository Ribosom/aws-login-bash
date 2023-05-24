# Recommendations

There are better more secure ways like these:
* https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html.
* https://ben11kehoe.medium.com/never-put-aws-temporary-credentials-in-env-vars-or-credentials-files-theres-a-better-way-25ec45b4d73e.

If this is not possible, and you need a way for legacy tools, you can use this script.

# Prerequisites

* aws cli
* jq

# Script

The provided script adds temporary session tokens to the aws credential file, so you don't have to write your permanent secret access key to the aws credential file.
For the first run of a new provided name, it will ask for aws_access_key_id, aws_secret_access_key and mfa_serial_arn and encrypt these to a file with a password you provide.
The file with the encrypted text will be saved next to the credential file as `<name>_ciphertext`.

If you use aws-login.sh again, you will be asked for your password you provided before and then it will get a session token from aws and put those in your credential file:

```
[<name>-session-token-profile]
aws_access_key_id = *
aws_secret_access_key = *
aws_session_token = *
```

You can also use this profile as a source profile from where you want to switch roles.

```
[other-profile]
role_arn=arn:aws:iam::*:role/*
source_profile=<name>-session-token-profile
```
