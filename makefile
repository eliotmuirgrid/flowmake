# We use wildcard matching to figure out where sources are based on the DIRS
# environmental variable
ifdef OS
   OBJEXT :=.obj
   LIBEXT :=lib
else
   OBJEXT :=.o
   LIBEXT :=a
endif

SEARCH  := $(foreach dir, $(DIRS),../$(dir)/*.cpp ../$(dir)/*.c) *.c *.cpp
SOURCES := $(wildcard $(SEARCH))
OBJECTS := $(subst .cpp,$(OBJEXT), $(SOURCES))
OBJECTS := $(subst .c,$(OBJEXT), $(OBJECTS))
DEPENDS := $(subst $(OBJEXT),.d, $(OBJECTS))

OBJECTS := $(OBJECTS) $(OBJECTS_EXTRA)

ifdef OS # Windows
    PLATFORM := Windows
else # POSIX
    CP := cp
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux) # Linux
        PLATFORM := Linux
    else ifeq ($(UNAME_S),Darwin) # macOS
        PLATFORM := macOS
        # Mac architectures: arm64 (Apple M series) or x86_64 (intel)
        MAC_ARCH := $(shell uname -m)
    else # Unsupported
        $(error "Current platform not supported")
    endif
endif

# If a target is not define, default to test
TARGET ?= test
ifeq (${PLATFORM},Windows)
    TARGET := $(TARGET).exe
endif

# Set MAC_TARGET to '-target x86_64-apple-macos13' for Intel
# Set MAC_TARGET to '-target arm64-apple-macos13' for ARM
#MAC_TARGET ?= -target x86_64-apple-macos13

# Switch on the first form to enable Address Sanitizer IX-2379
# `make ADDRESS_SANITIZE=-fsanitize=address` to enable address sanitizer
ADDRESS_SANITIZE ?=

# Conditionally add -DIFW_RELEASE=1 to the CXX flags for IX-2935.
TRACE_LICENSE :=
ifneq ($(IFW_RELEASE),)
    TRACE_LICENSE := -DIFW_RELEASE=1
endif

# /Zi gives better symbols for stack traces,but bigger PDB file - it also makes the windows build slower see IX-1944
# /FS is needed to allow parallel writes to PDB files with /Zi
ifdef OS # Windows
    CC      := ccache cl /nologo
    OBJECTS := $(patsubst %Posix.obj,,$(OBJECTS))   # Remove *Posix.* files - these are for Mac OS X and Linux
    DEFAULT_LDFLAGS := netapi32.lib ws2_32.lib Shell32.lib advapi32.lib Iphlpapi.lib gdi32.lib User32.lib crypt32.lib dbghelp.lib shlwapi.lib htmlhelp.lib version.lib
    CXXFLAGS := /MT /Zi /FS $(TRACE_LICENSE)
else	# POSIX
    OBJECTS  := $(patsubst %Windows.o,,$(OBJECTS))  # Remove *Windows.* files - these are windows specific
    OBJECTS  := $(patsubst %win32.o,,$(OBJECTS))    # Remove *win32.* files - these are windows specific
    CFLAGS   := -MMD -I../ -Werror
    CXXFLAGS := -MMD -I../ -Werror -std=c++11 $(TRACE_LICENSE) $(ADDRESS_SANITIZE)
    DEFAULT_LDFLAGS := -lstdc++ -lm $(ADDRESS_SANITIZE)
    CCACHE   := $(shell command -v ccache  2> /dev/null)
    ifdef CCACHE
       CC  := ccache $(CC)
       CXX := ccache $(CXX)
    endif
    ifeq (${PLATFORM},Linux)        # Linux See ticket IX-1462 for dicussion on -static option
        #DEFAULT_LDFLAGS += -ldl -lpthread -static
        DEFAULT_LDFLAGS += -ldl -lpthread -rdynamic     # -rdynamic enables COLbacktrace() to print function names instead of pointers
    else ifeq (${PLATFORM},macOS)   # macOS
        CXXFLAGS += -Wno-unused-value
        # Allows targeting Intel mac when build on an ARM mac
        CPPFLAGS += $(MAC_TARGET)
        DEFAULT_LDFLAGS += $(MAC_TARGET)
    endif
endif

# Windows build command
%.obj: %.cpp
	$(CC) -I../ -I../LUAC -I../LUACOM $(CXXFLAGS) -I../ZLIB -I../DB/ODBCSQLNative /EHsc -c $< /Fo$@
%.obj: %.c
	$(CC) -I../ $(CXXFLAGS) -I../ZLIB -c $< /Fo$@

%.oo:	%.mm
	clang $(MAC_TARGET) -c $< -o $@

# Define our clean rule - we try to use the native DEL under windows
RMLIST   := $(foreach dir, $(DIRS),../$(dir)/*.obj ../$(dir)/*.o ../$(dir)/*.d) *.d *.o *.obj *~ $(TARGET)
ifdef ComSpec  # ComSpec is just defined for Windows
	RM := del /s /q
	RMLIST := $(subst /,\, $(RMLIST))
    CP=copy
endif

TARGET_PDB := $(shell git rev-parse HEAD).pdb

$(TARGET): $(OBJECTS) $(SOURCES) 
ifdef OS # Windows - IX-2968 $(OBJECTS) is too long to be passed directly into the LINK command. Serialize its contents to a file and use that file when linking instead.
	@for %%i in ($(OBJECTS)) do @echo %%i >> objectFiles.txt 
	LINK /nologo @objectFiles.txt /DEBUG:FULL $(LIB_LDFLAGS) $(DEFAULT_LDFLAGS) /PDB:$(TARGET_PDB) /PDBALTPATH:$(TARGET_PDB) /out:$@
	del objectFiles.txt
else
	$(CC) $(OBJECTS)  $(LIB_LDFLAGS) $(DEFAULT_LDFLAGS) -o $@
endif

info:
	echo "Making: " $(TARGET)
	@echo CC      = $(CC)
	@echo SEARCH  = $(SEARCH)
	@echo SOURCES = $(SOURCES)
	@echo OBJECTS = $(OBJECTS)
	@echo DEPENDS = $(DEPENDS)
	@echo SSLFOUND = $(SSLFOUND)
	@echo LIB_LDFLAGS = $(LIB_LDFLAGS)
	@echo CXXFLAGS = $(CXXFLAGS)
	@echo SSLSEARCH = $(SSLSEARCH)
	@echo PLATFORM = $(PLATFORM)

all: $(TARGET)

# Use double colon rule for clean so regular makefiles can perform addition cleaning. See Iguana makefile for example
# https://www.gnu.org/software/make/manual/html_node/Double_002dColon.html
clean::
ifdef OS # Windows
	cd ../ && git clean -dfx
else
	-$(RM) $(RMLIST)
endif

-include $(DEPENDS)
