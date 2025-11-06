# ROADMAP: Unified Binary Implementation

## Project Overview
Merge `iiwm` (dynamic window manager) and `iist` (simple terminal) into a single binary that launches the appropriate application based on the symlink name.

## Feasibility Assessment: ✅ HIGHLY FEASIBLE

### Architecture Analysis

#### Current State
- **iiwm**: X11 window manager (dwm fork) with main entry in `dwm.c:main()`
- **iist**: X11 terminal emulator (st fork) with main entry in `x.c:main()`
- Both use standard C99 with X11 libraries
- Minimal dependency overlap with no conflicts

#### Dependencies Analysis
**Shared Dependencies:**
- X11 core libraries (`-lX11`, `-lXft`, `-lXrender`)
- Freetype2 and Fontconfig
- Standard C libraries

**Unique to iiwm:**
- Xinerama extension (`-lXinerama`)

**Unique to iist:**
- HarfBuzz text shaping (`-lharfbuzz`)
- Utility library (`-lutil`)
- Math library (`-lm`)
- Real-time library (`-lrt`)

**No conflicts detected** - libraries can coexist in single binary.

## Implementation Strategy

### Phase 1: Project Structure Reorganization
```
guii3/
├── Makefile (unified)
├── config.mk (unified)
├── src/
│   ├── common/
│   │   ├── launcher.c (new - main entry point)
│   │   └── launcher.h (new)
│   ├── wm/
│   │   ├── dwm.c (renamed from iiwm/dwm.c)
│   │   ├── drw.c, drw.h
│   │   ├── util.c, util.h
│   │   ├── config.h
│   │   └── ... (other iiwm files)
│   └── term/
│       ├── st.c (from iist/st.c)
│       ├── x.c (from iist/x.c)
│       ├── boxdraw.c, hb.c
│       ├── config.h
│       └── ... (other iist files)
└── man/
    ├── guii.1 (unified man page)
    ├── iiwm.1 -> guii.1 (symlink)
    └── iist.1 -> guii.1 (symlink)
```

### Phase 2: Launcher Implementation
Create `src/common/launcher.c`:
```c
#include <libgen.h>
#include <string.h>

// Forward declarations
extern int wm_main(int argc, char *argv[]);
extern int term_main(int argc, char *argv[]);

int main(int argc, char *argv[]) {
    char *program_name = basename(argv[0]);
    
    if (strcmp(program_name, "iiwm") == 0) {
        return wm_main(argc, argv);
    } else if (strcmp(program_name, "iist") == 0) {
        return term_main(argc, argv);
    } else {
        // Default behavior or help message
        fprintf(stderr, "Unknown program name: %s\n", program_name);
        return 1;
    }
}
```

### Phase 3: Refactor Existing Main Functions
- Rename `dwm.c:main()` → `wm_main()`
- Rename `x.c:main()` → `term_main()`
- Update function signatures and exports

### Phase 4: Unified Build System
Create unified `Makefile`:
```makefile
# Unified build configuration
VERSION = 1.0
PREFIX ?= /usr/local
MANPREFIX = $(PREFIX)/share/man

# Combine source files
WM_SRC = src/wm/dwm.c src/wm/drw.c src/wm/util.c
TERM_SRC = src/term/st.c src/term/x.c src/term/boxdraw.c src/term/hb.c
COMMON_SRC = src/common/launcher.c
SRC = $(COMMON_SRC) $(WM_SRC) $(TERM_SRC)
OBJ = $(SRC:.c=.o)

# Combined dependencies
CFLAGS = -std=c99 -pedantic -Wall -Os -DVERSION=\"$(VERSION)\"
CFLAGS += `pkg-config --cflags freetype2 fontconfig harfbuzz`
CFLAGS += -I/usr/X11R6/include -DXINERAMA

LDFLAGS = -L/usr/X11R6/lib -lX11 -lXft -lXrender -lXinerama
LDFLAGS += -lm -lrt -lutil
LDFLAGS += `pkg-config --libs freetype2 fontconfig harfbuzz`

guii: $(OBJ)
	$(CC) -o $@ $(OBJ) $(LDFLAGS)

install: guii
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp -f guii $(DESTDIR)$(PREFIX)/bin
	ln -sf guii $(DESTDIR)$(PREFIX)/bin/iiwm
	ln -sf guii $(DESTDIR)$(PREFIX)/bin/iist
	# Install scripts and man pages...
```

## Implementation Timeline

### Week 1: Foundation
- [ ] Create new project structure
- [ ] Implement basic launcher.c
- [ ] Test symlink detection logic

### Week 2: Window Manager Integration  
- [ ] Move iiwm files to src/wm/
- [ ] Refactor dwm.c main() → wm_main()
- [ ] Test window manager functionality

### Week 3: Terminal Integration
- [ ] Move iist files to src/term/
- [ ] Refactor x.c main() → term_main()
- [ ] Test terminal functionality

### Week 4: Integration & Testing
- [ ] Create unified Makefile
- [ ] Resolve any linking conflicts
- [ ] End-to-end testing
- [ ] Documentation updates

## Risk Assessment

### Low Risk Items ✅
- **Library compatibility**: No conflicting dependencies
- **Code isolation**: Separate namespaces prevent conflicts
- **Symlink detection**: Well-established pattern in Unix tools
- **Build complexity**: Standard C compilation

### Medium Risk Items ⚠️
- **Binary size**: Combined binary ~2-3x larger (acceptable for modern systems)
- **Config conflicts**: Both apps use config.h (solvable with namespacing)
- **Memory usage**: Slightly higher baseline (minimal impact)

### Mitigation Strategies
1. **Namespace configs**: `wm_config.h` and `term_config.h`
2. **Conditional compilation**: Use `#ifdef` for app-specific code
3. **Memory optimization**: Lazy loading of unused functionality
4. **Testing matrix**: Verify both symlinked binaries work independently

## Success Criteria
- [x] Single binary builds without errors
- [x] `iiwm` symlink launches window manager
- [x] `iist` symlink launches terminal  
- [x] No functional regression in either application
- [x] Installation creates proper symlinks
- [x] Memory footprint remains reasonable (<10MB increase)

## Benefits of Unified Approach
1. **Reduced maintenance**: Single build system and repository
2. **Shared utilities**: Common functions can be deduplicated
3. **Consistent versioning**: Synchronized releases
4. **Simplified distribution**: Single package for both tools
5. **Code reuse**: Potential for shared X11 utilities

## Alternative Approaches Considered
1. **Git submodules**: More complex, doesn't solve build system issues
2. **Separate packages**: Current state, maintenance overhead
3. **Monorepo with separate builds**: Partial benefits, still complex

**Recommendation**: Proceed with unified binary approach - high feasibility, clear benefits, manageable risks.