#!/bin/bash

set -e

LUVI_VERSION=v2.0.5
LIT_VERSION=1.1.8
RMA_VERSION=luvi-up

LIT_URL="https://github.com/luvit/lit/archive/$LIT_VERSION.zip"
RMA_URL="https://github.com/virgo-agent-toolkit/rackspace-monitoring-agent"
LUA_SIGAR_URL="https://github.com/virgo-agent-toolkit/lua-sigar.git "

BUILD_DIR=${PWD}/build
SRC_DIR=${PWD}/src

setup() {
  mkdir -p ${BUILD_DIR}
  mkdir -p ${SRC_DIR}
  export PATH=${BUILD_DIR}:$PATH
}

build_luvi() {
  LUVI_DIR="${SRC_DIR}/luvi-${LUVI_VERSION}"
  [ -d ${LUVI_DIR} ] || \
    git clone --recursive --branch ${LUVI_VERSION} \
      https://github.com/luvit/luvi ${LUVI_DIR}
  pushd ${LUVI_DIR}
    export WITHOUT_AMALG=1
    make regular && make && cp build/luvi ${BUILD_DIR}
  popd
}

build_lit() {
  [ -f ${SRC_DIR}/lit.zip ] || \
    curl -L $LIT_URL > ${SRC_DIR}/lit.zip
  [ -x ${BUILD_DIR}/lit ] || \
    pushd ${BUILD_DIR} ; ${BUILD_DIR}/luvi ${SRC_DIR}/lit.zip -- make ${SRC_DIR}/lit.zip ; popd
}

build_lua_sigar() {
  SIGAR_DIR="${SRC_DIR}/lua-sigar"
  [ -d ${SIGAR_DIR} ] || \
    git clone --recursive ${LUA_SIGAR_URL} ${SIGAR_DIR}
  pushd ${SIGAR_DIR}
    make && cp build/sigar.so ${BUILD_DIR}
  popd
}

build_rackspace_monitoring_agent() {
  RMA_DIR="${SRC_DIR}/rackspace-monitoring-agent"
  LUVI_ARCH=`uname -s`
  [ -d ${RMA_DIR} ] || git clone --branch ${RMA_VERSION} ${RMA_URL} ${RMA_DIR}
  pushd ${RMA_DIR}
    cp ${BUILD_DIR}/sigar.so libs/${LUVI_ARCH}-x64
    ${BUILD_DIR}/lit make
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

while getopts ":n" o; do
  case "${o}" in
    n)
      SKIP_UPLOAD="true"
      ;;
    *)
      ;;
  esac
done
shift $((OPTIND-1))

setup
build_luvi
build_lit
build_lua_sigar
build_rackspace_monitoring_agent
