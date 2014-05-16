#!/bin/bash
# @Author: Tamas Szucs
# @Date:   2014-05-14 15:16:02
# @Last Modified by:   Tamas Szucs
# @Last Modified time: 2014-05-16 14:39:36

source ./util-jsonval/step.sh

#default values

if [ ${HOCKEYAPP_NOTES+x} ]; then
	notes=$HOCKEYAPP_NOTES
else
	notes="Automatic build with Concrete."
fi

if [ ${HOCKEYAPP_NOTES_TYPE+x} ]; then
	notes_type=$HOCKEYAPP_NOTES_TYPE
else
	notes_type=0
fi

if [ ${HOCKEYAPP_NOTIFY+x} ]; then
	notify=$HOCKEYAPP_NOTIFY
else
	notify=2
fi

if [ ${HOCKEYAPP_STATUS+x} ]; then
	status=$HOCKEYAPP_STATUS
else
	status=2
fi

if [ ${HOCKEYAPP_MANDATORY+x} ]; then
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
    echo "export CONCRETE_DEPLOY_STATUS=\"failed\"" >> ~/.bash_profile
    echo "export TESTFLIGHT_DEPLOY_STATUS=\"failed\"" >> ~/.bash_profile
    exit 1
fi

# dSYM if provided
if [ ${CONCRETE_DSYM_PATH+x} ]; then
  if [[ ! -f "$CONCRETE_DSYM_PATH" ]]; then
    echo "No DSYM found to deploy"
    echo "export CONCRETE_DEPLOY_STATUS=\"failed\"" >> ~/.bash_profile
    echo "export TESTFLIGHT_DEPLOY_STATUS=\"failed\"" >> ~/.bash_profile
    exit 1
  fi
fi

# App token
if [ ! ${HOCKEYAPP_TOKEN+x} ]; then
    echo "No App token found"
    echo "export CONCRETE_DEPLOY_STATUS=\"failed\"" >> ~/.bash_profile
    echo "export TESTFLIGHT_DEPLOY_STATUS=\"failed\"" >> ~/.bash_profile
    exit 1
fi

# App Id
if [ ! ${HOCKEYAPP_APP_ID+x} ]; then
    echo "No App Id found"
    echo "export CONCRETE_DEPLOY_STATUS=\"failed\"" >> ~/.bash_profile
    echo "export TESTFLIGHT_DEPLOY_STATUS=\"failed\"" >> ~/.bash_profile
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
  -H "X-HockeyAppToken: $HOCKEYAPP_OKEN" \
  https://rink.hockeyapp.net/api/2/apps/$HOCKEYAPP_APP_ID/app_versions/upload)

echo " --- Result ---"
echo "$json"
echo " --------------"

# error checking

prop='errors'
errors=`jsonval`

if [ ! ${errors+x} ]; then
  echo "export CONCRETE_DEPLOY_STATUS=\"success\"" >> ~/.bash_profile
  echo "export TESTFLIGHT_DEPLOY_STATUS=\"success\"" >> ~/.bash_profile

  prop='public_url'
  public_url=`jsonval`

  echo "export CONCRETE_DEPLOY_URL=\"$install_url\"" >> ~/.bash_profile
  echo "export TESTFLIGHT_DEPLOY_URL=\"$install_url\"" >> ~/.bash_profile

  echo "CONCRETE_DEPLOY_URL: \"$install_url\""
  echo "TESTFLIGHT_DEPLOY_URL: \"$install_url\""
else
  echo "export CONCRETE_DEPLOY_STATUS=\"failed\"" >> ~/.bash_profile
  echo "export TESTFLIGHT_DEPLOY_STATUS=\"failed\"" >> ~/.bash_profile
  exit 1
fi

exit 0
