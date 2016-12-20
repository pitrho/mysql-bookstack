#!/bin/bash

IMAGE_TAG="pitrho/mysql-bookstack"

# Custom die function.
die() { echo >&2 -e "\nRUN ERROR: $@\n"; exit 1; }

# Parse the command line flags.
while getopts "t:" opt; do
  case $opt in
    t)
      IMAGE_TAG=${OPTARG}
      ;;
    \?)
      die "Invalid option: -$OPTARG"
      ;;
  esac
done

# Create the build directory
rm -rf build
mkdir build

cp Dockerfile.tmpl build/Dockerfile

cp backup.sh backup_public.sh backup_recovery.sh enable_backups.sh build/

# build the container image
docker build -t="${IMAGE_TAG}" build/

# clean the build
rm -rf build
