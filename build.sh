#!/bin/bash

set -e

LUVI_VERSION=v1.0.1
LIT_VERSION=1.0.2
RMA_VERSION=luvi-up

LIT_URL="https://github.com/luvit/lit/archive/$LIT_VERSION.zip"
RMA_URL="https://github.com/virgo-agent-toolkit/rackspace-monitoring-agent"
LUA_SIGAR_URL="https://github.com/virgo-agent-toolkit/lua-sigar.git "

BUILD_DIR=${PWD}/build
SRC_DIR=${PWD}/src

setup() {
  mkdir -p ${BUILD_DIR}
  mkdir -p ${SRC_DIR}
}

build_luvi() {
  LUVI_DIR="${SRC_DIR}/luvi-${LUVI_VERSION}"
  [ -d ${LUVI_DIR} ] || \
    git clone --recursive --branch ${LUVI_VERSION} \
      https://github.com/luvit/luvi ${LUVI_DIR}
  pushd ${LUVI_DIR}
    make static && make && cp build/luvi ${BUILD_DIR}
  popd
}

build_lit() {
  [ -f ${SIRC_DIR}/lit.zip ] || \
    curl -L $LIT_URL > ${SRC_DIR}/lit.zip
  [ -x ${BUILD_DIR}/lit ] || \
    LUVI_TARGET=${BUILD_DIR}/lit LUVI_APP=${SRC_DIR}/lit.zip \
      ${BUILD_DIR}/luvi make ${SRC_DIR}/lit.zip
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
  popd
}

setup
build_luvi
build_lit
build_lua_sigar
build_rackspace_monitoring_agent
