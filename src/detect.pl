#! /usr/bin/perl

use strict;
use Carp;                       # 'confess', similar to 'die'
use File::Path 'mkpath';
use File::Spec;
use POSIX;



################################################################################
# Setup
################################################################################

# Possible settings of FFTW3_DIR:
# - directory: use this directory, which must contain the library
# - 'BUILD': build the library
# - 'NO_BUILD': don't do anything, assuming another mechanism provides
#               the library
# - empty: look for the library; if found, use it; if not found, build it
my $do_build;                   # build the library
my $do_set_options;             # set Cactus options

my $thorn = "FFTW3";
my $install_dir;
my (@inc_dirs, @lib_dirs, @libs);



################################################################################
# Search
################################################################################

if ($ENV{FFTW3_DIR} eq 'BUILD') {
    $do_build = 1;
    $do_set_options = 1;
} elsif ($ENV{FFTW3_DIR} eq 'NO_BUILD') {
    $install_dir = '';
    $do_build = 0;
    $do_set_options = 0;
} elsif ($ENV{FFTW3_DIR} eq '') {
    print "BEGIN MESSAGE\n";
    print "FFTW3 selected, but FFTW3_DIR not set. Checking some places...\n";
    print "END MESSAGE\n";

    my @dirs = ("/usr", "/usr/local", "/usr/local/packages", "/usr/local/apps",
                "/opt/local", "$ENV{HOME}", "c:/packages");
    my @subdirs = (".", "fftw3");
    my @libdirs = ("lib64", "lib/x86_64-linux-gnu", "lib",
                   "lib/i386-linux-gnu", "lib/arm-linux-gnueabihf");
    my @libexts = ("a", "dll", "dll.a", "dylib", "lib", "so");
    my @need_includes = ("fftw3.h");
    my @need_libs = ("fftw3");
  FINDLIB: for my $dir (@dirs) {
        for my $subdir (@subdirs) {
            # libraries can be in lib or lib64 (or libx32?)
            for my $libdir (@libdirs) {
                # libraries might have different file extensions
                for my $libext (@libexts) {
                    my @files;
                    foreach my $need_include (@need_includes) {
                        push @files, "include/${need_include}";
                    }
                    foreach my $need_lib (@need_libs) {
                        push @files, "${libdir}/lib${need_lib}.${libext}";
                    }
                    # assume this is the one and check all needed files
                    $install_dir = "${dir}/${subdir}";
                    for my $file (@files) {
                        # discard this directory if one file was not found
                        if (! -r "$dir/$file") {
                            undef $install_dir;
                            last;
                        }
                    }
                    # don't look further if all files have been found
                    if (defined $install_dir) {
                        last FINDLIB;
                    }
                }
            }
        }
    }

    if (!defined $install_dir) {
        $do_build = 1;
        print "BEGIN MESSAGE\n";
        print "${thorn} not found\n";
        print "END MESSAGE\n";
    } else {
        $do_build = 0;
        print "BEGIN MESSAGE\n";
        print "Found ${thorn} in ${install_dir}\n";
        print "END MESSAGE\n";
    }
    $do_set_options = 1;
} else {
    $do_build = 0;
    $do_set_options = 1;
    $install_dir = $ENV{FFTW3_DIR};
}

# If we will set options and don't build, $install_dir must now be set
if ($do_build) {
    defined $install_dir and confess "Internal inconsistency";
} else {
    defined $install_dir or confess "Internal inconsistency";
}



################################################################################
# Build
################################################################################

if ($do_build) {
    print "BEGIN MESSAGE\n";
    print "Using bundled ${thorn}...\n";
    print "END MESSAGE\n";

    # Check for required tools. Do this here so that we don't require
    # them when using the system library.
    if ($ENV{TAR} eq '') {
        print "BEGIN ERROR\n";
        print "Could not find tar command.\n";
        print "Please make sure that the (GNU) tar command is present,\n";
        print "and that the TAR variable is set to its location.\n";
        print "END ERROR\n";
        exit 1;
    }
    if ($ENV{PATCH} eq '') {
        print "BEGIN ERROR\n";
        print "Could not find patch command.\n";
        print "Please make sure that the patch command is present,\n";
        print "and that the PATCH variable is set to its location.\n";
        print "END ERROR\n";
        exit 1;
    }

    # Set locations
    my $build_dir = "$ENV{SCRATCH_BUILD}/build/${thorn}";
    if ($ENV{FFTW3_INSTALL_DIR} eq '') {
        $install_dir = "$ENV{SCRATCH_BUILD}/external/${thorn}";
    } else {
        $install_dir = $ENV{FFTW3_INSTALL_DIR};
        print "BEGIN MESSAGE\n";
        print "Installing ${thorn} into ${install_dir}\n";
        print "END MESSAGE\n";
    }

    @inc_dirs = ("${install_dir}/include");
    @lib_dirs = ("${install_dir}/lib");
    @libs = ("fftw3_threads", "fftw3");
    if ($ENV{MPI_DIR} ne '') {
        unshift @libs, "fftw3_mpi";
    }
} else {
    $install_dir eq '' and confess "Internal inconsistency";
    if ($do_set_options) {
        @inc_dirs = split '', $ENV{FFTW3_INC_DIRS};
        @lib_dirs = split '', $ENV{FFTW3_LIB_DIRS};
        @libs = split '', $ENV{FFTW3_LIBS};
        if (!@inc_dirs) {
            @inc_dirs = ("${install_dir}/include");
        }
        if (!@lib_dirs) {
            @lib_dirs = ("${install_dir}/lib");
        }
        if (!@libs) {
            @libs = ("fftw3_threads", "fftw3");
            if ($ENV{MPI_DIR} ne '') {
                unshift @libs, "fftw3_mpi";
            }
        }
    } else {
        @inc_dirs = ();
        @lib_dirs = ();
        @libs = ();
    }

    my $done_dir = "$ENV{SCRATCH_BUILD}/done";
    mkpath $done_dir;
    my $done_file = "${done_dir}/${thorn}";
    open (my $fh, '>', $done_file) or confess "Could not open file";
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
        localtime(time);
    print $fh strftime "%F %T\n", $sec,$min,$hour,$mday,$mon,$year;
    close $fh;
}



################################################################################
# Configure Cactus
################################################################################

if ($do_build) {
    # Pass configuration options to build script
    print "BEGIN MAKE_DEFINITION\n";
    print "FFTW3_INSTALL_DIR = ${install_dir}\n";
    if ($ENV{MPI_DIR} ne '') {
        print "MPI_DIR      = ${ENV{MPI_DIR}}\n";
        print "MPI_INC_DIRS = ${ENV{MPI_INC_DIRS}}\n";
        print "MPI_LIB_DIRS = ${ENV{MPI_LIB_DIRS}}\n";
        print "MPI_LIBS     = ${ENV{MPI_LIBS}}\n";
    }
    if ($ENV{HWLOC_DIR} ne '') {
        print "HWLOC_DIR      = ${ENV{HWLOC_DIR}}\n";
        print "HWLOC_INC_DIRS = ${ENV{HWLOC_INC_DIRS}}\n";
        print "HWLOC_LIB_DIRS = ${ENV{HWLOC_LIB_DIRS}}\n";
        print "HWLOC_LIBS     = ${ENV{HWLOC_LIBS}}\n";
    }
    print "END MAKE_DEFINITION\n";
}

@inc_dirs = map { File::Spec->canonpath($_) } @inc_dirs;
@inc_dirs = grep !m{^(|/usr|/usr/local)/include$}, @inc_dirs;

@lib_dirs = map { File::Spec->canonpath($_) } @lib_dirs;
@lib_dirs = grep !m{^(|/usr|/usr/local)/(lib|lib64)$}, @lib_dirs;

# Pass options to Cactus
print "BEGIN MAKE_DEFINITION\n";
print "FFTW3_DIR      = ${install_dir}\n";
print "FFTW3_INC_DIRS = " . (join ' ', @inc_dirs) . "\n";
print "FFTW3_LIB_DIRS = " . (join ' ', @lib_dirs) . "\n";
print "FFTW3_LIBS     = " . (join ' ', @libs) . "\n";
print "END MAKE_DEFINITION\n";

print "INCLUDE_DIRECTORY         \$(FFTW3_INC_DIRS)\n";
print "INCLUDE_DIRECTORY_FORTRAN \$(FFTW3_INC_DIRS) /usr/include\n";
print "LIBRARY_DIRECTORY         \$(FFTW3_LIB_DIRS)\n";
print "LIBRARY                   \$(FFTW3_LIBS)\n";
