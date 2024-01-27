#!/usr/bin/env bash


export CONF_PROP_UTC_DATE=$(date --utc "+%F");	# 2024-01-25

export CONF_PROP_UTC_DATETIME=$(date --utc "+%F %T"); # 2024-01-25 18:13:23

export CONF_PROP_UTC_DATE_HUMAN=$(date --utc "+%b %d, %Y"); # Jan 25, 2024


if [[ ${BUILD_SOURCEBRANCHNAME:+1} ]] ; then
  export CONF_PROP_GIT_BRANCH="$BUILD_SOURCEBRANCHNAME";
else
  export CONF_PROP_GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD)";
fi

