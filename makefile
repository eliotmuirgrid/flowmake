# Wildcard matching to figure out where sources are based on the DIRS variable
OBJEXT :=.o
LIBEXT :=a

SEARCH  := $(foreach dir, $(DIRS),../$(dir)/*.cpp ../$(dir)/*.c) *.c
SOURCES := $(wildcard $(SEARCH))
OBJECTS := $(subst .c,$(OBJEXT), $(SOURCES))
DEPENDS := $(subst $(OBJEXT),.d, $(OBJECTS))

OBJECTS := $(OBJECTS) $(OBJECTS_EXTRA)

# If a target is not define, default to test
TARGET ?= test

CFLAGS   := -MMD -I../ 
CCACHE   := $(shell command -v ccache  2> /dev/null)
ifdef CCACHE
   CC  := ccache $(CC)
endif

# Define our clean rule - we try to use the native DEL under windows
RMLIST   := $(foreach dir, $(DIRS),../$(dir)/*.o ../$(dir)/*.d) *.d *.o *~ $(TARGET)

$(TARGET): $(OBJECTS) $(SOURCES) 
	$(CC) $(OBJECTS) -o $@

info:
	echo "Making: " $(TARGET)
	@echo CC      = $(CC)
	@echo SEARCH  = $(SEARCH)
	@echo SOURCES = $(SOURCES)
	@echo OBJECTS = $(OBJECTS)
	@echo DEPENDS = $(DEPENDS)
	@echo CXXFLAGS = $(CXXFLAGS)
	@echo PLATFORM = $(PLATFORM)

all: $(TARGET)

# Use double colon rule for clean so regular makefiles can perform addition cleaning. 
clean::
	-$(RM) $(RMLIST)

-include $(DEPENDS)
