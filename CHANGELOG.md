## Changelog (Current version: 2.4.1)

-----------------

### 2.4.1 (2017 Jul 03)

* [2c9161a] prepare for 2.4.1
* [9d51796] do not require ipa path
* [5e70587] test for only ipa and only dsym uploads (#25)
* [541f4f5] make .ipa input optional when .dSYM is specified (#24)

### 2.4.0 (2017 Jan 05)

* [aa1b4ac] prepare for 2.4.0
* [9619cc8] Retry (#22)

### 2.3.0 (2016 Feb 18)

* [2bf1d2f] dSYM input title change - make it clear that its optional now
* [bbd12f5] Merge pull request #18 from godrei/optional_dsym
* [d6a55cf] dsym zip as input
* [fb54b10] make dsym input optional

### 2.2.2 (2016 Feb 15)

* [4f33828] Merge pull request #17 from godrei/mandatory_fix
* [6809b1b] print inputs before validate, mandatory backwared compatibility

### 2.2.1 (2016 Feb 12)

* [0a1c58a] Merge pull request #16 from godrei/file_exist
* [a27f8ea] bitrise yml fix
* [750574e] check if ipa and dsym path files exist
* [1b9a24b] Merge pull request #12 from godrei/multiline_notes
* [bf468fb] secret api_token
* [b939903] step.go, some cleanup
* [3087190] step.yml : `run_if` set to ".IsCI"

### 2.2.0 (2015 Dec 15)

* [d12dda4] bitrise.yml update
* [6c7f9e0] HockeyApp: App ID - revision on the input text
* [868239d] more info about the path if "No IPA found to deploy"
* [7d9cfac] bitrise.yml format version upgrade
* [2196b39] step.yml : ouputs cleanup
* [815281b] project type tag : lowercase
* [a7b4858] Merge branch 'master' of github.com:bitrise-io/steps-hockeyapp-deploy
* [bb2502f] Merge pull request #10 from godrei/update
* [0d68571] added 'ios' project type flag
* [cc83fa2] log fix
* [443f479] step updates

### 2.1.1 (2015 Oct 11)

* [8abcf33] Fix for input handling where the input had a hardcoded default value before the V2 revisions
* [a2a64d6] Merge pull request #9 from bazscsa/patch-1
* [884bf7b] Update step.yml

### 2.1.0 (2015 Sep 11)

* [c323e73] Merge pull request #8 from gkiki90/update
* [79afa9a] merge

### 2.0.0 (2015 Sep 08)

* [15522d7] bitrise stack related update
* [b39fa6d] Merge pull request #7 from gkiki90/update
* [09fc246] PR fix
* [1d7d0a6] fix
* [560847f] update
* [d492fdb] stepYML input title changes

### 1.3.0 (2015 Feb 16)

* [7679436] dsym not found info text format change
* [547b447] dSYM is required - HockeyApp API doesn't seem to accept the app IPA if no dSYM is available
* [986d3db] test
* [bc31dc0] debug and test
* [be1d07f] debug
* [a9461fe] stepYML : guide where to get API token and App ID
* [bfde80f] dSYM is optional - handling changed accordingly; space to tab conversion

### 1.2.0 (2015 Jan 16)

* [ddd07cd] build direct download url text fix
* [b0395cd] success output formatting fixes
* [9aeddf7] default value handling [fix]; styling fix; step.YML update (major)
* [8086580] added the two missing Bitrise related input ENVs https://github.com/bitrise-io/step-hockeyapp-deploy/issues/4

### 1.1.0 (2015 Jan 03)

* [04f5408] error logging quotation mark fix
* [97c2238] logging style change
* [2c4d833] success logging style change
* [e0d9ee0] last logging section fix
* [734b5ec] a bit more code, error handling and logging revision
* [6df303c] base improvements / revisions : the step now uses the new _utils and _formatted_output bash script utils; step.yml updated; step.sh code style update
* [7e82a10] Merge pull request #6 from tomfurrier/master
* [e4cc07f] Merge pull request #5 from erosdome/master
* [c98b4f8] Update step.yml
* [74c3b27] Update step.yml
* [fcbdb8b] Update README.md
* [50ba23b] removed unnecessary header
* [d911a39] incorrect dependency path fix

-----------------

Updated: 2017 Jul 03