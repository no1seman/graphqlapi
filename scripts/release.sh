#!/bin/bash

if [ -z "$1" ]
  then
    echo "No version argument supplied"
    exit 1
fi

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

cd $SCRIPTPATH/..

sed -i "s/local VERSION = 'scm-1'/local VERSION = '$1-1'/g" graphqlapi.lua
tarantoolctl rocks new_version --tag $1
tarantoolctl rocks make graphqlapi-$1-1.rockspec
tarantoolctl rocks pack graphqlapi $1
sed -i "s/local VERSION = '$1-1'/local VERSION = 'scm-1'/g" graphqlapi.lua
