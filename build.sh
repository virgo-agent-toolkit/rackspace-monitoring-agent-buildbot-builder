#!/bin/bash

# LUVI_VERSION should reference latest release on rackspace branch
LUVI_VERSION=v2.9.4-sigar
LIT_VERSION=3.7.3
RMA_VERSION=${RMA_VERSION:-master}

LIT_URL="https://lit.luvit.io/packages/luvit/lit/v$LIT_VERSION.zip"
LUVI_URL="https://github.com/virgo-agent-toolkit/luvi.git"
RMA_URL="https://github.com/virgo-agent-toolkit/rackspace-monitoring-agent"
LUA_SIGAR_URL="https://github.com/virgo-agent-toolkit/lua-sigar.git "

BUILD_DIR=${PWD}/build
SRC_DIR=${PWD}/src
RESULT=0

set -e
ulimit -c unlimited -S # capture core dumps

export LIT=${BUILD_DIR}/lit
export LUVI=${BUILD_DIR}/luvi

setup() {
  mkdir -p ${BUILD_DIR} ${SRC_DIR}
  export PATH=${BUILD_DIR}:$PATH
}

build_luvi() {
  WITHOUT_AMALG=1
  LUVI_DIR="${SRC_DIR}/luvi-${LUVI_VERSION}"
  [ -d ${LUVI_DIR} ] || \
    git clone --recursive --branch ${LUVI_VERSION} ${LUVI_URL} ${LUVI_DIR}
  pushd ${LUVI_DIR}
    WITHOUT_AMALG=1 make regular-asm && make && cp build/luvi ${BUILD_DIR}
  popd
}

build_lit() {
  [ -f ${SRC_DIR}/lit.zip ] || \
    curl -kL $LIT_URL > ${SRC_DIR}/lit.zip
  [ -x ${BUILD_DIR}/lit ] || {
    pushd ${BUILD_DIR} ; ${BUILD_DIR}/luvi ${SRC_DIR}/lit.zip -- make ${SRC_DIR}/lit.zip ${BUILD_DIR}/lit ${BUILD_DIR}/luvi; popd
  }
}

check_core() {
  for i in $(find ./ -maxdepth 1 -name 'core*' -print); do gdb $(pwd)/build/rackspace-monitoring-agent core* -ex "thread apply all bt" -ex "set pagination 0" -batch; done;
}

build_rackspace_monitoring_agent() {
  RMA_DIR="${SRC_DIR}/rackspace-monitoring-agent"
  [ -d ${RMA_DIR} ] || git clone --depth=1 --branch ${RMA_VERSION} ${RMA_URL} ${RMA_DIR}
  pushd ${RMA_DIR}
    ln -f -s ${LUVI} .
    ln -f -s ${LUVI} luvi-sigar
    ln -f -s ${LIT} .
    make || (RESULT=$? ; check_core)
    make test || (RESULT=$? ; check_core)
    make package
    make packagerepo
    if [ "$SKIP_UPLOAD" != "true" ] ; then
      make packagerepoupload
      make siggen
      make siggenupload
    else
      echo "skipping upload"
    fi
  popd
}

show_usage() {
  echo "Usage: $0 [--force-version VERSION] [-n|--skip-upload]"
  exit 1
}

while :; do
  case $1 in
    n|--skip-upload)
      export SKIP_UPLOAD="true"
      ;;
    --force-version)
      if [ -n "$2" ] ; then
        export FORCE_VERSION=$2
        echo "Forcing version: $2"
        shift
      fi
      ;;
    --) # end of options
      shift
      break
      ;;
    -h|-\?|--help)
      show_usage
      ;;
    *)
      break
      ;;
  esac
  shift
done

setup
build_luvi
build_lit
build_rackspace_monitoring_agent
