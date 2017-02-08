#!/bin/bash

vercomp () {
  if [[ $1 == $2 ]]
  then
    return 0
  fi
  local IFS=.
  local i ver1=($1) ver2=($2)
  # fill empty fields in ver1 with zeros
  for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
  do
    ver1[i]=0
  done
  for ((i=0; i<${#ver1[@]}; i++))
  do
    if [[ -z ${ver2[i]} ]]
    then
      # fill empty fields in ver2 with zeros
      ver2[i]=0
    fi
    if ((10#${ver1[i]} > 10#${ver2[i]}))
    then
      return 1
    fi
    if ((10#${ver1[i]} < 10#${ver2[i]}))
    then
      return 2
    fi
  done
  return 0
}

ver_gt() {
  vercomp "$1" "$2"
  [ $? -eq 1 ]
}


parse_flags() {
  local key=""
  local value=""
  args=()
  for flag in $@; do
    if [ ${flag:0:2} = "--" ]; then
      IFS="=" read -r key value <<< "${flag:2}"
      [ -z "$value" ] && value="true"
      eval "flags_$key=\"$value\""
    else
      args+=("$flag")
    fi
  done
}

fatal() {
  local status=$1
  shift
  cecho RED $@
  exit $status
}

dry() {
  if [ $# -eq 0 ]; then
    [ -z "$flags_dry_run" ]
  else
    if [ -z "$flags_dry_run" ]; then
      eval $@
    else
      echo "> $@"
    fi
  fi
}


