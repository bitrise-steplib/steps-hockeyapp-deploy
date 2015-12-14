#!/bin/bash

THIS_SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function echoStatusFailed {
  envman add --key HOCKEYAPP_DEPLOY_STATUS --value "failed"
  echo
  echo 'HOCKEYAPP_DEPLOY_STATUS: "failed"'
  echo " --------------"
}


# mandatory handling, with backward compatibility
#  0 - not mandatory (default)
#  1 - mandatory
if [[ "${mandatory}" == "1" || "${mandatory}" == "true" ]] ; then
  mandatory=1
else
  mandatory=0
fi


# IPA
if [ ! -f "${ipa_path}" ] ; then
  echo "# Error"
  echo '* No IPA found to deploy.'
  echoStatusFailed
  exit 1
fi

# dSYM
if [[ -z "${dsym_path}" || ! -f "${dsym_path}" ]] ; then
	echo "# Error"
	echo '* DSYM file not found to deploy. To generate debug symbols (dSYM) go to your Xcode Project Settings - `Build Settings - Debug Information Format` and set it to **DWARF with dSYM File**.'
	echoStatusFailed
	exit 1
fi

# App api_token
if [ -z "${api_token}" ] ; then
  echo "# Error"
  echo '* No App api_token provided as environment variable. Terminating...'
  echoStatusFailed
  exit 1
fi

echo
echo "========== Configs =========="
echo "* ipa_path: ${ipa_path}"
echo "* dsym_path: ${dsym_path}"
echo "* api_token: ***"
echo "* app_id: ${app_id}"
echo "* notes: ${notes}"
echo "* notes_type: ${notes_type}"
echo "* notify: ${notify}"
echo "* status: ${status}"
echo "* mandatory: ${mandatory}"
echo "* tags: ${tags}"
echo "* commit_sha: ${commit_sha}"
echo "* build_server_url: ${build_server_url}"
echo "* repository_url: ${repository_url}"
echo

###########################

curl_cmd="curl --fail"
curl_cmd="$curl_cmd -F \"ipa=@${ipa_path}\""
curl_cmd="$curl_cmd -F \"dsym=@${dsym_path}\""
curl_cmd="$curl_cmd -F \"notes=${notes}\""
curl_cmd="$curl_cmd -F \"notes_type=${notes_type}\""
curl_cmd="$curl_cmd -F \"notify=${notify}\""
curl_cmd="$curl_cmd -F \"status=${status}\""
curl_cmd="$curl_cmd -F \"mandatory=${mandatory}\""
curl_cmd="$curl_cmd -F \"tags=${tags}\""
curl_cmd="$curl_cmd -F \"commit_sha=${commit_sha}\""
curl_cmd="$curl_cmd -F \"build_server_url=${build_server_url}\""
curl_cmd="$curl_cmd -F \"repository_url=${repository_url}\""
curl_cmd="$curl_cmd -H \"X-HockeyAppToken: ${api_token}\""
if [ -z "${app_id}" ] ; then
  curl_cmd="$curl_cmd https://rink.hockeyapp.net/api/2/apps/upload"
else
  curl_cmd="$curl_cmd https://rink.hockeyapp.net/api/2/apps/${app_id}/app_versions/upload"
fi

echo
echo "=> Curl:"
echo '$' $curl_cmd
echo

json=$(eval $curl_cmd)
curl_res=$?

echo
echo " --- Result ---"
echo " * cURL command exit code: ${curl_res}"
echo " * response JSON: ${json}"
echo " --------------"
echo

if [ ${curl_res} -ne 0 ] ; then
  echo "# Error"
  echo '* cURL command exit code not zero!'
  echoStatusFailed
  exit 1
fi

# error handling
if [[ ${json} ]] ; then
  errors=`ruby "${THIS_SCRIPTDIR}/steps-utils-jsonval/parse_json.rb" \
  --json-string="${json}" \
  --prop=errors`
  parse_res=$?
  if [ ${parse_res} -ne 0 ] ; then
     errors="Failed to parse the response JSON"
  fi
else
  errors="No valid JSON result from request."
fi

if [[ ${errors} ]]; then
  echo "# Error"
  echo "* ${errors}"
  echoStatusFailed
  exit 1
fi

# everything is OK

envman add --key "HOCKEYAPP_DEPLOY_STATUS" --value "success"

# public url
public_url=`ruby "${THIS_SCRIPTDIR}/steps-utils-jsonval/parse_json.rb" \
  --json-string="$json" \
  --prop=public_url`

envman add --key "HOCKEYAPP_DEPLOY_PUBLIC_URL" --value "${public_url}"


# build url
build_url=`ruby "${THIS_SCRIPTDIR}/steps-utils-jsonval/parse_json.rb" \
  --json-string="$json" \
  --prop=build_url`

envman add --key "HOCKEYAPP_DEPLOY_BUILD_URL" --value "${build_url}"

# config url
config_url=`ruby "${THIS_SCRIPTDIR}/steps-utils-jsonval/parse_json.rb" \
  --json-string="$json" \
  --prop=config_url`

envman add --key "HOCKEYAPP_DEPLOY_CONFIG_URL" --value "${config_url}"


# final results
echo "# Success"
echo "## Generated Outputs"
echo "* Deploy Result: **success**"
if [ -z "${public_url}" ] ; then
  public_url='(empty/none)'
else
  public_url="[${public_url}](${public_url})"
fi
echo "* Public URL: **${public_url}**"
if [ -z "${build_url}" ] ; then
  build_url='(empty/none)'
else
  build_url="[${build_url}](${build_url})"
fi
echo "* Build (direct download) URL: **${build_url}**"
if [ -z "${config_url}" ] ; then
  config_url='(empty/none)'
else
  config_url="[${config_url}](${config_url})"
fi
echo "* Config URL: **${config_url}**"

exit 0
