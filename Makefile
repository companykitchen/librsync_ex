# Based on https://github.com/potatosalad/elixirconf2017/tree/master/apps/latency/c_src/Makefile
# which is in turn based on c_src.mk from erlang.mk (https://github.com/ninenines/erlang.mk/blob/master/plugins/c_src.mk)

BASEDIR :=$(shell pwd)
PRIV_DIR ?= $(BASEDIR)/priv

# Configuration
C_SRC_DIR ?= $(BASEDIR)/c_src
C_SRC_ENV ?= $(C_SRC_DIR)/elixir-env.mk

C_SRC_LIBRSYNC_NIF ?= $(PRIV_DIR)/librsync_ex_nif

# "erl" command used for fetching erl include/lib directory locations
ERL = erl +A0 -noinput -boot start_clean

# Platform detection.
ifeq ($(PLATFORM),)
UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Linux)
PLATFORM = linux
else ifeq ($(UNAME_S),Darwin)
PLATFORM = darwin
else ifeq ($(UNAME_S),SunOS)
PLATFORM = solaris
else ifeq ($(UNAME_S),GNU)
PLATFORM = gnu
else ifeq ($(UNAME_S),FreeBSD)
PLATFORM = freebsd
else ifeq ($(UNAME_S),NetBSD)
PLATFORM = netbsd
else ifeq ($(UNAME_S),OpenBSD)
PLATFORM = openbsd
else ifeq ($(UNAME_S),DragonFly)
PLATFORM = dragonfly
else ifeq ($(shell uname -o),Msys)
PLATFORM = msys2
else
$(error Unable to detect platform. Please open a ticket with the output of uname -a.)
endif

export PLATFORM
endif

# System type and C compiler/flags
C_SRC_SHARED_EXTENSION ?= .so
C_SRC_EXECUTABLE_EXTENSION ?=

C_SRC_LIBRSYNC_NIF_LIB = $(C_SRC_LIBRSYNC_NIF)$(C_SRC_SHARED_EXTENSION)

ifeq ($(PLATFORM),msys2)
# We hardcode the compiler used on MSYS2. The default CC=cc does
# not produce working code. The "gcc" MSYS2 package also doesn't.
	CC = /mingw64/bin/gcc
	CFLAGS ?= -O3 -std=c11 -finline-functions -fstack-protector -Wall -Wmissing-prototypes
	CXXFLAGS ?= -O3 -std=c++11 -finline-functions -fstack-protector -Wall
else ifeq ($(PLATFORM),darwin)
  CC ?= cc
  CFLAGS ?= -O3 -std=c11 -arch x86_64 -fPIC -fstack-protector -Wall -Wmissing-prototypes
	CXXFLAGS ?= -O3 -std=c++11 -arch x86_64 -fPIC -fstack-protector -Wall
  LDFLAGS ?= -arch x86_64 -flat_namespace -undefined suppress
else ifeq ($(PLATFORM),freebsd)
	CC ?= cc
	CFLAGS ?= -O3 -std=c11 -finline-functions -fstack-protector -Wall -Wmissing-prototypes
	CXXFLAGS ?= -O3 -std=c++11 -finline-functions -fstack-protector -Wall
else ifeq ($(PLATFORM),linux)
	CC ?= gcc
	CFLAGS ?= -O3 -std=c11 -finline-functions -fstack-protector -Wall -Wmissing-prototypes
	CXXFLAGS ?= -O3 -std=c++11 -finline-functions -fstack-protector -Wall
else ifeq ($(PLATFORM),solaris)
	CC ?= cc
	CFLAGS ?= -O3 -std=c11 -finline-functions -fstack-protector -Wall -Wmissing-prototypes -fPIC
	CXXFLAGS ?= -O3 -std=c++11 -finline-functions -fstack-protector -Wall -fPIC
	LDLIBS ?= -latomic
endif

ifneq ($(PLATFORM),msys2)
	CFLAGS += -fPIC
	CXXFLAGS += -fPIC
endif

CFLAGS += -I"$(ERTS_INCLUDE_DIR)" -I"$(ERL_INTERFACE_INCLUDE_DIR)"
CXXFLAGS += -I"$(ERTS_INCLUDE_DIR)" -I"$(ERL_INTERFACE_INCLUDE_DIR)"

LDLIBS += -L"$(ERL_INTERFACE_LIB_DIR)" -lerl_interface -lei -lrsync

# Verbosity.
ifeq ($(VERBOSE),)
  V := 0
else
  V := $(VERBOSE)
endif

verbose_0 = @
verbose_2 = set -x;
verbose = $(verbose_$(V))

c_verbose_0 = @echo " C     " $(?F);
c_verbose = $(c_verbose_$(V))

cpp_verbose_0 = @echo " CPP   " $(?F);
cpp_verbose = $(cpp_verbose_$(V))

dep_verbose_0 = @echo " DEP   " $(1);
dep_verbose_2 = set -x;
dep_verbose = $(dep_verbose_$(V))

gen_verbose_0 = @echo " GEN   " $@;
gen_verbose_2 = set -x;
gen_verbose = $(gen_verbose_$(V))

link_verbose_0 = @echo " LD    " $(@F);
link_verbose = $(link_verbose_$(V))

# Targets.
core_find = $(if $(wildcard $1),$(shell find $(1:%/=%) -type f -name $(subst *,\*,$2)))
ifeq ($(PLATFORM),msys2)
core_native_path = $(subst \,\\\\,$(shell cygpath -w $1))
else
core_native_path = $1
endif

ifeq ($(C_SRC_LIBRSYNC_NIF_SOURCES),)
	C_SRC_LIBRSYNC_NIF_SOURCES := $(sort $(foreach pat,*.c *.C *.cc *.cpp,$(call core_find,$(C_SRC_DIR)/,$(pat))))
endif

C_SRC_LIBRSYNC_NIF_OBJECTS = $(addsuffix .o, $(basename $(C_SRC_LIBRSYNC_NIF_SOURCES)))

COMPILE_C = $(c_verbose) $(CC) $(CFLAGS) $(CPPFLAGS) -c
COMPILE_CPP = $(cpp_verbose) $(CXX) $(CXXFLAGS) $(CPPFLAGS) -c

librsync-nif :: $(C_SRC_ENV) $(C_SRC_LIBRSYNC_NIF_LIB)

$(C_SRC_LIBRSYNC_NIF_LIB): $(C_SRC_LIBRSYNC_NIF_OBJECTS)
	$(verbose) mkdir -p $(BASEDIR)/priv
	$(link_verbose) $(CC) $(C_SRC_LIBRSYNC_NIF_OBJECTS) $(LDFLAGS) -shared $(LDLIBS) -o $(C_SRC_LIBRSYNC_NIF_LIB)

%.o: %.c
	$(COMPILE_C) $(OUTPUT_OPTION) $<

%.o: %.cc
	$(COMPILE_CPP) $(OUTPUT_OPTION) $<

%.o: %.C
	$(COMPILE_CPP) $(OUTPUT_OPTION) $<

%.o: %.cpp
	$(COMPILE_CPP) $(OUTPUT_OPTION) $<

clean:: clean-c_src

clean-c_src:
	$(gen_verbose) rm -f $(C_SRC_LIBRSYNC_NIF_LIB) $(C_SRC_LIBRSYNC_NIF_OBJECTS)

$(C_SRC_ENV):
	$(verbose) $(ERL) -eval "file:write_file(\"$(call core_native_path,$(C_SRC_ENV))\", \
	  io_lib:format( \
	    \"ERTS_INCLUDE_DIR ?= ~s/erts-~s/include/~n\" \
	    \"ERL_INTERFACE_INCLUDE_DIR ?= ~s~n\" \
	    \"ERL_INTERFACE_LIB_DIR ?= ~s~n\", \
	    [code:root_dir(), erlang:system_info(version), \
	    code:lib_dir(erl_interface, include), \
	    code:lib_dir(erl_interface, lib)])), \
	  halt()."

distclean:: distclean-env

distclean-env:
	$(gen_verbose) rm -f $(C_SRC_ENV)

clang-format-all:
	$(gen_verbose) clang-format -i c_src/*.h c_src/*.c

-include $(C_SRC_ENV)
