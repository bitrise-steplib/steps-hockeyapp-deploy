#!/bin/bash

#
# Run it from the directory which contains step.sh
#


# ------------------------
# --- Helper functions ---

function print_and_do_command {
  echo "$ $@"
  $@
}

function inspect_test_result {
  if [ $1 -eq 0 ]; then
    test_results_success_count=$[test_results_success_count + 1]
  else
    test_results_error_count=$[test_results_error_count + 1]
  fi
}

#
# First param is the expect message, other are the command which will be executed.
#
function expect_success {
  expect_msg=$1
  shift

  echo " -> $expect_msg"
  $@
  cmd_res=$?

  if [ $cmd_res -eq 0 ]; then
    echo " [OK] Expected zero return code, got: 0"
  else
    echo " [ERROR] Expected zero return code, got: $cmd_res"
    exit 1
  fi
}

#
# First param is the expect message, other are the command which will be executed.
#
function expect_error {
  expect_msg=$1
  shift

  echo " -> $expect_msg"
  $@
  cmd_res=$?

  if [ ! $cmd_res -eq 0 ]; then
    echo " [OK] Expected non-zero return code, got: $cmd_res"
  else
    echo " [ERROR] Expected non-zero return code, got: 0"
    exit 1
  fi
}

function is_dir_exist {
  if [ -d "$1" ]; then
    return 0
  else
    return 1
  fi
}

function is_file_exist {
  if [ -f "$1" ]; then
    return 0
  else
    return 1
  fi
}

function is_not_empty {
  if [[ $1 ]]; then
    return 0
  else
    return 1
  fi
}

function test_cleanup {
  unset HOCKEYAPP_APP_ID
  unset HOCKEYAPP_TOKEN
  unset CONCRETE_IPA_PATH
}

function print_new_test {
  echo
  echo "[TEST]"
}

# -----------------
# --- Run tests ---

function run_target_command { 
  print_and_do_command eval "CONCRETE_IPA_PATH=$test_ipa_path ./step.sh"
}

echo "Starting tests..."

test_ipa_path="tests/testfile.ipa"
test_results_success_count=0
test_results_error_count=0

# [TEST] Call the command with the minimum required parameters given, 
# it should execute, but curl should return with authentication error
# 
(
  print_new_test

  # Set env vars
  HOCKEYAPP_TOKEN="asd1234"
  HOCKEYAPP_APP_ID="dsa4321"

  # Create test file
  print_and_do_command echo 'test file content' > "$test_ipa_path"

  # The file should exist
  expect_success "File $test_ipa_path should exist" is_file_exist "$test_ipa_path"

  # Both HOCKEYAPP_TOKEN and HOCKEYAPP_APP_ID should exist
  expect_success "HOCKEYAPP_TOKEN environment variable should be set" is_not_empty "$HOCKEYAPP_TOKEN"
  expect_success "HOCKEYAPP_APP_ID environment variable should be set" is_not_empty "$HOCKEYAPP_APP_ID"

  # Deploy the file
  expect_error "The command should be called, but should not complete sucessfully" run_target_command

  test_cleanup
)
test_result=$?
inspect_test_result $test_result


# [TEST] Call the command with HOCKEYAPP_TOKEN not set, 
# it should raise an error message and exit
# 
(
  print_new_test

  # Set env var
  HOCKEYAPP_APP_ID="dsa4321"

  # Create test file
  print_and_do_command echo 'test file content' > "$test_ipa_path"

  # The file should exist
  expect_success "File $test_ipa_path should exist" is_file_exist "$test_ipa_path"

  # HOCKEYAPP_TOKEN should NOT exist
  expect_error "HOCKEYAPP_TOKEN environment variable should NOT be set" is_not_empty "$HOCKEYAPP_TOKEN"
  expect_success "HOCKEYAPP_APP_ID environment variable should be set" is_not_empty "$HOCKEYAPP_APP_ID"

  # Deploy the file
  expect_error "The command should be called, but should not complete sucessfully" run_target_command

  test_cleanup
)
test_result=$?
inspect_test_result $test_result

# [TEST] Call the command with HOCKEYAPP_APP_ID not set, 
# it should raise an error message and exit
# 
(
  print_new_test

  # Set env vars
  HOCKEYAPP_TOKEN="asd1234"

  # Create test file
  print_and_do_command echo 'test file content' > "$test_ipa_path"

  # The file should exist
  expect_success "File $test_ipa_path should exist" is_file_exist "$test_ipa_path"

  # HOCKEYAPP_APP_ID should NOT exist
  expect_error "HOCKEYAPP_APP_ID environment variable should NOT be set" is_not_empty "$HOCKEYAPP_APP_ID"
  expect_success "HOCKEYAPP_TOKEN environment variable should be set" is_not_empty "$HOCKEYAPP_TOKEN"

  # Deploy the file
  expect_error "The command should be called, but should not complete sucessfully" run_target_command

  test_cleanup
)
test_result=$?
inspect_test_result $test_result

# [TEST] Call the command with HOCKEYAPP_APP_ID and HOCKEYAPP_TOKEN NOT set, 
# it should raise an error message and exit
# 
(
  print_new_test

  # Create test file
  print_and_do_command echo 'test file content' > "$test_ipa_path"

  # The file should exist
  expect_success "File $test_ipa_path should exist" is_file_exist "$test_ipa_path"

  # HOCKEYAPP_APP_ID and HOCKEYAPP_TOKEN should NOT exist
  expect_error "HOCKEYAPP_APP_ID environment variable should NOT be set" is_not_empty "$HOCKEYAPP_APP_ID"
  expect_error "HOCKEYAPP_TOKEN environment variable should NOT be set" is_not_empty "$HOCKEYAPP_TOKEN"

  # Deploy the file
  expect_error "The command should be called, but should not complete sucessfully" run_target_command

  test_cleanup
)
test_result=$?
inspect_test_result $test_result

# --------------------
# --- Test Results ---

echo
echo "--- Results ---"
echo " * Errors: $test_results_error_count"
echo " * Success: $test_results_success_count"
echo "---------------"

if [ $test_results_error_count -eq 0 ]; then
  echo "-> SUCCESS"
else
  echo "-> FAILED"
fi