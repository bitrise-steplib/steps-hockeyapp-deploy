#!/bin/bash

THIS_SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${THIS_SCRIPTDIR}/_utils.sh"
source "${THIS_SCRIPTDIR}/_formatted_output.sh"

function echoStatusFailed {
  echo 'export deploy_status="failed"' >> ~/.bash_profile
  echo
  echo 'deploy_status: "failed"'
  echo " --------------"
}

function CLEANUP_ON_ERROR_FN {
  write_section_to_formatted_output "# Error"
  echo_string_to_formatted_output "See the logs for more details"
}

# init / cleanup the formatted output
echo "" > "${formatted_output_file_path}"


# default values

notes=""
if [ ! -z "${notes}" ] ; then
	notes="${notes}"
fi

notes_type=0
if [ ! -z "${notes_type}" ] ; then
	notes_type="${notes_type}"
fi

notify=2
if [ ! -z "${notify}" ] ; then
	notify="${notify}"
fi

status=2
if [ ! -z "${status}" ] ; then
	status="${status}"
fi

# mandatory handling, with backward compatibility
#  0 - not mandatory (default)
#  1 - mandatory
mandatory=0
if [ ! -z "${mandatory}" ] ; then
  if [[ "${mandatory}" == "1" || "${mandatory}" == "true" ]] ; then
	mandatory=1
  fi
fi

echo
echo "ipa_path: ${ipa_path}"
echo "dsym_path: ${dsym_path}"
echo "token: ${token}"
echo "app_id: ${app_id}"
echo "notes: ${notes}"
echo "notes_type: ${notes_type}"
echo "notify: ${notify}"
echo "status: ${status}"
echo "mandatory: ${mandatory}"
echo "tags: ${tags}"
echo "commit_sha: ${commit_sha}"
echo "build_server_url: ${build_server_url}"
echo "repository_url: ${repository_url}"
echo


# IPA
if [ ! -f "${ipa_path}" ] ; then
	write_section_to_formatted_output "# Error"
	write_section_start_to_formatted_output '* No IPA found to deploy.'
	echoStatusFailed
	exit 1
fi

# dSYM
if [[ -z "${dsym_path}" || ! -f "${dsym_path}" ]] ; then
	write_section_to_formatted_output "# Error"
	write_section_start_to_formatted_output '* DSYM file not found to deploy. To generate debug symbols (dSYM) go to your Xcode Project Settings - `Build Settings - Debug Information Format` and set it to **DWARF with dSYM File**.'
	echoStatusFailed
	exit 1
fi


# App token
if [ -z "${token}" ] ; then
	write_section_to_formatted_output "# Error"
	write_section_start_to_formatted_output '* No App token provided as environment variable. Terminating...'
	echoStatusFailed
	exit 1
fi

# App Id
if [ -z "${app_id}" ] ; then
	write_section_to_formatted_output "# Error"
	write_section_start_to_formatted_output '* No App Id provided as environment variable. Terminating...'
	echoStatusFailed
	exit 1
fi

###########################

json=$(curl --fail \
  -F "ipa=@${ipa_path}" \
  -F "dsym=@${dsym_path}" \
  -F "notes=${notes}" \
  -F "notes_type=${notes_type}" \
  -F "notify=${notify}" \
  -F "status=${status}" \
  -F "mandatory=${mandatory}" \
  -F "tags=${tags}" \
  -F "commit_sha=${commit_sha}" \
  -F "build_server_url=${build_server_url}" \
  -F "repository_url=${repository_url}" \
  -H "X-HockeyAppToken: ${token}" \
  https://rink.hockeyapp.net/api/2/apps/${app_id}/app_versions/upload)
curl_res=$?

echo
echo " --- Result ---"
echo " * cURL command exit code: ${curl_res}"
echo " * response JSON: ${json}"
echo " --------------"
echo

if [ ${curl_res} -ne 0 ] ; then
  write_section_to_formatted_output "# Error"
  write_section_start_to_formatted_output '* cURL command exit code not zero!'
  echoStatusFailed
  exit 1
fi

# error handling
if [[ ${json} ]] ; then
  errors=`ruby ./steps-utils-jsonval/parse_json.rb \
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
  write_section_to_formatted_output "# Error"
  write_section_start_to_formatted_output "* ${errors}"
  echoStatusFailed
  exit 1
fi

# everything is OK

export deploy_status="success"
echo 'export deploy_status="success"' >> ~/.bash_profile

# public url
public_url=`ruby ./steps-utils-jsonval/parse_json.rb \
  --json-string="$json" \
  --prop=public_url`

echo "export deploy_public_url=\"${public_url}\"" >> ~/.bash_profile

# build url
build_url=`ruby ./steps-utils-jsonval/parse_json.rb \
  --json-string="$json" \
  --prop=build_url`

echo "export deploy_build_url=\"${build_url}\"" >> ~/.bash_profile

# config url
config_url=`ruby ./steps-utils-jsonval/parse_json.rb \
  --json-string="$json" \
  --prop=config_url`

echo "export deploy_config_url=\"${config_url}\"" >> ~/.bash_profile


# final results
write_section_to_formatted_output "# Success"
write_section_to_formatted_output "## Generated Outputs"
echo_string_to_formatted_output "* Deploy Result: **${deploy_status}**"
if [ -z "${public_url}" ] ; then
  public_url='(empty/none)'
else
  public_url="[${public_url}](${public_url})"
fi
echo_string_to_formatted_output "* Public URL: **${public_url}**"
if [ -z "${build_url}" ] ; then
  build_url='(empty/none)'
else
  build_url="[${build_url}](${build_url})"
fi
echo_string_to_formatted_output "* Build (direct download) URL: **${build_url}**"
if [ -z "${config_url}" ] ; then
  config_url='(empty/none)'
else
  config_url="[${config_url}](${config_url})"
fi
echo_string_to_formatted_output "* Config URL: **${config_url}**"

exit 0
