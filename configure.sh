#! /bin/bash

################################################################################
# Prepare
################################################################################

# Set up shell
if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
    set -x                      # Output commands
fi
set -e                          # Abort on errors



################################################################################
# Search
################################################################################

if [ -z "${FFTW3_DIR}" ]; then
    echo "BEGIN MESSAGE"
    echo "FFTW3 selected, but FFTW3_DIR not set. Checking some places..."
    echo "END MESSAGE"
    
    FILES="include/fftw3.h"
    DIRS="/usr /usr/local /usr/local/fftw3 /usr/local/packages/fftw3 /usr/local/apps/fftw3 ${HOME} c:/packages/fftw3"
    for dir in $DIRS; do
        FFTW3_DIR="$dir"
        for file in $FILES; do
            if [ ! -r "$dir/$file" ]; then
                unset FFTW3_DIR
                break
            fi
        done
        if [ -n "$FFTW3_DIR" ]; then
            break
        fi
    done
    
    if [ -z "$FFTW3_DIR" ]; then
        echo "BEGIN MESSAGE"
        echo "FFTW3 not found"
        echo "END MESSAGE"
    else
        echo "BEGIN MESSAGE"
        echo "Found FFTW3 in ${FFTW3_DIR}"
        echo "END MESSAGE"
    fi
fi



################################################################################
# Build
################################################################################

if [ -z "${FFTW3_DIR}"                                                  \
     -o "$(echo "${FFTW3_DIR}" | tr '[a-z]' '[A-Z]')" = 'BUILD' ]
then
    echo "BEGIN MESSAGE"
    echo "Using bundled FFTW3..."
    echo "END MESSAGE"
    
    # Set locations
    THORN=FFTW3
    NAME=fftw-3.3.3
    SRCDIR=$(dirname $0)
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
    
    if [ -e ${DONE_FILE} -a ${DONE_FILE} -nt ${SRCDIR}/dist/${NAME}.tar.gz \
                         -a ${DONE_FILE} -nt ${SRCDIR}/configure.sh ]
    then
        echo "BEGIN MESSAGE"
        echo "FFTW3 has already been built; doing nothing"
        echo "END MESSAGE"
    else
        echo "BEGIN MESSAGE"
        echo "Building FFTW3"
        echo "END MESSAGE"
        
        # Build in a subshell
        (
        exec >&2                # Redirect stdout to stderr
        if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
            set -x              # Output commands
        fi
        set -e                  # Abort on errors
        cd ${SCRATCH_BUILD}
        
        # Set up environment
        export LDFLAGS
        unset LIBS
        unset RPATH
        if echo '' ${ARFLAGS} | grep 64 >/dev/null 2>&1; then
            export OBJECT_MODE=64
        fi
        
        echo "FFTW3: Preparing directory structure..."
        mkdir build external done 2> /dev/null || true
        rm -rf ${BUILD_DIR} ${INSTALL_DIR}
        mkdir ${BUILD_DIR} ${INSTALL_DIR}
        
        echo "FFTW3: Unpacking archive..."
        pushd ${BUILD_DIR}
        ${TAR?} xzf ${SRCDIR}/dist/${NAME}.tar.gz
        
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
        )
        if (( $? )); then
            echo 'BEGIN ERROR'
            echo 'Error while building FFTW3. Aborting.'
            echo 'END ERROR'
            exit 1
        fi
    fi
    
fi



################################################################################
# Configure Cactus
################################################################################

# Set options
if [ "${FFTW3_DIR}" = '/usr' -o "${FFTW3_DIR}" = '/usr/local' ]; then
    FFTW3_INC_DIRS=''
    FFTW3_LIB_DIRS=''
else
    FFTW3_INC_DIRS="${FFTW3_DIR}/include"
    FFTW3_LIB_DIRS="${FFTW3_DIR}/lib"
fi
: ${FFTW3_LIBS='fftw3'}

# Pass options to Cactus
echo "BEGIN MAKE_DEFINITION"
echo "HAVE_FFTW3     = 1"
echo "FFTW3_DIR      = ${FFTW3_DIR}"
echo "FFTW3_INC_DIRS = ${FFTW3_INC_DIRS}"
echo "FFTW3_LIB_DIRS = ${FFTW3_LIB_DIRS}"
echo "FFTW3_LIBS     = ${FFTW3_LIBS}"
echo "END MAKE_DEFINITION"

echo 'INCLUDE_DIRECTORY $(FFTW3_INC_DIRS)'
echo 'LIBRARY_DIRECTORY $(FFTW3_LIB_DIRS)'
echo 'LIBRARY           $(FFTW3_LIBS)'
