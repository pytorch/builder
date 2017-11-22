CC=g++

CFLAGS=-fPIC -m64 -Wall -g -O3 -mavx -msse4 -mpopcnt -fopenmp -Wno-sign-compare -std=c++11 -fopenmp
LDFLAGS=-g -fPIC  -fopenmp

# common linux flags
SHAREDEXT=so
SHAREDFLAGS=-shared
FAISSSHAREDFLAGS=-shared

BLASBASEFLAGS=-L$(PREFIX)/lib -lmkl_intel_lp64 -lmkl_core -lmkl_gnu_thread -lmkl_rt -lmkl_def -ldl -lpthread
BLASLDFLAGS=-Wl,--no-as-needed $(BLASBASEFLAGS)
BLASCFLAGS=-DFINTEGER=int

SWIGEXEC=swig
NUMPY_INCLUDE = $(shell python -c "import numpy as np; print(np.get_include())")
PYTHON_INCLUDE = $(shell python -c "from sysconfig import get_paths; print(get_paths()['include'])")
PYTHONCFLAGS =-I$(PYTHON_INCLUDE) -I$(NUMPY_INCLUDE)


###########################################################################
# Cuda GPU flags
###########################################################################
# a C++ compiler that supports c++11
CC11=g++

CUDA_HOME ?= /usr/local/cuda
CUDA_LIB ?= $(CUDA_HOME)/lib64
CUDA_INC ?= $(CUDA_HOME)/include
NVCC ?= $(CUDA_HOME)/bin/nvcc

CUDA_VERSION = $(shell ls $(CUDA_LIB)/libcudart.so.* | head -1 | rev | cut -d "." -f -2 | rev)
CUDA_MAJOR = $(shell echo $(CUDA_VERSION) | cut -d "." -f 1)
CUDA_MINOR = $(shell echo $(CUDA_VERSION) | cut -d "." -f 2)

CUDACFLAGS=-I$(CUDA_INC)

ifeq ($(CUDA_MAJOR), 8)
NVCCFLAGS= $(CUDAFLAGS) \
   -I $(CUDA_INC) \
   -Xcompiler -fPIC \
   -Xcudafe --diag_suppress=unrecognized_attribute \
   -gencode arch=compute_35,code="compute_35" \
   -gencode arch=compute_52,code="compute_52" \
   -gencode arch=compute_60,code="compute_60" \
   -gencode arch=compute_61,code="compute_61" \
   --std c++11 -lineinfo \
   -ccbin $(CC11) -DFAISS_USE_FLOAT16
else
# CUDA 9
NVCCFLAGS= $(CUDAFLAGS) \
   -I $(CUDA_HOME)/targets/x86_64-linux/include/ \
   -Xcompiler -fPIC \
   -Xcudafe --diag_suppress=unrecognized_attribute \
   -gencode arch=compute_35,code="compute_35" \
   -gencode arch=compute_52,code="compute_52" \
   -gencode arch=compute_60,code="compute_60" \
   -gencode arch=compute_61,code="compute_61" \
   -gencode arch=compute_70,code="compute_70" \
   --std c++11 -lineinfo \
   -ccbin $(CC11) -DFAISS_USE_FLOAT16
endif

# BLAS LD flags for nvcc (used to generate an executable)
# if BLASLDFLAGS contains several flags, each one may
# need to be prepended with -Xlinker
BLASLDFLAGSNVCC=-Xlinker --no-as-needed $(BLASBASEFLAGS)

# Same, but to generate a .so
BLASLDFLAGSSONVCC=$(BLASLDFLAGSNVCC)
