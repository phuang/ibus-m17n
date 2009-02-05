/* vim:set et sts=4: */
#ifndef __M17NUTIL_H__
#define __M17NUTIL_H__

#include <ibus.h>
#include <m17n.h>

void             ibus_m17n_init             (void);
GList           *ibus_m17n_list_engines     (void);
IBusComponent   *ibus_m17n_get_component    (void);
gchar           *ibus_m17n_mtext_to_utf8    (MText      *text);
gunichar        *ibus_m17n_mtext_to_ucs4    (MText      *text);
#endif
