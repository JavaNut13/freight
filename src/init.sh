#!/bin/bash

is_bare=$(git -C "$flags_working_dir" rev-parse --is-bare-repository)

if [ "$is_bare" != "true" ]; then
  fatal 2 "--working_dir ($flags_working_dir) is not a bare git repo"
fi

if [ -e "$flags_working_dir/hooks/post-receive" ]; then
  fatal 2 "post-receive hook already exists"
fi

read_d() {
  local prompt="$1"
  local default="$2"
  local var="$3"
  local value=""

  echo -n "$prompt [$default] "
  read value
  if [ -z "$value" ]; then
    value="$default"
  fi
  eval "$var='$value'"
}

expand() {
  flags_working_dir=$(readlink -f "$flags_working_dir")
}

write_hook() {
  # Expects variables:
  # freight_location
  # flags_working_dir
  # version_store

  local file="$flags_working_dir/hooks/post-receive"
  cat > "$file" <<-EOF
#!/bin/bash
set -e

THIS="$flags_working_dir"

tempdir=\$(mktemp -d)
git clone "\$THIS" "\$tempdir"

"$freight_location" upgrade "$version_store" "\$tempdir"
rm -rf "\$tempdir"
EOF
  chmod +x "$file"
  cecho GREEN "Hook written to $file"
}

freight_location="$(readlink -f $(dirname "$BASH_SOURCE"))/freight"
read_d "Location of the Freight script" "$freight_location" freight_location
read_d "Place to store container version info" "~/$(hostname)_freight_version" version_store

echo
cecho BLUE "Creating hook that will use freight at $freight_location"
cecho BLUE "Container info will be stored in $version_store"
echo
read_d "Is this correct? [y/n]" "n" confirm
if [ "$confirm" = "y" ]; then
  cecho PURPLE "Writing hook"
  write_hook
else
  cecho YELLOW "Not doing anything."
fi
