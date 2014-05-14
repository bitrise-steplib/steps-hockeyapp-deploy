#!/bin/bash
# @Author: Tamas Szucs
# @Date:   2014-05-14 15:16:02
# @Last Modified by:   Tamas Szucs
# @Last Modified time: 2014-05-14 16:48:31

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

res=$(curl \
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
echo "$res"
echo " --------------"

$(echo "$res" | grep HTTP/ | awk {'print $2'} | tail -1)

exit 0