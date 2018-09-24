#!/usr/bin/env bash

[[ -n $VKV_CLIPBOARD ]] || VKV_CLIPBOARD=pbcopy

vkv() {
  if [[ $VKV_TRACE ]]; then
    set -x
  fi
  _vkv "$@"
  local retval=$?
  if [[ $VKV_TRACE ]]; then
    set +x
  fi
  return $retval
}

_vkv() {
  local prefix=$(_vkv_prefix)
  local path=$1
  if [[ -z $path ]]; then
    _vkv_err "Path required"
    return 1
  fi
  if [[ $2 = "" ]]; then
    _vkv_debug "getting $prefix/$path"
    _vkv_json $prefix/$path
  elif [[ $2 = "-d" ]]; then
    _vkv_debug "deleting $prefix/$path"
    vault kv delete $prefix/$path > /dev/null
  elif [[ $2 = "-p" ]]; then
    _vkv_debug "purging $prefix/$path"
    vault kv metadata delete $prefix/$path > /dev/null
  elif [[ $2 =~ = ]]; then
    local key=$(echo "$2" | cut -d = -f 1)
    local val=$(echo "$2" | cut -d = -f 2)
    if [[ $val = "-d" ]]; then
      _vkv_debug "deleting $prefix/$path#$key"
      _vkv_json $prefix/$path | jq -M "del(.$key)" | vault kv put $prefix/$path - > /dev/null || return 1
      [ ${PIPESTATUS[0]} -eq 0 ] || return 1
      _vkv_json $prefix/$path
    else
      if [[ $val = "-" ]]; then
        _vkv_debug "setting $prefix/$path#$key from stdin"
        val="$(</dev/stdin)"
        if [[ $val =~ '\n' ]]; then
          _vkv_debug "value had newline(s), replacing with \n"
          val="$(echo "$val" | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g')"
        fi
      fi
      _vkv_debug "setting $prefix/$path#$key to $val"
      local json=$(_vkv_json $prefix/$path 2> /dev/null)
      echo "$json" | jq -M ". | .$key = \"$val\"" | vault kv put $prefix/$path - > /dev/null || return 1
      [ ${PIPESTATUS[0]} -eq 0 ] || return 1
      _vkv_json $prefix/$path
    fi
  elif [[ $3 = '.' ]]; then
    _vkv_debug "copying $prefix/$path#$2"
    vault kv get --field=$2 $prefix/$path | $VKV_CLIPBOARD || return 1
    [ ${PIPESTATUS[0]} -eq 0 ] || return 1
    echo "Copied $2 to clipboard"
  else
    _vkv_debug "getting $prefix/$path#$2"
    vault kv get --field=$2 $prefix/$path
  fi
}

_vkv_json() {
  _vkv_debug "_vkv_json $1"
  local json="$(vault kv get -format=json $1 2> /dev/null)"
  if [[ -z $json ]]; then
    _vkv_err "No secret found at $1"
    echo "{}"
    return 1
  fi
  json="$(echo "$json" | jq -M 'if ( .data.metadata | length ) == 0 then .data else .data.data end')"
  if [[ $json = "null" ]]; then
    echo "{}"
  else
    echo "$json"
  fi
}

_vkv_prefix() {
  [[ -n $VKV_PREFIX ]] && echo $VKV_PREFIX || echo secret
}

_vkv_err() {
  echo >&2 "vkv: $1"
}

_vkv_debug() {
  [[ -n $VKV_DEBUG ]] && echo >&2 "> $1"
}

_vkv_paths() {
  local path=$1
  local prefix=$(_vkv_prefix)
  [[ $path =~ ^\. || $path = / ]] && path=""
  if [[ $path =~ /$ || $path = "" ]]; then
    vault kv list -format=json $prefix/$path | jq -r .[] | sed "s|^|$path|g" || return 1
    [ ${PIPESTATUS[0]} -eq 0 ] || return 1
    return
  fi
  _vkv_paths "$(dirname $path)/" || return 1
}

_vkv_keys() {
  local path=$1
  local prefix=$(_vkv_prefix)
  vault kv get -format=json $prefix/$path \
      | jq -M 'if ( .data.metadata | length ) == 0 then .data else .data.data end' \
      | grep -v '^[{}]' \
      | sed -e 's|^  "||' -e 's|": "| |' -e 's|"$||' -e 's|",$||' \
      | awk '{print $1}' || return 1
  [ ${PIPESTATUS[0]} -eq 0 ] || return 1
}

_vkv_completion() {
  if [[ $COMP_CWORD -lt 3 ]]; then
    local word=${COMP_WORDS[$COMP_CWORD]}
    if [[ $COMP_CWORD -lt 2 ]]; then
      local choices=$(_vkv_paths "$word") || return 1
    elif [[ $COMP_CWORD -eq 2 ]]; then
      local choices=$(_vkv_keys "${COMP_WORDS[1]}") || return 1
    fi
    local suggestions=($(compgen -W "$choices" -- $word))
    for i in "${!suggestions[@]}"; do
      local value="${suggestions[$i]}"
      if ! [[ $value =~ /$ ]]; then
        suggestions[$i]="$value "
      fi
    done
    COMPREPLY=("${suggestions[@]}")
  fi
}

complete -o nospace -F _vkv_completion vkv
