#!/usr/bin/env bash

# Clear any cached credentials for the profile
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

# Or, if using ~/.aws/credentials, just re-source or restart terminal