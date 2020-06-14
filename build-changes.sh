#!/bin/bash
set -e

if [ "$INPUT_WORK_DIRECTORY" = "" ]; then
  echo "INPUT_WORK_DIRECTORY environment variable not set"
  exit 1
fi

if [ "$INPUT_SHA" = "" ]; then
  echo "INPUT_SHA environment variable not set"
  exit 1
fi

echo "$INPUT_PRIVATE_KEY" > /home/abuild/.abuild/buildkey.rsa
echo "$INPUT_PUBLIC_KEY" > /home/abuild/.abuild/buildkey.rsa.pub
chown abuild:abuild /home/abuild/.abuild/buildkey.rsa /home/abuild/.abuild/buildkey.rsa.pub
chmod 600 /home/abuild/.abuild/buildkey.rsa /home/abuild/.abuild/buildkey.rsa.pub

cd "$INPUT_WORK_DIRECTORY/packages"

base=$(git merge-base remotes/origin/master HEAD)
files=$(git diff --name-only "$base" "$INPUT_SHA" | cut -d'/' -f 2 | uniq)

for package_path in $files; do
  if [ -d "$package_path" ]; then
    echo "Building package directory $package_path"
    chown -R abuild:abuild "$package_path"

    pushd "$package_path"
      su-exec abuild abuild checksum
      su-exec abuild abuild -r
    popd
  fi
done
