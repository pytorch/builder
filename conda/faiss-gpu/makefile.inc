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

###########################################################################
# Cuda GPU flags
###########################################################################

CUDAROOT ?= /usr/local/cuda
CUDA_LIB ?= $(CUDAROOT)/lib64
CUDA_INC ?= $(CUDAROOT)/include
NVCC ?= $(CUDAROOT)/bin/nvcc

CUDA_VERSION = $(shell ls $(CUDA_LIB)/libcudart.so.* | head -1 | rev | cut -d "." -f -2 | rev)
CUDA_MAJOR = $(shell echo $(CUDA_VERSION) | cut -d "." -f 1)
CUDA_MINOR = $(shell echo $(CUDA_VERSION) | cut -d "." -f 2)

CUDACFLAGS=-I$(CUDA_INC)

ifeq ($(CUDA_MAJOR), 8)
NVCCFLAGS= -I $(CUDAROOT)/targets/x86_64-linux/include/ \
   -Xcompiler -fPIC \
   -Xcudafe --diag_suppress=unrecognized_attribute \
   -gencode arch=compute_35,code="compute_35" \
   -gencode arch=compute_52,code="compute_52" \
   -gencode arch=compute_60,code="compute_60" \
   -gencode arch=compute_61,code="compute_61" \
   -lineinfo \
   -ccbin $(CXX) -DFAISS_USE_FLOAT16
else
# CUDA 9
NVCCFLAGS= -I $(CUDAROOT)/targets/x86_64-linux/include/ \
   -Xcompiler -fPIC \
   -Xcudafe --diag_suppress=unrecognized_attribute \
   -gencode arch=compute_35,code="compute_35" \
   -gencode arch=compute_52,code="compute_52" \
   -gencode arch=compute_60,code="compute_60" \
   -gencode arch=compute_61,code="compute_61" \
   -gencode arch=compute_70,code="compute_70" \
   -lineinfo \
   -ccbin $(CXX) -DFAISS_USE_FLOAT16
endif

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

prefix      ?= /usr/local
exec_prefix ?= ${prefix}
libdir       = ${exec_prefix}/lib
includedir   = ${prefix}/include
