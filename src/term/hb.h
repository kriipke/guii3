#ifndef ST_HB_H
#define ST_HB_H

#include <X11/Xft/Xft.h>
#include <harfbuzz/hb.h>
#include <harfbuzz/hb-ft.h>

void hbunloadfonts();
void hbtransform(XftGlyphFontSpec *, const Glyph *, size_t, int, int);

#endif /* ST_HB_H */

