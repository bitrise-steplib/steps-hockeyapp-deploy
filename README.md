step-hockeyapp-deploy
=====================

Bitrise step to deploy an iOS application to HockeyApp. You need to register on HockeyApp's website http://hockeyapp.net/features/ and create an app to utilize this step. You also need to create a HockeyApp Token for your app. It will be used to authenticate you.

This step depends on the Archive Step.

Description of HockeyApp specific variables available at: http://support.hockeyapp.net/kb/api/api-versions#-u-post-api-2-apps-app_id-app_versions-upload-u-

To run the tests for this step it is important to execute them from the root directory of the step (example usage: ./tests/step_test.sh)

# Input Environment Variables 
- BITRISE_IPA_PATH			(passed automatically)
- BITRISE_DSYM_PATH			(passed automatically)
- .
- HOCKEYAPP_TOKEN
- HOCKEYAPP_APP_ID
- HOCKEYAPP_NOTES			(optional, default = "Automatic build with Bitrise.")
- HOCKEYAPP_NOTES_TYPE		(optional, default = 0 - Textile)
- HOCKEYAPP_NOTIFY			(optional, default = 2 - Notify all testers)
- HOCKEYAPP_STATUS			(optional, default = 2 - Available for download or installation)
- HOCKEYAPP_MANDATORY		(optional, default = 0 - not mandatory)
- HOCKEYAPP_TAGS			(optional)
- HOCKEYAPP_COMMIT_SHA		(optional)
- HOCKEYAPP_BUILD_SERVER_URL(optional)
- HOCKEYAPP_REPOSITORY_URL	(optional)

# Output Environment Variables
- HOCKEYAPP_DEPLOY_STATUS	[success/failed]
- HOCKEYAPP_DEPLOY_PUBLIC_URL
- HOCKEYAPP_DEPLOY_BUILD_URL
- HOCKEYAPP_DEPLOY_CONFIG_URL
