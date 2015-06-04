#!/bin/bash

set -e

LUVI_VERSION=release
LIT_VERSION=1.2.9
RMA_VERSION=luvi-up

LIT_URL="https://github.com/luvit/lit/archive/$LIT_VERSION.zip"
RMA_URL="https://github.com/virgo-agent-toolkit/rackspace-monitoring-agent"
LUA_SIGAR_URL="https://github.com/virgo-agent-toolkit/lua-sigar.git "

BUILD_DIR=${PWD}/build
SRC_DIR=${PWD}/src

ulimit -c unlimited # capture core dumps

export LIT=${BUILD_DIR}/lit
export LUVI=${BUILD_DIR}/luvi

setup() {
  mkdir -p ${BUILD_DIR} ${SRC_DIR}
  export PATH=${BUILD_DIR}:$PATH
}

build_luvi() {
  LUVI_DIR="${SRC_DIR}/luvi-${LUVI_VERSION}"
  [ -d ${LUVI_DIR} ] || \
    git clone --depth=1 --recursive --branch ${LUVI_VERSION} \
      https://github.com/luvit/luvi ${LUVI_DIR}
  pushd ${LUVI_DIR}
    export WITHOUT_AMALG=1
    make regular && make && cp build/luvi ${BUILD_DIR}
  popd
}

build_lit() {
  [ -f ${SRC_DIR}/lit.zip ] || \
    curl -L $LIT_URL > ${SRC_DIR}/lit.zip
  [ -x ${BUILD_DIR}/lit ] || {
    pushd ${BUILD_DIR} ; ${BUILD_DIR}/luvi ${SRC_DIR}/lit.zip -- make ${SRC_DIR}/lit.zip ; popd
  }
}

build_lua_sigar() {
  SIGAR_DIR="${SRC_DIR}/lua-sigar"
  [ -d ${SIGAR_DIR} ] || \
    git clone --depth=1 --recursive ${LUA_SIGAR_URL} ${SIGAR_DIR}
  pushd ${SIGAR_DIR}
    make && cp build/sigar.so ${BUILD_DIR}
  popd
}

build_rackspace_monitoring_agent() {
  RMA_DIR="${SRC_DIR}/rackspace-monitoring-agent"
  LUVI_ARCH=`uname -s`
  [ -d ${RMA_DIR} ] || git clone --depth=1 --branch ${RMA_VERSION} ${RMA_URL} ${RMA_DIR}
  pushd ${RMA_DIR}
    ln -f -s ${LUVI} .
    ln -f -s ${LIT} .
    cp ${BUILD_DIR}/sigar.so libs/${LUVI_ARCH}-x64
    make
    make test
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
build_lua_sigar
build_rackspace_monitoring_agent
