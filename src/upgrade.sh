#!/bin/bash

[ ! -z "$flags_dry_run" ] && echo "DRY RUN"

current_versions="${args[0]}"
if [ -z "$current_versions" ]; then
  fatal 1 "Current versions file must be given"
fi

if [ -e "$current_versions" ]; then
  echo "Reading old version info from $current_versions"
  source "$current_versions"
  dry mv "$current_versions" "$current_versions-old"
fi
dry echo -n '' > "$current_versions"

function upgrade_app() {
  local tmp_path=$(mktemp -d)
  # Clone the repo to a temp location
  dry git clone "$url" "$tmp_path"
  dry git --git-dir "$tmp_path/.git" checkout "tags/$version"

  # Build a tagged image for the repo
  cecho CYAN "Building image for $app_name"
  dry docker build -t "$app_name:$version" "$tmp_path"
  if ! dry; then
    # Stop the running container
    container=$(docker ps | grep "$app_name" | cut -d' ' -f1 | xargs)
    if [ -z "$container" ]; then
      cecho LIGHT_BLUE "No running containers for image $app_name"
    else
      cecho CYAN "Stopping container $container"
      docker stop $container
    fi
  fi
  # Start the new container
  dry docker run ${run_flags[@]} -d "$app_name:$version"
  cecho GREEN "$app_name started"
  rm -rf "$tmp_path"
}

function flag() {
  local key="$1"
  local value="$2"
  run_flags+=("-$key=$value")
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
  run_flags=()
}

run_flags=()
for src_file in ${args[@]:1}; do
  cecho LIGHT_BLUE "Loading $src_file"
  [ ! -e "$src_file" ] && fatal 2 "File does not exist or is folder: $src_file"
  if [ -d "$src_file" ]; then
    for src in $src_file/*; do
      source $src
    done
  else
    source "$src_file"
  fi
done
