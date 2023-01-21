#!/bin/bash
set -ex -o pipefail

PYTHON_DOWNLOAD_URL=https://www.python.org/ftp/python
GET_PIP_URL=https://bootstrap.pypa.io/get-pip.py

# Python versions to be installed in /opt/$VERSION_NO
CPYTHON_VERSIONS=${CPYTHON_VERSIONS:-"3.7.5 3.8.1 3.9.0 3.10.1 3.11.0"}

function check_var {
    if [ -z "$1" ]; then
        echo "required variable not defined"
        exit 1
    fi
}

function lex_pyver {
    # Echoes Python version string padded with zeros
    # Thus:
    # 3.2.1 -> 003002001
    # 3     -> 003000000
    echo $1 | awk -F "." '{printf "%03d%03d%03d", $1, $2, $3}'
}

function do_cpython_build {
    local py_ver=$1
    check_var $py_ver
    local ucs_setting=$2
    check_var $ucs_setting
    tar -xzf Python-$py_ver.tgz
    pushd Python-$py_ver
    if [ "$ucs_setting" = "none" ]; then
        unicode_flags=""
        dir_suffix=""
    else
        local unicode_flags="--enable-unicode=$ucs_setting"
        local dir_suffix="-$ucs_setting"
    fi
    local prefix="/opt/_internal/cpython-${py_ver}${dir_suffix}"
    mkdir -p ${prefix}/lib

    # -Wformat added for https://bugs.python.org/issue17547 on Python 2.6
    if [[ -z  "${WITH_OPENSSL+x}" ]]; then
        CFLAGS="-Wformat" ./configure --prefix=${prefix} --disable-shared $unicode_flags > /dev/null
    else
        CFLAGS="-Wformat" ./configure --prefix=${prefix} --with-openssl=${WITH_OPENSSL} --with-openssl-rpath=auto --disable-shared $unicode_flags > /dev/null
    fi

    make -j40 > /dev/null
    make install > /dev/null

    popd
    rm -rf Python-$py_ver
    # Some python's install as bin/python3. Make them available as
    # bin/python.
    if [ -e ${prefix}/bin/python3 ]; then
        ln -s python3 ${prefix}/bin/python
    fi
    ${prefix}/bin/python get-pip.py
    if [ -e ${prefix}/bin/pip3 ] && [ ! -e ${prefix}/bin/pip ]; then
        ln -s pip3 ${prefix}/bin/pip
    fi
    ${prefix}/bin/pip install wheel==0.34.2
    local abi_tag=$(${prefix}/bin/python -c "from wheel.pep425tags import get_abbr_impl, get_impl_ver, get_abi_tag; print('{0}{1}-{2}'.format(get_abbr_impl(), get_impl_ver(), get_abi_tag()))")
    ln -s ${prefix} /opt/python/${abi_tag}
}

function build_cpython {
    local py_ver=$1
    check_var $py_ver
    check_var $PYTHON_DOWNLOAD_URL
    local py_ver_folder=$py_ver
    wget -q $PYTHON_DOWNLOAD_URL/$py_ver_folder/Python-$py_ver.tgz
    if [ $(lex_pyver $py_ver) -lt $(lex_pyver 3.3) ]; then
        do_cpython_build $py_ver ucs2
        do_cpython_build $py_ver ucs4
    else
        do_cpython_build $py_ver none
    fi
    rm -f Python-$py_ver.tgz
}

function build_cpythons {
    check_var $GET_PIP_URL
    curl -sLO $GET_PIP_URL
    for py_ver in $@; do
        build_cpython $py_ver
    done
    rm -f get-pip.py
}

mkdir -p /opt/python
mkdir -p /opt/_internal
build_cpythons $CPYTHON_VERSIONS
