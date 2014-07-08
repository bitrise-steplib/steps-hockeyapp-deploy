#!/bin/bash
# @Author: Tamas Szucs
# @Date:   2014-05-14 15:16:02
# @Last Modified by:   Tamas Szucs
# @Last Modified time: 2014-07-08 15:54:39

function echoStatusFailed {
  echo "export HOCKEYAPP_DEPLOY_STATUS=\"failed\"" >> ~/.bash_profile
  echo "HOCKEYAPP_DEPLOY_STATUS: \"failed\""
  echo " --------------"
}

#default values

if [[ $HOCKEYAPP_NOTES ]]; then
	notes=$HOCKEYAPP_NOTES
else
	notes="Automatic build with Concrete."
fi

if [[ $HOCKEYAPP_NOTES_TYPE ]]; then
	notes_type=$HOCKEYAPP_NOTES_TYPE
else
	notes_type=0
fi

if [[ $HOCKEYAPP_NOTIFY ]]; then
	notify=$HOCKEYAPP_NOTIFY
else
	notify=2
fi

if [[ $HOCKEYAPP_STATUS ]]; then
	status=$HOCKEYAPP_STATUS
else
	status=2
fi

if [[ $HOCKEYAPP_MANDATORY ]]; then
	mandatory=$HOCKEYAPP_MANDATORY
else
	mandatory=0
fi

echo "CONCRETE_IPA_PATH: $CONCRETE_IPA_PATH"
echo "CONCRETE_DSYM_PATH: $CONCRETE_DSYM_PATH"
echo "HOCKEYAPP_TOKEN: $HOCKEYAPP_TOKEN"
echo "HOCKEYAPP_APP_ID: $HOCKEYAPP_APP_ID"
echo "HOCKEYAPP_NOTES: $notes"
echo "HOCKEYAPP_NOTES_TYPE: $notes_type"
echo "HOCKEYAPP_NOTIFY: $notify"
echo "HOCKEYAPP_STATUS: $status"
echo "HOCKEYAPP_MANDATORY: $mandatory"
echo "HOCKEYAPP_TAGS: $HOCKEYAPP_TAGS"
echo "HOCKEYAPP_COMMIT_SHA: $HOCKEYAPP_COMMIT_SHA"
echo "HOCKEYAPP_BUILD_SERVER_URL: $HOCKEYAPP_BUILD_SERVER_URL"
echo "HOCKEYAPP_REPOSITORY_URL: $HOCKEYAPP_REPOSITORY_URL"

# IPA
if [[ ! -f "$CONCRETE_IPA_PATH" ]]; then
    echo "No IPA found to deploy"
    echo "export HOCKEYAPP_DEPLOY_STATUS=\"failed\"" >> ~/.bash_profile
    echoStatusFailed
    exit 1
fi

# dSYM if provided
if [[ $CONCRETE_DSYM_PATH ]]; then
  if [[ ! -f "$CONCRETE_DSYM_PATH" ]]; then
    echo "No DSYM found to deploy"
    echoStatusFailed
    exit 1
  fi
fi

# App token
if [[ ! $HOCKEYAPP_TOKEN ]]; then
    echo "No App token provided as environment variable"
    echoStatusFailed
    exit 1
fi

# App Id
if [[ ! HOCKEYAPP_APP_ID ]]; then
    echo "No App Id provided as environment variable"
    echoStatusFailed
    exit 1
fi

json=$(curl \
  -F "ipa=@$CONCRETE_IPA_PATH" \
  -F "dsym=@$CONCRETE_DSYM_PATH" \
  -F "notes=$notes" \
  -F "notes_type=$notes_type" \
  -F "notify=$notify" \
  -F "status=$status" \
  -F "mandatory=$mandatory" \
  -F "tags=$HOCKEYAPP_TAGS" \
  -F "commit_sha=$HOCKEYAPP_COMMIT_SHA" \
  -F "build_server_url=$HOCKEYAPP_BUILD_SERVER_URL" \
  -F "repository_url=$HOCKEYAPP_REPOSITORY_URL" \
  -H "X-HockeyAppToken: $HOCKEYAPP_TOKEN" \
  https://rink.hockeyapp.net/api/2/apps/$HOCKEYAPP_APP_ID/app_versions/upload)

echo " --- Result ---"
echo "$json"
echo " --------------\n"

# error handling
if [[ $json ]]; then
  errors=`ruby ./util-jsonval/parse_json.rb \
    --json-string="$json" \
    --prop=errors`
else
  errors="No valid JSON result from request."
fi

if [[ $errors ]]; then
  echo " --FAILED--"
  echo "$errors"
  echoStatusFailed
  exit 1
fi

# everything is OK

echo "export HOCKEYAPP_DEPLOY_STATUS=\"success\"" >> ~/.bash_profile

# public url
public_url=`ruby ./util-jsonval/parse_json.rb \
  --json-string="$json" \
  --prop=public_url`

echo "export HOCKEYAPP_DEPLOY_PUBLIC_URL=\"$public_url\"" >> ~/.bash_profile

# build url
build_url=`ruby ./util-jsonval/parse_json.rb \
  --json-string="$json" \
  --prop=build_url`

echo "export HOCKEYAPP_DEPLOY_BUILD_URL=\"$build_url\"" >> ~/.bash_profile

# config url
config_url=`ruby ./util-jsonval/parse_json.rb \
  --json-string="$json" \
  --prop=config_url`

echo "export HOCKEYAPP_DEPLOY_BUILD_URL=\"$config_url\"" >> ~/.bash_profile

# final results
echo " --SUCCESS--\n output env vars="
echo "HOCKEYAPP_DEPLOY_STATUS: \"success\""
echo "HOCKEYAPP_DEPLOY_PUBLIC_URL: \"$public_url\""
echo "HOCKEYAPP_DEPLOY_BUILD_URL: \"$build_url\""
echo "HOCKEYAPP_DEPLOY_CONFIG_URL: \"$config_url\""
echo " --------------"

exit 0
