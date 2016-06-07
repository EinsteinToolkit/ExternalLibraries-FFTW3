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

    DIRS="/usr /usr/local /usr/local/packages /usr/local/apps /opt/local ${HOME} c:/packages"
    for dir in $DIRS; do
      DIRS="$DIRS $dir/fftw3"
    done
    for dir in $DIRS; do
        # libraries might have different file extensions
        for libext in a dll dll.a dylib lib so; do
            # libraries can be in lib or lib64 (or libx32?)
            for libdir in lib64 lib/x86_64-linux-gnu lib lib/i386-linux-gnu lib/arm-linux-gnueabihf; do
                FILES="include/fftw3.h $libdir/libfftw3.$libext"
                # assume this is the one and check all needed files
                FFTW3_DIR="$dir"
                for file in $FILES; do
                    # discard this directory if one file was not found
                    if [ ! -r "$dir/$file" ]; then
                        unset FFTW3_DIR
                        break
                    fi
                done
                # don't look further if all files have been found
                if [ -n "$FFTW3_DIR" ]; then
                    break
                fi
            done
            # don't look further if all files have been found
            if [ -n "$FFTW3_DIR" ]; then
                break
            fi
        done
        # don't look further if all files have been found
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

THORN=FFTW3



################################################################################
# Build
################################################################################

if [ -z "${FFTW3_DIR}"                                                  \
     -o "$(echo "${FFTW3_DIR}" | tr '[a-z]' '[A-Z]')" = 'BUILD' ]
then
    echo "BEGIN MESSAGE"
    echo "Using bundled FFTW3..."
    echo "END MESSAGE"
    
    # Check for required tools. Do this here so that we don't require
    # them when using the system library.
    if [ "x$TAR" = x ] ; then
        echo 'BEGIN ERROR'
        echo 'Could not find tar command.'
        echo 'Please make sure that the (GNU) tar command is present,'
        echo 'and that the TAR variable is set to its location.'
        echo 'END ERROR'
        exit 1
    fi
    if [ "x$PATCH" = x ] ; then
        echo 'BEGIN ERROR'
        echo 'Could not find patch command.'
        echo 'Please make sure that the patch command is present,'
        echo 'and that the PATCH variable is set to its location.'
        echo 'END ERROR'
        exit 1
    fi

    # Set locations
    BUILD_DIR=${SCRATCH_BUILD}/build/${THORN}
    if [ -z "${FFTW3_INSTALL_DIR}" ]; then
        INSTALL_DIR=${SCRATCH_BUILD}/external/${THORN}
    else
        echo "BEGIN MESSAGE"
        echo "Installing FFTW3 into ${FFTW3_INSTALL_DIR}"
        echo "END MESSAGE"
        INSTALL_DIR=${FFTW3_INSTALL_DIR}
    fi
    FFTW3_BUILD=1
    FFTW3_DIR=${INSTALL_DIR}
else
    FFTW3_BUILD=
    DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
    if [ ! -e ${DONE_FILE} ]; then
        mkdir ${SCRATCH_BUILD}/done 2> /dev/null || true
        date > ${DONE_FILE}
    fi
fi



################################################################################
# Configure Cactus
################################################################################

# Pass configuration options to build script
echo "BEGIN MAKE_DEFINITION"
echo "FFTW3_BUILD       = ${FFTW3_BUILD}"
echo "FFTW3_INSTALL_DIR = ${FFTW3_INSTALL_DIR}"
echo "END MAKE_DEFINITION"

# Set options
if [ "${FFTW3_DIR}" != 'NO_BUILD' ]; then
    : ${FFTW3_INC_DIRS="${FFTW3_DIR}/include"}
    : ${FFTW3_LIB_DIRS="${FFTW3_DIR}/lib"}
fi
: ${FFTW3_LIBS='fftw3'}

FFTW3_INC_DIRS="$(${CCTK_HOME}/lib/sbin/strip-incdirs.sh ${FFTW3_INC_DIRS})"
FFTW3_LIB_DIRS="$(${CCTK_HOME}/lib/sbin/strip-libdirs.sh ${FFTW3_LIB_DIRS})"

# Pass options to Cactus
echo "BEGIN MAKE_DEFINITION"
echo "FFTW3_DIR      = ${FFTW3_DIR}"
echo "FFTW3_INC_DIRS = ${FFTW3_INC_DIRS}"
echo "FFTW3_LIB_DIRS = ${FFTW3_LIB_DIRS}"
echo "FFTW3_LIBS     = ${FFTW3_LIBS}"
echo "END MAKE_DEFINITION"

echo 'INCLUDE_DIRECTORY         $(FFTW3_INC_DIRS)'
echo 'INCLUDE_DIRECTORY_FORTRAN $(FFTW3_INC_DIRS) /usr/include'
echo 'LIBRARY_DIRECTORY         $(FFTW3_LIB_DIRS)'
echo 'LIBRARY                   $(FFTW3_LIBS)'
