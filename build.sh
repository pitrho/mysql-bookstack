#!/bin/bash

MYSQL_VERSION="5.6"
IMAGE_TAG="pitrho/mysql-bookstack"

# Custom die function.
#
die() { echo >&2 -e "\nRUN ERROR: $@\n"; exit 1; }

# Parse the command line flags.
#
while getopts "v:t:" opt; do
  case $opt in
    t)
      IMAGE_TAG=${OPTARG}
      ;;

    v)
      MYSQL_VERSION=${OPTARG}
      ;;

    \?)
      die "Invalid option: -$OPTARG"
      ;;
  esac
done

[ $MYSQL_VERSION != "5.5" -a $MYSQL_VERSION != "5.6" ] && ( echo "Only MySQL 5.5 and 5.6 are supported." && exit 1; )

# Crete the build directory
rm -rf build
mkdir build

cp backup/* build/
cp service/* build/

# Copy docker file, and override the MYSQL_VERSION string
sed 's/%%MYSQL_VERSION%%/'"$MYSQL_VERSION"'/g' Dockerfile.tmpl > build/Dockerfile

docker build -t="${IMAGE_TAG}" build/

rm -rf build
