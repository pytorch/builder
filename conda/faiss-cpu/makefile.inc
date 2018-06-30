# Copyright (c) 2015-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD+Patents license found in the
# LICENSE file in the root directory of this source tree.

CXX          = g++ -std=c++11
CXXCPP       = g++ -std=c++11 -E
# NOTE: Change to `-DFINTEGER=long` if using MKL.
# TODO: Investigate the LAPACKE wrapper for LAPACK, which defines the correct
#   type for FORTRAN integers.
CPPFLAGS     = -DFINTEGER=int
CXXFLAGS     = -fPIC -fopenmp -m64 -Wno-sign-compare -g -O3 -Wall -Wextra
CPUFLAGS     = -msse4 -mpopcnt
LDFLAGS      = -fopenmp
LIBS         = -lmkl_intel_lp64 -lmkl_intel_thread -lmkl_core -liomp5 -lpthread


########
########   Caution: modify those to point to your local conda install
########

PYTHON_INC=$(shell python -c "import distutils.sysconfig; print(distutils.sysconfig.get_python_inc())")
NUMPY_INC=$(shell python -c "import numpy ; print(numpy.get_include())")
PYTHONCFLAGS=-I${PYTHON_INC} -I${NUMPY_INC}

NVCC         =
NVCCLDFLAGS  =
NVCCLIBS     =
CUDAROOT     =
CUDACFLAGS   =
NVCCFLAGS    = -I $(CUDAROOT)/targets/x86_64-linux/include/ \
-Xcompiler -fPIC \
-Xcudafe --diag_suppress=unrecognized_attribute \
-gencode arch=compute_35,code="compute_35" \
-gencode arch=compute_52,code="compute_52" \
-gencode arch=compute_60,code="compute_60" \
-lineinfo \
-ccbin $(CXX) -DFAISS_USE_FLOAT16

OS = $(shell uname -s)

SHAREDEXT   = so
SHAREDFLAGS = -shared

ifeq ($(OS),Darwin)
        SHAREDEXT   = dylib
        SHAREDFLAGS = -dynamiclib -undefined dynamic_lookup
endif

MKDIR_P      = /opt/local/bin/gmkdir -p
PYTHON       = python
SWIG         = swig

#prefix      ?= /Users/ailzhang/miniconda3/envs/faiss-build
prefix      ?= /usr/local
exec_prefix ?= ${prefix}
libdir       = ${exec_prefix}/lib
includedir   = ${prefix}/include
