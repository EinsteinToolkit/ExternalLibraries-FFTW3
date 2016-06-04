#! /bin/bash

################################################################################
# Build
################################################################################

# Set up shell
if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
    set -x                      # Output commands
fi
set -e                          # Abort on errors



# Set locations
THORN=FFTW3
NAME=fftw-3.3.3
SRCDIR="$(dirname $0)"
BUILD_DIR=${SCRATCH_BUILD}/build/${THORN}
if [ -z "${FFTW3_INSTALL_DIR}" ]; then
    INSTALL_DIR=${SCRATCH_BUILD}/external/${THORN}
else
    echo "BEGIN MESSAGE"
    echo "Installing FFTW3 into ${FFTW3_INSTALL_DIR}"
    echo "END MESSAGE"
    INSTALL_DIR=${FFTW3_INSTALL_DIR}
fi
DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
FFTW3_DIR=${INSTALL_DIR}

# Set up environment
export CPPFLAGS="${CPPFLAGS} $(echo $(for dir in ${SYS_INC_DIRS}; do echo '' -I${dir}; done))"
export LDFLAGS="${LDFLAGS} $(echo $(for dir in ${LIBDIRS}; do echo '' -L${dir} -Wl,-rpath,${dir}; done))"
export LIBS='-lm'
unset RPATH
if echo '' ${ARFLAGS} | grep 64 >/dev/null 2>&1; then
    export OBJECT_MODE=64
fi

echo "FFTW3: Preparing directory structure..."
cd ${SCRATCH_BUILD}
mkdir build external done 2> /dev/null || true
rm -rf ${BUILD_DIR} ${INSTALL_DIR}
mkdir ${BUILD_DIR} ${INSTALL_DIR}

echo "FFTW3: Unpacking archive..."
pushd ${BUILD_DIR}
${TAR?} xzf ${SRCDIR}/../dist/${NAME}.tar.gz

echo "FFTW3: Configuring..."
cd ${NAME}
./configure --prefix=${FFTW3_DIR}

echo "FFTW3: Building..."
${MAKE}

echo "FFTW3: Installing..."
${MAKE} install
popd

echo "FFTW3: Cleaning up..."
rm -rf ${BUILD_DIR}

date > ${DONE_FILE}
echo "FFTW3: Done."
