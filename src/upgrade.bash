#!/bin/bash

set -e

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
  echo $@
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

# Actual script bit

parse_flags $@

[ ! -z "$flags_dry_run" ] && echo "DRY RUN"

current_versions="${args[0]}"
dry && fatal 1 "Current versions file must be given"

if [ -e "$current_versions" ]; then
  echo "Reading old version info from $current_versions"
  source "$current_versions"
  dry mv "$current_versions" "$current_versions-old"
fi
dry echo -n '' > "$current_versions"

function upgrade_app() {
  local tmp_path=$(mktemp -d)
  dry git clone $url $tmp_path
  dry git -C $tmp_path checkout tags/$version 2> /dev/null
  dry docker build -t $app_name:$version $tmp_path
  if ! dry; then
    container=$(docker ps | grep "$app_name" | cut -d' ' -f1 | xargs)
    if [ -z "$container" ]; then
      echo "No running containers for image $app_name"
    else
      docker stop $container
    fi
  fi
  dry docker run -d $app_name:$version
  rm -rf $tmp_path
}

function app() {
  eval "$1"
  app_name=${1//-/_}
  [ -z "$url" ] && fatal 1 "ERROR: url is blank"
  [ -z "$version" ] && fatal 1 "ERROR: version is blank"
  old_version=$(eval "echo \$version_$app_name")
  [ -z "$old_version" ] && old_version=0.0.0
  if ver_gt $version $old_version; then
    echo "Updating $app_name from $old_version to $version"
    upgrade_app
  else
    echo "$app_name up to date ($version)"
  fi
  dry echo "version_$app_name=$version" >> "$current_versions"
  url=""
  version=""
  app_name=""
}

for src_file in ${args[@]:1}; do
  echo "Loading $src_file"
  source $src_file
done
