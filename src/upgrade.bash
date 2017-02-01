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

# Actual script bit

current_versions="$1"

if [ -e "$current_versions" ]; then
  echo "Reading old version info from $current_versions"
  source "$current_versions"
  mv "$current_versions" "$current_versions-old"
fi
echo -n '' > "$current_versions"

function upgrade_app() {
  local tmp_path=$(mktemp -d)
  git clone $url $tmp_path
  git -C $tmp_path checkout tags/$version 2> /dev/null
  docker build -t $app_name:$version $tmp_path
  container=$(docker ps | grep "$app_name" | cut -d' ' -f1 | xargs)
  if [ -z "$container" ]; then
    echo "No running containers for image $app_name"
  else
    docker stop $container
  fi
  docker run -d $app_name:$version
  rm -rf $tmp_path
}

function app() {
  app_name="$1"
  eval $app_name
  [ -z "$url" ] && echo "ERROR: url is blank" && exit 1
  [ -z "$version" ] && echo "ERROR: version is blank" && exit 1
  old_version=$(eval "echo \$version_$app_name")
  [ -z "$old_version" ] && old_version=0.0.0
  if ver_gt $version $old_version; then
    echo "Updating $app_name from $old_version to $version"
    upgrade_app
  else
    echo "$app_name up to date ($version)"
  fi
  echo "version_$app_name=$version" >> "$current_versions"
  url=""
  version=""
  app_name=""
}

shift 1
for src_file in $@; do
  echo "Loading $src_file"
  source $src_file
done
