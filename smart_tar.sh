#!/bin/bash 

##########################
#  Author: Jake Robers   #
##########################

override=false
target=""
masks=()
destination=""

if [ "$#" -lt 1 ] ; then
  echo "Invalid parameter count." >&2
  echo "[ -r ] target mask1 [ mask2 ... ] destination" >&2
  exit 1
fi

case $1 in
  -v|--version)
    echo "0.01"
    exit 0
    ;;
  -h|--help)
    echo "[ -r ] target mask1 [ mask2 ... ] destination"
    exit 0
    ;;
  -r|--override)
    override=true
    shift
    ;;
esac


while [[ $# > 1 ]] ; do
  key=$1
  if [ "${target}" == "" ] ; then
    # Convert the relative url to absolute and store in destination
    if [ ${key:0:2} == "./" ] ; then
      key="${key#./}"
    fi

    if [ ${key:0:1} != "/" ] ; then
      key="$(pwd)/${key}"
    fi
    target="${key}"
  else
    masks+=("${key}")
  fi
  shift
done

# Convert the relative url to absolute and store in destination
key=${1}
if [ ${key:0:2} == "./" ] ; then
  key="${key#./}"
fi

if [ ${key:0:1} != "/" ] ; then
  key="$(pwd)/${key}"
fi

destination="${key}"

# Error checking
if [ "${#masks[@]}" == 0 ] ; then
  echo "Invalid parameter count." >&2
  echo "[ -r ] target mask1 [ mask2 ... ] destination" >&2
  exit 1
fi

if [ ! -d "${target}" ] ; then
  echo "Directory provided does not exist." >&2
  exit 1
fi

temp=$(mktemp)
exit_code=0

for mask in "${masks[@]}" ; do
  while read line ; do
    echo "${line#${target}/}" >> "${temp}"
  done < <(find -L "${target}" -type f -name "${mask}")
done

if [ -d $(dirname "${destination}") ] ; then
  if [ -f "${destination}" ] ; then
    if [ "${override}" = true ] ; then
      echo "Overwriting the existing archive..." >&2
      tar cfz "${destination}" -C "${target}" -T "${temp}"
    else
      echo "File already exists. Use -r to override." >&2
      exit_code=1
    fi
  else
    tar cfz "${destination}" -C "${target}" -T "${temp}"
  fi
else
  echo "Destination directory does not exist." >&2
  exit_code=1 
fi

rm "${temp}"
exit "${exit_code}"

