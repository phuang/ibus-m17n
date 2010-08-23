/* vim:set et sts=4: */
#ifndef __M17NUTIL_H__
#define __M17NUTIL_H__

#include <ibus.h>
#include <m17n.h>

#define INVALID_COLOR ((guint)-1)
/* default configuration */
#define PREEDIT_FOREGROUND 0x00000000
#define PREEDIT_BACKGROUND 0x00c8c8f0

void           ibus_m17n_init_common       (void);
void           ibus_m17n_init              (IBusBus     *bus);
GList         *ibus_m17n_list_engines      (void);
IBusComponent *ibus_m17n_get_component     (void);
gchar         *ibus_m17n_mtext_to_utf8     (MText       *text);
gunichar      *ibus_m17n_mtext_to_ucs4     (MText       *text,
                                            glong       *nchars);
guint          ibus_m17n_parse_color       (const gchar *hex);
gboolean       ibus_m17n_preedit_highlight (const gchar *engine_name);
#endif
