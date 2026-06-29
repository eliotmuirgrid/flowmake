# Wildcard matching to figure out where sources are based on the DIRS variable
OBJEXT  := .o
LIBEXT  := a

# Safely expand search paths
SEARCH  := $(foreach dir, $(DIRS), ../$(dir)/*.cpp ../$(dir)/*.c) *.c
SOURCES := $(wildcard $(SEARCH))

# Use patsubst instead of subst to prevent corrupting folder names containing ".c"
OBJECTS := $(patsubst %.c, %$(OBJEXT), $(SOURCES))
DEPENDS := $(patsubst %$(OBJEXT), %.o.d, $(OBJECTS))

OBJECTS := $(OBJECTS) $(OBJECTS_EXTRA)

# If a target is not defined, default to test.com
TARGET  ?= test.com

CFLAGS  := -MMD -MP -I../ 
CC      := ccache $(FLOW_TOOL_COSMOPOLITAN)/bin/cosmocc  

# Define our clean list
RMLIST  := $(foreach dir, $(DIRS), ../$(dir)/*.o ../$(dir)/*.d) *.d *.o *~ *.elf *.dbg $(TARGET)

.PHONY: all info clean

all: $(TARGET)

# FIXED: Removed $(SOURCES) from this line to stop infinite relinking
$(TARGET): $(OBJECTS) 
	$(CC) $(OBJECTS) -o $@

# ADDED: Explicit rule to compile C files using cosmocc and CFLAGS
%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

info:
	@echo "Making: " $(TARGET)
	@echo CC      = $(CC)
	@echo SEARCH  = $(SEARCH)
	@echo SOURCES = $(SOURCES)
	@echo OBJECTS = $(OBJECTS)
	@echo DEPENDS = $(DEPENDS)

# Use double colon rule for clean so regular makefiles can perform additional cleaning. 
clean::
	-$(RM) $(RMLIST)

-include $(DEPENDS)

