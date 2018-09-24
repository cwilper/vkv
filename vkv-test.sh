#!/usr/bin/env bash

. vkv.sh

VKV_PREFIX=secret
#VKV_DEBUG=1
#VKV_TRACE=1

testpath=path/of/some-secret

if [[ -e /usr/local/bin/vault ]]; then
  echo "Redefining vault"
  vault() {
    /usr/local/bin/vault "$@"
  }
fi

main() {
  echo "--[ Started tests at $(date)"

  # vkv path/of/some-secret                    # gets all key-value pairs of a secret as json
  test_get_secret

  # vkv path/of/some-secret -d                 # deletes a secret
  test_delete_secret

  # vkv path/of/some-secret -p                 # purges a secret
  test_purge_secret

  # vkv path/of/some-secret some_key           # prints the value of an existing key in a secret
  test_get_value

  # vkv path/of/some-secret some_key .         # copies the value to the system clipboard
  test_get_value_to_clipboard

  # vkv path/of/some-secret some_key=-d        # deletes the value
  test_delete_value

  # vkv path/of/some-secret some_key=some-val  # sets the value
  test_set_via_arg

  # vkv path/of/some-secret some_key=-         # sets the value from stdin
  test_set_via_stdin
  test_set_via_stdin_with_newlines

  echo "--[ Finished tests at $(date)"
}

start_test() {
  vault kv metadata delete $VKV_PREFIX/$testpath > /dev/null 2>&1
  echo "--[ Running $1"
}

test_get_secret() {
  start_test ${FUNCNAME[0]}
  vkv $testpath some_key="some-val" > /dev/null 2>&1
  local expected='{"some_key":"some-val"}'
  local result=$(vkv $testpath | jq . -cM)
  assert_status $? 0
  assert_string "$result" "$expected"
}

test_delete_secret() {
  start_test ${FUNCNAME[0]}
}

test_purge_secret() {
  start_test ${FUNCNAME[0]}
}

test_get_value() {
  start_test ${FUNCNAME[0]}
}

test_get_value_to_clipboard() {
  start_test ${FUNCNAME[0]}
}

test_delete_value() {
  start_test ${FUNCNAME[0]}
}

test_set_via_arg() {
  start_test ${FUNCNAME[0]}
  local result=$(vkv $testpath some_key="Set via arg value" | jq . -cM)
  local expected='{"some_key":"Set via arg value"}'
  assert_string "$result" "$expected"
  result=$(vkv $testpath | jq . -cM)
  assert_string "$result" "$expected"
}

test_set_via_stdin() {
  start_test ${FUNCNAME[0]}
  local result=$(echo "Set via stdin value" | vkv $testpath some_key=- | jq . -cM)
  local expected='{"some_key":"Set via stdin value"}'
  assert_string "$result" "$expected"
  result=$(vkv $testpath | jq . -cM)
  assert_string "$result" "$expected"
}

test_set_via_stdin_with_newlines() {
  start_test ${FUNCNAME[0]}
  local input=$(cat <<EOF
This
has
newlines
EOF
)
  local result=$(echo "$input" | vkv $testpath some_key=- | jq . -cM)
  local expected='{"some_key":"This\nhas\nnewlines"}'
  assert_string "$result" "$expected"
  result=$(vkv $testpath | jq . -cM)
  assert_string "$result" "$expected"
}

assert_status() {
  if [[ $1 -ne $2 ]]; then
    echo "Error: Expected status $2, got $1"
    exit 1
  fi
  echo "Got expected status: $2"
}

assert_string() {
  if ! [[ "$1" = "$2" ]]; then
    echo "Error: Expected string '$2', got '$1'"
    exit 1
  fi
  echo "Got expected string: $2"
}

main

