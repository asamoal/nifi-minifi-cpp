#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

get_toolset_name() {
    case "$OS_MAJOR" in
        7) TOOLSET_NAME=devtoolset-11 ;;
        8) TOOLSET_NAME=gcc-toolset-12 ;;
        9) TOOLSET_NAME=gcc-toolset-12 ;;
    esac
}

install_pkgs() {
    if [ "$OS_MAJOR" -gt 7 ]; then
        sudo dnf -y install "$@"
    else
        ulimit -n 1024000 && sudo yum -y install "$@"
    fi
}

verify_enable_platform() {
    feature="$1"
    if [ "$OS_MAJOR" -gt 6 ]; then
        if [ "$feature" = "USB_ENABLED" ]; then
            echo "false"
        else
            verify_gcc_enable "$feature"
        fi
    fi
}

add_os_flags() {
    get_toolset_name
    source /opt/rh/$TOOLSET_NAME/enable
}
install_bison() {
    INSTALLED+=("bison")
}

install_libusb() {
    INSTALLED+=("libusb-devel")
}


bootstrap_cmake(){
    install_cmake_from_binary
}

bootstrap_compiler() {
    get_toolset_name
    if [ -n "$TOOLSET_NAME" ]; then
        install_pkgs centos-release-scl
        install_pkgs "$TOOLSET_NAME"
    fi
    source "/opt/rh/$TOOLSET_NAME/enable"
}

build_deps() {
    COMMAND="install_pkgs libuuid libuuid-devel libtool patch epel-release"
    INSTALLED=()
    for option in "${OPTIONS[@]}" ; do
        option_value="${!option}"
        if [ "$option_value" = "${TRUE}" ]; then
            # option is enabled
            FOUND_VALUE=""
            for cmake_opt in "${DEPENDENCIES[@]}" ; do
                KEY=${cmake_opt%%:*}
                VALUE=${cmake_opt#*:}
                if [ "$KEY" = "$option" ]; then
                    FOUND_VALUE="$VALUE"
                    if [ "$FOUND_VALUE" = "libpcap" ]; then
                        INSTALLED+=("libpcap-devel")
                    elif [ "$FOUND_VALUE" = "libusb" ]; then
                        install_libusb
                    elif [ "$FOUND_VALUE" = "libpng" ]; then
                        INSTALLED+=("libpng-devel")
                    elif [ "$FOUND_VALUE" = "bison" ]; then
                        install_bison
                    elif [ "$FOUND_VALUE" = "flex" ]; then
                        INSTALLED+=("flex")
                    elif [ "$FOUND_VALUE" = "automake" ]; then
                        INSTALLED+=("automake")
                    elif [ "$FOUND_VALUE" = "jnibuild" ]; then
                        INSTALLED+=("java-1.8.0-openjdk")
                        INSTALLED+=("java-1.8.0-openjdk-devel")
                        INSTALLED+=("maven")
                    elif [ "$FOUND_VALUE" = "python" ]; then
                        INSTALLED+=("python36-devel")
                    elif [ "$FOUND_VALUE" = "lua" ]; then
                        INSTALLED+=("lua-libs")
                        INSTALLED+=("lua-devel")
                    elif [ "$FOUND_VALUE" = "gpsd" ]; then
                        INSTALLED+=("gpsd-devel")
                    elif [ "$FOUND_VALUE" = "libarchive" ]; then
                        INSTALLED+=("xz-devel")
                        INSTALLED+=("bzip2-devel")
                    elif [ "$FOUND_VALUE" = "libssh2" ]; then
                        INSTALLED+=("libssh2-devel")
                    elif [ "$FOUND_VALUE" = "opensslbuild" ]; then
                        INSTALLED+=("perl")
                    fi
                fi
            done

        fi
    done
    INSTALLED+=("autoconf")
    for option in "${INSTALLED[@]}" ; do
        COMMAND="${COMMAND} $option"
    done

    ${COMMAND}
}
