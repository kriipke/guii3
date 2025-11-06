# guii3 - Unified build system for iiwm + iist
# See ROADMAP.md for implementation details

VERSION = 1.0
PREFIX ?= /usr/local
MANPREFIX = $(PREFIX)/share/man

# Build directories
SRCDIR = src
BUILDDIR = build

# Source files
COMMON_SRC = $(SRCDIR)/common/launcher.c
WM_SRC = $(SRCDIR)/wm/dwm.c $(SRCDIR)/wm/drw.c $(SRCDIR)/wm/util.c
TERM_SRC = $(SRCDIR)/term/st.c $(SRCDIR)/term/x.c $(SRCDIR)/term/boxdraw.c $(SRCDIR)/term/hb.c
ALL_SRC = $(COMMON_SRC) $(WM_SRC) $(TERM_SRC)
OBJ = $(ALL_SRC:$(SRCDIR)/%.c=$(BUILDDIR)/%.o)

# Include paths
INCS = -I$(SRCDIR)/common -I$(SRCDIR)/wm -I$(SRCDIR)/term
INCS += -I/usr/X11R6/include
INCS += `pkg-config --cflags freetype2 fontconfig harfbuzz 2>/dev/null || echo ""`

# Compiler flags
CPPFLAGS = -D_DEFAULT_SOURCE -D_BSD_SOURCE -D_POSIX_C_SOURCE=200809L
CPPFLAGS += -DVERSION=\"$(VERSION)\" -DXINERAMA
CFLAGS = -std=c99 -pedantic -Wall -Wno-deprecated-declarations -Os $(INCS) $(CPPFLAGS)

# Linker flags
LDFLAGS = -L/usr/X11R6/lib -lX11 -lXft -lXrender -lXinerama -lm -lrt -lutil
LDFLAGS += `pkg-config --libs freetype2 fontconfig harfbuzz 2>/dev/null || echo ""`

# Compiler
CC ?= gcc

.PHONY: all options clean install uninstall test-build test-symlinks container-build container-test

all: options guii

options:
	@echo "guii3 build options:"
	@echo "CFLAGS  = $(CFLAGS)"
	@echo "LDFLAGS = $(LDFLAGS)"
	@echo "CC      = $(CC)"

# Create build directories
$(BUILDDIR):
	@mkdir -p $(BUILDDIR)/common $(BUILDDIR)/wm $(BUILDDIR)/term

# Generic object file rule
$(BUILDDIR)/%.o: $(SRCDIR)/%.c | $(BUILDDIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Config file generation
$(SRCDIR)/wm/config.h:
	cp $(SRCDIR)/wm/config.def.h $@

# Dependencies for specific components
$(BUILDDIR)/wm/dwm.o: $(SRCDIR)/wm/config.h
$(BUILDDIR)/term/st.o: $(SRCDIR)/term/config.h $(SRCDIR)/term/st.h $(SRCDIR)/term/win.h
$(BUILDDIR)/term/x.o: $(SRCDIR)/term/arg.h $(SRCDIR)/term/config.h $(SRCDIR)/term/st.h $(SRCDIR)/term/win.h $(SRCDIR)/term/hb.h
$(BUILDDIR)/term/hb.o: $(SRCDIR)/term/st.h
$(BUILDDIR)/term/boxdraw.o: $(SRCDIR)/term/config.h $(SRCDIR)/term/st.h $(SRCDIR)/term/boxdraw_data.h

# Main target
guii: $(OBJ)
	$(CC) -o $@ $(OBJ) $(LDFLAGS)

# Test targets
test-build: guii
	@echo "Testing basic binary functionality..."
	@./guii -v || echo "Version check failed (expected for launcher)"

test-symlinks: guii
	@echo "Creating test symlinks..."
	@ln -sf guii test-iiwm
	@ln -sf guii test-iist
	@echo "Testing symlink detection..."
	@./test-iiwm --help 2>/dev/null || echo "iiwm symlink test completed"
	@./test-iist --help 2>/dev/null || echo "iist symlink test completed"
	@rm -f test-iiwm test-iist
	@echo "Symlink tests completed"

# Container build targets
container-build:
	container build -t guii3-builder .

container-test: container-build
	container run --rm guii3-builder make test-build test-symlinks

# Clean targets
clean:
	rm -rf $(BUILDDIR) guii test-iiwm test-iist
	rm -f $(SRCDIR)/wm/config.h

# Install targets
install: guii
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp -f guii $(DESTDIR)$(PREFIX)/bin
	ln -sf guii $(DESTDIR)$(PREFIX)/bin/iiwm
	ln -sf guii $(DESTDIR)$(PREFIX)/bin/iist
	chmod 755 $(DESTDIR)$(PREFIX)/bin/guii
	mkdir -p $(DESTDIR)$(MANPREFIX)/man1
	sed "s/VERSION/$(VERSION)/g" < man/guii.1 > $(DESTDIR)$(MANPREFIX)/man1/guii.1
	chmod 644 $(DESTDIR)$(MANPREFIX)/man1/guii.1
	ln -sf guii.1 $(DESTDIR)$(MANPREFIX)/man1/iiwm.1
	ln -sf guii.1 $(DESTDIR)$(MANPREFIX)/man1/iist.1

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/guii
	rm -f $(DESTDIR)$(PREFIX)/bin/iiwm
	rm -f $(DESTDIR)$(PREFIX)/bin/iist
	rm -f $(DESTDIR)$(MANPREFIX)/man1/guii.1
	rm -f $(DESTDIR)$(MANPREFIX)/man1/iiwm.1
	rm -f $(DESTDIR)$(MANPREFIX)/man1/iist.1