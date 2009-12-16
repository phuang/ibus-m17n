/* vim:set et sts=4: */
#include <string.h>
#include "m17nutil.h"

#define N_(text) text

static MConverter *utf8_converter = NULL;
static MConverter *utf32_converter = NULL;

static const gchar *keymap[] = {
    "m17n:as:phonetic",
    "m17n:bn:inscript",
    "m17n:gu:inscript",
    "m17n:hi:inscript",
    "m17n:kn:kgp",
    "m17n:ks:kbd",
    "m17n:mai:inscript",
    "m17n:ml:inscript",
    "m17n:mr:inscript",
    "m17n:ne:rom",
    "m17n:or:inscript",
    "m17n:pa:inscript",
    "m17n:sa:harvard-kyoto",
    "m17n:sd:inscript",
    "m17n:si:wijesekera",
    "m17n:ta:tamil99",
    "m17n:te:inscript"
};

void
ibus_m17n_init (void)
{
    M17N_INIT ();

    if (utf8_converter == NULL) {
        utf8_converter = mconv_buffer_converter (Mcoding_utf_8, NULL, 0);
    }

    if (utf32_converter == NULL) {
        utf32_converter = mconv_buffer_converter (Mcoding_utf_32, NULL, 0);
    }
}

gchar *
ibus_m17n_mtext_to_utf8 (MText *text)
{
    gint bufsize;
    gchar *buf;

    if (text == NULL)
        return NULL;

    mconv_reset_converter (utf8_converter);

    bufsize = (mtext_len (text) + 1) * 6;
    buf = (gchar *) g_malloc (bufsize);

    mconv_rebind_buffer (utf8_converter, buf, bufsize);
    mconv_encode (utf8_converter, text);

    buf [utf8_converter->nbytes] = 0;

    return buf;
}

gunichar *
ibus_m17n_mtext_to_ucs4 (MText *text)
{
    gint bufsize;
    gunichar *buf;

    if (text == NULL)
        return NULL;

    mconv_reset_converter (utf32_converter);

    bufsize = (mtext_len (text) + 2) * sizeof (gunichar);
    buf = (gunichar *) g_malloc (bufsize);

    mconv_rebind_buffer (utf32_converter, (gchar *)buf, bufsize);
    mconv_encode (utf32_converter, text);

    buf [utf32_converter->nchars] = 0;

    return buf;
}

static IBusEngineDesc *
ibus_m17n_engine_new (MSymbol  lang,
                      MSymbol  name,
                      MText   *title,
                      MText   *icon,
                      MText   *desc)
{
    IBusEngineDesc *engine;
    gchar *engine_name;
    gchar *engine_longname;
    gchar *engine_title;
    gchar *engine_icon;
    gchar *engine_desc;
    gint i;

    engine_name = g_strdup_printf ("m17n:%s:%s", msymbol_name (lang), msymbol_name (name));

    engine_longname = g_strdup_printf ("%s (m17n)", msymbol_name (name));
    engine_title = ibus_m17n_mtext_to_utf8 (title);
    engine_icon = ibus_m17n_mtext_to_utf8 (icon);
    engine_desc = ibus_m17n_mtext_to_utf8 (desc);

    engine = ibus_engine_desc_new (engine_name,
                                   engine_longname,
                                   engine_desc ? engine_desc : "",
                                   msymbol_name (lang),
                                   "GPL",
                                   "",
                                   engine_icon ? engine_icon : "",
                                   "us");
    /* set default rank to 0 */
    engine->rank = 0;

    for (i = 0; i < G_N_ELEMENTS(keymap); i++) {
        if (strcmp (engine_name, keymap[i]) == 0) {
            /* set rank of default keymap to 1 */
            engine->rank = 1;
            break;
        }
    }

    g_free (engine_name);
    g_free (engine_longname);
    g_free (engine_title);
    g_free (engine_icon);
    g_free (engine_desc);

    return engine;
}

GList *
ibus_m17n_list_engines (void)
{
    GList *engines = NULL;
    MPlist *imlist;
    MPlist *elm;

    imlist = mdatabase_list(msymbol("input-method"), Mnil, Mnil, Mnil);

    for (elm = imlist; elm && mplist_key(elm) != Mnil; elm = mplist_next(elm)) {
        MDatabase *mdb = (MDatabase *) mplist_value(elm);
        MSymbol *tag = mdatabase_tag(mdb);

        if (tag[1] != Mnil && tag[2] != Mnil) {
            MSymbol lang;
            MSymbol name;
            MText *title = NULL;
            MText *icon = NULL;
            MText *desc = NULL;
            MPlist *l;

            lang = tag[1];
            name = tag[2];

            l = minput_get_variable (lang, name, msymbol ("candidates-charset"));
            if (l) {
                /* check candidates encoding */
                MPlist *sl;
                MSymbol varname;
                MText *vardesc;
                MSymbol varunknown;
                MSymbol varcharset;

                sl = mplist_value (l);
                varname  = mplist_value (sl);
                sl = mplist_next (sl);
                vardesc = mplist_value (sl);
                sl = mplist_next (sl);
                varunknown = mplist_value (sl);
                sl = mplist_next (sl);
                varcharset = mplist_value (sl);

                if (varcharset != Mcoding_utf_8 ||
                    varcharset != Mcoding_utf_8_full) {
                    /*
                    g_debug ("%s != %s or %s",
                                msymbol_name (varcharset),
                                msymbol_name (Mcoding_utf_8),
                                msymbol_name (Mcoding_utf_8_full));
                    */
                    continue;
                }

            }
            if (l)
                m17n_object_unref (l);

            desc = minput_get_description (lang, name);
            l = minput_get_title_icon (lang, name);
            if (l && mplist_key (l) == Mtext) {
                title = mplist_value (l);
            }

            MPlist *n = mplist_next (l);
            if (n && mplist_key (n) == Mtext) {
                icon = mplist_value (n);
            }

            engines = g_list_append (engines, ibus_m17n_engine_new (lang, name, title, icon, desc));

            if (desc)
                m17n_object_unref (desc);
            m17n_object_unref (l);
        }
    }

    if (imlist) {
        m17n_object_unref (imlist);
    }

    return engines;
}

IBusComponent *
ibus_m17n_get_component (void)
{
    GList *engines, *p;
    IBusComponent *component;

    component = ibus_component_new ("org.freedesktop.IBus.M17n",
                                    N_("M17N"),
                                    "0.1.0",
                                    "GPL",
                                    "Peng Huang <shawn.p.huang@gmail.com>",
                                    "http://code.google.com/p/ibus/",
                                    "",
                                    "ibus-m17n");

    engines = ibus_m17n_list_engines ();

    for (p = engines; p != NULL; p = p->next) {
        ibus_component_add_engine (component, (IBusEngineDesc *) p->data);
    }

    g_list_free (engines);
    return component;
}

#ifdef DEBUG
#include <locale.h>

int main ()
{
    IBusComponent *component;
    GString *output;

    setlocale (LC_ALL, "");
    ibus_init ();
    ibus_m17n_init();

    component = ibus_m17n_get_component ();

    output = g_string_new ("");

    ibus_component_output (component, output, 1);

    g_debug ("\n%s", output->str);

    g_string_free (output, TRUE);
    g_object_unref (component);

    return 0;
}
#endif

