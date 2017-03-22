#!/bin/bash
set -e

if [[ $1 == "" || $2 == "" ]]; then
  echo Usage: $0 OPENSSL_HOME ENGINE
  exit 0
fi

OPENSSL_HOME=$1
ENGINE=$2
EXE=

if [[ $(uname) == "Darwin" ]]; then
  export DYLD_LIBRARY_PATH=$OPENSSL_HOME:"$DYLD_LIBRARY_PATH"
elif [[ $(uname) == "Linux" ]]; then
  export LD_LIBRARY_PATH=$OPENSSL_HOME:"$LD_LIBRARY_PATH"
elif [[ $(uname) == "CYGWIN" ]]; then
  export PATH=$OPENSSL_HOME:"$PATH"
  EXE=".exe"
fi

tput setaf 1
echo Running with engine: $ENGINE
tput sgr0
$OPENSSL_HOME/apps/openssl$EXE <<EOF
  engine $ENGINE
  speed -engine Everest ecdhx25519
  speed -engine Everest -evp chacha20
  speed -engine Everest -evp poly1305
EOF