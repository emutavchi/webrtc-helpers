#!/bin/bash

set -e

function trap_exit() {
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo "*** Error: build failed"
    fi
    trap - INT TERM EXIT
    exit $exit_code
}
trap "trap_exit" INT TERM EXIT

SCRIPT_DIR=$(readlink -m ${BASH_SOURCE[0]} | xargs dirname)
WORK_DIR=${WORK_DIR-${SCRIPT_DIR}/source}
STAGE_DIR=${STAGE_DIR-${SCRIPT_DIR}/stage}
BUILD_DIR=${WORK_DIR}/out/Release
WEBRTC_PKG_DEPS="openssl libevent vpx alsa expat jsoncpp"
BUILD_CONFIGURATION=(
 -Dbuild_expat=0
 -Dbuild_json=0
 -Dbuild_libevent=0
 -Dbuild_libsrtp=1
 -Dbuild_libvpx=0
 -Dbuild_libyuv=1
 -Dbuild_ssl=0
 -Dbuild_usrsctp=0
 -Dbuild_with_chromium=0
 -Dchromeos=0
 -Dclang=0
 -Denable_protobuf=0
 -Dgtest_target_type=executable
 -Dinclude_examples=0
 -Dinclude_ilbc=0
 -Dinclude_opus=0
 -Dinclude_pulse_audio=0
 -Dinclude_tests=1
 -Dlibvpx_build_vp9=0
 -Dlibyuv_disable_jpeg=1
 -Dmsan=0
 -Dnacl_untrusted_build=0
 -Dos_bsd=0
 -Dos_posix=1
 -Dproprietary_codecs=0
 -Drtc_use_openmax_dl=0
 -Dsysroot=""
 -Dtarget_arch=x64
 -Dtest_isolation_mode=noop
 -Duse_gtk=0
 -Duse_x11=0
 -Dwebrtc_pkg_deps="$WEBRTC_PKG_DEPS"
)

function do_clone()
{
    # Revision numbers are based on https://chromium.googlesource.com/chromium/src.git/+/52.0.2743.116/DEPS
    mkdir -p ${WORK_DIR} && cd ${WORK_DIR}
    if [ ! -d .git ]; then
        git clone https://chromium.googlesource.com/external/webrtc .
        git fetch origin refs/branch-heads/52
        git checkout FETCH_HEAD -b m52
    fi

    mkdir -p ${WORK_DIR}/third_party/libyuv && cd ${WORK_DIR}/third_party/libyuv
    if [ ! -d .git ]; then
        git clone https://chromium.googlesource.com/libyuv/libyuv .
        git checkout 76aee8ced7ca74c724d69c1dcf9891348450c8e8
    fi

    mkdir -p ${WORK_DIR}/third_party/libsrtp && cd ${WORK_DIR}/third_party/libsrtp
    if [ ! -d .git ]; then
        git clone https://chromium.googlesource.com/chromium/deps/libsrtp .
        git checkout 720780acf8fa41c4a6ad515d0382d62f8f5195eb
    fi

    mkdir -p  ${WORK_DIR}/tools/gyp && cd ${WORK_DIR}/tools/gyp
    if [ ! -d .git ]; then
        git clone https://chromium.googlesource.com/external/gyp .
        git checkout bce1c7793010574d88d7915e2d55395213ac63d1
    fi

    mkdir -p ${WORK_DIR}/third_party/gflags/src && cd ${WORK_DIR}/third_party/gflags/src
    if [ ! -d .git ]; then
        git clone https://chromium.googlesource.com/external/github.com/gflags/gflags .
        git checkout 03bebcb065c83beff83d50ae025a55a4bf94dfca
    fi

    mkdir -p ${WORK_DIR}/testing/gmock && cd ${WORK_DIR}/testing/gmock
    if [ ! -d .git ]; then
        git clone https://chromium.googlesource.com/external/googlemock .
        git checkout 0421b6f358139f02e102c9c332ce19a33faf75be
    fi

    mkdir -p ${WORK_DIR}/testing/gtest && cd ${WORK_DIR}/testing/gtest
    if [ ! -d .git ]; then
        git clone https://chromium.googlesource.com/external/github.com/google/googletest .
        git checkout 6f8a66431cb592dad629028a50b3dd418a408c87
    fi
}

function do_patch()
{
    cd ${WORK_DIR}
    if [ ! -d .pc ]; then
        quilt init
        quilt import ${SCRIPT_DIR}/disable_vp8_postproc.patch
        quilt import ${SCRIPT_DIR}/default_rsa_key_type.patch
        quilt import ${SCRIPT_DIR}/initial_build_fix.patch
        quilt push -a
    fi
}

function do_configure()
{
    cd ${WORK_DIR}

    cp ${SCRIPT_DIR}/gmock.gyp ${WORK_DIR}/testing/
    cp ${SCRIPT_DIR}/gtest.gyp ${WORK_DIR}/testing/

    GYP_GENERATORS=ninja tools/gyp/gyp --no-circular-check --depth . -I "${SCRIPT_DIR}/supplement.gypi" "${BUILD_CONFIGURATION[@]}"

    # Disable thin archives
    sed -i 's:ar rcsT:ar rcs:g' out/*/build.ninja
}

function do_build()
{
    cd ${WORK_DIR}
    ninja -v -C ${BUILD_DIR}
}

function do_clean()
{
    cd ${WORK_DIR}
    ninja -v -t clean -C ${BUILD_DIR}
}

function do_install()
{
    cd ${WORK_DIR}

    install -d ${STAGE_DIR}/include/
    find ./webrtc -name '*.h' -exec cp --parents '{}' ${STAGE_DIR}/include/ \;

    install -d ${STAGE_DIR}/lib
    find ${BUILD_DIR} -name '*.a' -exec install '{}' ${STAGE_DIR}/lib/ \;

    install -d ${STAGE_DIR}/lib/pkgconfig/
    install ${SCRIPT_DIR}/webrtc.pc ${STAGE_DIR}/lib/pkgconfig/

    cd ${STAGE_DIR}/lib

    webrtc_libs=$(find ${BUILD_DIR} -name '*.a' -print | xargs -n1 basename | sed s/^lib/-l/g | sed s/\.a$//g | tr '\n' ' ')
    sed -i "s:%WEBRTC_PREFIX%:${STAGE_DIR}:g" pkgconfig/webrtc.pc
    sed -i "s:%WEBRTC_LIBS%:${webrtc_libs}:g" pkgconfig/webrtc.pc
    sed -i "s:%WEBRTC_PKG_DEPS%:${WEBRTC_PKG_DEPS}:g" pkgconfig/webrtc.pc
}

function usage()
{
    echo "Usage: `basename $0` [-d] [-h|--help] [action]"
    echo "    -h    --help                  : this help"
    echo "    -d                            : debug build"
    echo
    echo "Supported actions:"
    echo "      clone, patch, configure, clean, build (DEFAULT), install"
    exit 0
}

if ! GETOPT=$(getopt -n "build.sh" -o hd -l help: -- "$@"); then
    usage
    exit 1
fi
eval set -- "$GETOPT"

while true; do
    case "$1" in
        -h | --help ) usage; exit 0 ;;
        -d) BUILD_DIR=${WORK_DIR}/out/Debug ;;
        -- ) shift; break;;
        * ) break;;
    esac
    shift
done

ARGS=$@
HIT=false

for i in ${ARGS[@]}; do
    case $i in
        clone)      HIT=true; do_clone ;;
        patch)      HIT=true; do_patch ;;
        configure)  HIT=true; do_configure ;;
        clean)      HIT=true; do_clean ;;
        build)      HIT=true; do_build ;;
        install)    HIT=true; do_install ;;
        *)
        #skip unknown
        ;;
    esac
done

if ! $HIT; then
    do_clone
    do_patch
    do_configure
    do_build
    do_install
fi

trap - INT TERM EXIT
set +ex
