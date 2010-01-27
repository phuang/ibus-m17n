/* vim:set et sts=4: */

#include <ibus.h>
#include <m17n.h>
#include <string.h>
#include "m17nutil.h"
#include "engine.h"

typedef struct _IBusM17NEngine IBusM17NEngine;
typedef struct _IBusM17NEngineClass IBusM17NEngineClass;

struct _IBusM17NEngine {
    IBusEngine parent;

    /* members */
    MInputContext *context;
    IBusLookupTable *table;
    IBusProperty    *status_prop;
    IBusPropList    *prop_list;
};

struct _IBusM17NEngineClass {
    IBusEngineClass parent;
};

/* functions prototype */
static void ibus_m17n_engine_class_init     (IBusM17NEngineClass    *klass);
static void ibus_m17n_engine_init           (IBusM17NEngine         *m17n);
static GObject*
            ibus_m17n_engine_constructor    (GType                   type,
                                             guint                   n_construct_params,
                                             GObjectConstructParam  *construct_params);
static void ibus_m17n_engine_destroy        (IBusM17NEngine         *m17n);
static gboolean
            ibus_m17n_engine_process_key_event
                                            (IBusEngine             *engine,
                                             guint                   keyval,
                                             guint                   keycode,
                                             guint                   modifiers);
static void ibus_m17n_engine_focus_in       (IBusEngine             *engine);
static void ibus_m17n_engine_focus_out      (IBusEngine             *engine);
static void ibus_m17n_engine_reset          (IBusEngine             *engine);
static void ibus_m17n_engine_enable         (IBusEngine             *engine);
static void ibus_m17n_engine_disable        (IBusEngine             *engine);
static void ibus_engine_set_cursor_location (IBusEngine             *engine,
                                             gint                    x,
                                             gint                    y,
                                             gint                    w,
                                             gint                    h);
static void ibus_m17n_engine_set_capabilities
                                            (IBusEngine             *engine,
                                             guint                   caps);
static void ibus_m17n_engine_page_up        (IBusEngine             *engine);
static void ibus_m17n_engine_page_down      (IBusEngine             *engine);
static void ibus_m17n_engine_cursor_up      (IBusEngine             *engine);
static void ibus_m17n_engine_cursor_down    (IBusEngine             *engine);
static void ibus_m17n_engine_property_activate
                                            (IBusEngine             *engine,
                                             const gchar            *prop_name,
                                             guint                   prop_state);
static void ibus_m17n_engine_property_show
                                            (IBusEngine             *engine,
                                             const gchar            *prop_name);
static void ibus_m17n_engine_property_hide
                                            (IBusEngine             *engine,
                                             const gchar            *prop_name);

static void ibus_m17n_engine_commit_string
                                            (IBusM17NEngine         *m17n,
                                             const gchar            *string);
static void ibus_m17n_engine_callback       (MInputContext          *context,
                                             MSymbol                 command);

static IBusEngineClass *parent_class = NULL;
static GHashTable      *im_table = NULL;

GType
ibus_m17n_engine_get_type (void)
{
    static GType type = 0;

    static const GTypeInfo type_info = {
        sizeof (IBusM17NEngineClass),
        (GBaseInitFunc)        NULL,
        (GBaseFinalizeFunc) NULL,
        (GClassInitFunc)    ibus_m17n_engine_class_init,
        NULL,
        NULL,
        sizeof (IBusM17NEngine),
        0,
        (GInstanceInitFunc)    ibus_m17n_engine_init,
    };

    if (type == 0) {
        type = g_type_register_static (IBUS_TYPE_ENGINE,
                                       "IBusM17NEngine",
                                       &type_info,
                                       (GTypeFlags) 0);
    }

    return type;
}

static void
ibus_m17n_engine_class_init (IBusM17NEngineClass *klass)
{
    GObjectClass *object_class = G_OBJECT_CLASS (klass);
    IBusObjectClass *ibus_object_class = IBUS_OBJECT_CLASS (klass);
    IBusEngineClass *engine_class = IBUS_ENGINE_CLASS (klass);

    parent_class = (IBusEngineClass *) g_type_class_peek_parent (klass);

    object_class->constructor = ibus_m17n_engine_constructor;
    ibus_object_class->destroy = (IBusObjectDestroyFunc) ibus_m17n_engine_destroy;

    engine_class->process_key_event = ibus_m17n_engine_process_key_event;

    engine_class->reset = ibus_m17n_engine_reset;
    engine_class->enable = ibus_m17n_engine_enable;
    engine_class->disable = ibus_m17n_engine_disable;

    engine_class->focus_in = ibus_m17n_engine_focus_in;
    engine_class->focus_out = ibus_m17n_engine_focus_out;

    engine_class->page_up = ibus_m17n_engine_page_up;
    engine_class->page_down = ibus_m17n_engine_page_down;

    engine_class->cursor_up = ibus_m17n_engine_cursor_up;
    engine_class->cursor_down = ibus_m17n_engine_cursor_down;

    engine_class->property_activate = ibus_m17n_engine_property_activate;
}

static void
ibus_m17n_engine_init (IBusM17NEngine *m17n)
{
    m17n->status_prop = ibus_property_new ("status",
                                           PROP_TYPE_NORMAL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           TRUE,
                                           FALSE,
                                           0,
                                           NULL);
    g_object_ref_sink (m17n->status_prop);

    m17n->prop_list = ibus_prop_list_new ();
    g_object_ref_sink (m17n->prop_list);
    ibus_prop_list_append (m17n->prop_list,  m17n->status_prop);

    m17n->table = ibus_lookup_table_new (9, 0, TRUE, TRUE);
    g_object_ref_sink (m17n->table);
    m17n->context = NULL;
}

static GObject*
ibus_m17n_engine_constructor (GType                   type,
                              guint                   n_construct_params,
                              GObjectConstructParam  *construct_params)
{
    IBusM17NEngine *m17n;
    MInputMethod *im;
    const gchar *engine_name;

    m17n = (IBusM17NEngine *) G_OBJECT_CLASS (parent_class)->constructor (type,
                                                       n_construct_params,
                                                       construct_params);

    engine_name = ibus_engine_get_name ((IBusEngine *) m17n);
    g_assert (engine_name);

    if (im_table == NULL) {
        im_table = g_hash_table_new_full (g_str_hash,
                                          g_str_equal,
                                          g_free,
                                          (GDestroyNotify) minput_close_im);
    }

    im = (MInputMethod *) g_hash_table_lookup (im_table, engine_name);
    if (im == NULL) {
        gchar *lang;
        gchar *name;
        gchar **strv;

        strv = g_strsplit (engine_name, ":", 3);

        g_assert (g_strv_length (strv) == 3);
        g_assert (g_strcmp0 (strv[0], "m17n") == 0);

        lang = strv[1];
        name = strv[2];

        im = minput_open_im (msymbol (lang), msymbol (name), NULL);
        if (im != NULL) {
            mplist_put (im->driver.callback_list, Minput_preedit_start, ibus_m17n_engine_callback);
            mplist_put (im->driver.callback_list, Minput_preedit_draw, ibus_m17n_engine_callback);
            mplist_put (im->driver.callback_list, Minput_preedit_done, ibus_m17n_engine_callback);
            mplist_put (im->driver.callback_list, Minput_status_start, ibus_m17n_engine_callback);
            mplist_put (im->driver.callback_list, Minput_status_draw, ibus_m17n_engine_callback);
            mplist_put (im->driver.callback_list, Minput_status_done, ibus_m17n_engine_callback);
            mplist_put (im->driver.callback_list, Minput_candidates_start, ibus_m17n_engine_callback);
            mplist_put (im->driver.callback_list, Minput_candidates_draw, ibus_m17n_engine_callback);
            mplist_put (im->driver.callback_list, Minput_candidates_done, ibus_m17n_engine_callback);
            mplist_put (im->driver.callback_list, Minput_set_spot, ibus_m17n_engine_callback);
            mplist_put (im->driver.callback_list, Minput_toggle, ibus_m17n_engine_callback);
            mplist_put (im->driver.callback_list, Minput_reset, ibus_m17n_engine_callback);
            mplist_put (im->driver.callback_list, Minput_get_surrounding_text, ibus_m17n_engine_callback);
            mplist_put (im->driver.callback_list, Minput_delete_surrounding_text, ibus_m17n_engine_callback);

            g_hash_table_insert (im_table, g_strdup (engine_name), im);
        }

        g_strfreev (strv);
    }

    if (im == NULL) {
        g_warning ("Can not find m17n keymap %s", engine_name);
        g_object_unref (m17n);
        return NULL;
    }

    m17n->context = minput_create_ic (im, NULL);
    mplist_add (m17n->context->plist, msymbol ("IBusEngine"), m17n);

    return (GObject *) m17n;
}


static void
ibus_m17n_engine_destroy (IBusM17NEngine *m17n)
{
    if (m17n->prop_list) {
        g_object_unref (m17n->prop_list);
        m17n->prop_list = NULL;
    }

    if (m17n->status_prop) {
        g_object_unref (m17n->status_prop);
        m17n->status_prop = NULL;
    }

    if (m17n->table) {
        g_object_unref (m17n->table);
        m17n->table = NULL;
    }

    if (m17n->context) {
        minput_destroy_ic (m17n->context);
        m17n->context = NULL;
    }

    IBUS_OBJECT_CLASS (parent_class)->destroy ((IBusObject *)m17n);
}

static void
ibus_m17n_engine_commit_string (IBusM17NEngine *m17n,
                                const gchar    *string)
{
    IBusText *text;
    text = ibus_text_new_from_static_string (string);
    ibus_engine_commit_text ((IBusEngine *)m17n, text);
}

MSymbol
ibus_m17n_key_event_to_symbol (guint keyval,
                               guint modifiers)
{
    GString *keysym;
    MSymbol mkeysym = Mnil;
    guint mask = 0;

    if (keyval >= IBUS_Shift_L && keyval <= IBUS_Hyper_R) {
        return Mnil;
    }

    keysym = g_string_new ("");

    if (keyval >= IBUS_space && keyval <= IBUS_asciitilde) {
        gint c = keyval;
        if (keyval == IBUS_space && modifiers & IBUS_SHIFT_MASK)
            mask |= IBUS_SHIFT_MASK;

        if (modifiers & IBUS_CONTROL_MASK) {
            if (c >= IBUS_a && c <= IBUS_z)
                c += IBUS_A - IBUS_a;
            mask |= IBUS_CONTROL_MASK;
        }

        g_string_append_c (keysym, c);
    }
    else {
        mask |= modifiers & (IBUS_CONTROL_MASK | IBUS_SHIFT_MASK);
        g_string_append (keysym, ibus_keyval_name (keyval));
        if (keysym->len == 0) {
            g_string_free (keysym, TRUE);
            return Mnil;
        }
    }

    mask |= modifiers & (IBUS_MOD1_MASK |
                         IBUS_META_MASK |
                         IBUS_SUPER_MASK |
                         IBUS_HYPER_MASK);


    if (mask & IBUS_HYPER_MASK) {
        g_string_prepend (keysym, "H-");
    }
    if (mask & IBUS_SUPER_MASK) {
        g_string_prepend (keysym, "s-");
    }
    if (mask & IBUS_MOD1_MASK) {
        g_string_prepend (keysym, "A-");
    }
    if (mask & IBUS_META_MASK) {
        g_string_prepend (keysym, "M-");
    }
    if (mask & IBUS_CONTROL_MASK) {
        g_string_prepend (keysym, "C-");
    }
    if (mask & IBUS_SHIFT_MASK) {
        g_string_prepend (keysym, "S-");
    }

    mkeysym = msymbol (keysym->str);
    g_string_free (keysym, TRUE);

    return mkeysym;
}

static gboolean
ibus_m17n_engine_process_key (IBusM17NEngine *m17n,
                              MSymbol         key)
{
    gchar *buf;
    MText *produced;
    gint retval;

    retval = minput_filter (m17n->context, key, NULL);

    if (retval) {
        return TRUE;
    }

    produced = mtext ();

    retval = minput_lookup (m17n->context, key, NULL, produced);

    if (retval) {
        // g_debug ("minput_lookup returns %d", retval);
    }

    buf = ibus_m17n_mtext_to_utf8 (produced);
    m17n_object_unref (produced);

    if (buf && strlen (buf)) {
        ibus_m17n_engine_commit_string (m17n, buf);
    }
    g_free (buf);

    return retval == 0;
}

static gboolean
ibus_m17n_engine_process_key_event (IBusEngine     *engine,
                                    guint           keyval,
                                    guint           keycode,
                                    guint           modifiers)
{
    IBusM17NEngine *m17n = (IBusM17NEngine *) engine;

    if (modifiers & IBUS_RELEASE_MASK)
        return FALSE;
    MSymbol m17n_key = ibus_m17n_key_event_to_symbol (keyval, modifiers);

    if (m17n_key == Mnil)
        return FALSE;

    return ibus_m17n_engine_process_key (m17n, m17n_key);
}

static void
ibus_m17n_engine_focus_in (IBusEngine *engine)
{
    IBusM17NEngine *m17n = (IBusM17NEngine *) engine;

    ibus_engine_register_properties (engine, m17n->prop_list);
    ibus_m17n_engine_process_key (m17n, msymbol ("input-focus-in"));

    parent_class->focus_in (engine);
}

static void
ibus_m17n_engine_focus_out (IBusEngine *engine)
{
    IBusM17NEngine *m17n = (IBusM17NEngine *) engine;

    ibus_m17n_engine_process_key (m17n, msymbol ("input-focus-out"));

    parent_class->focus_out (engine);
}

static void
ibus_m17n_engine_reset (IBusEngine *engine)
{
    IBusM17NEngine *m17n = (IBusM17NEngine *) engine;

    parent_class->reset (engine);
    ibus_m17n_engine_focus_in (engine);
}

static void
ibus_m17n_engine_enable (IBusEngine *engine)
{
    IBusM17NEngine *m17n = (IBusM17NEngine *) engine;

    parent_class->enable (engine);
}

static void
ibus_m17n_engine_disable (IBusEngine *engine)
{
    IBusM17NEngine *m17n = (IBusM17NEngine *) engine;

    ibus_m17n_engine_focus_out (engine);
    parent_class->disable (engine);
}

static void
ibus_m17n_engine_page_up (IBusEngine *engine)
{
    IBusM17NEngine *m17n = (IBusM17NEngine *) engine;

    ibus_m17n_engine_process_key (m17n, msymbol ("Up"));
    parent_class->page_up (engine);
}

static void
ibus_m17n_engine_page_down (IBusEngine *engine)
{

    IBusM17NEngine *m17n = (IBusM17NEngine *) engine;

    ibus_m17n_engine_process_key (m17n, msymbol ("Down"));
    parent_class->page_down (engine);
}

static void
ibus_m17n_engine_cursor_up (IBusEngine *engine)
{

    IBusM17NEngine *m17n = (IBusM17NEngine *) engine;

    ibus_m17n_engine_process_key (m17n, msymbol ("Left"));
    parent_class->cursor_up (engine);
}

static void
ibus_m17n_engine_cursor_down (IBusEngine *engine)
{

    IBusM17NEngine *m17n = (IBusM17NEngine *) engine;

    ibus_m17n_engine_process_key (m17n, msymbol ("Right"));
    parent_class->cursor_down (engine);
}

static void
ibus_m17n_engine_property_activate (IBusEngine  *engine,
                                    const gchar *prop_name,
                                    guint        prop_state)
{
    parent_class->property_activate (engine, prop_name, prop_state);
}

static void
ibus_m17n_engine_update_lookup_table (IBusM17NEngine *m17n)
{
   ibus_lookup_table_clear (m17n->table);

    if (m17n->context->candidate_list && m17n->context->candidate_show) {
        IBusText *text;
        MPlist *group;
        group = m17n->context->candidate_list;
        gint i = 0;
        gint page = 1;

        while (1) {
            gint len;
            if (mplist_key (group) == Mtext)
                len = mtext_len ((MText *) mplist_value (group));
            else
                len = mplist_length ((MPlist *) mplist_value (group));

            if (i + len > m17n->context->candidate_index)
                break;

            i += len;
            group = mplist_next (group);
            page ++;
        }

        if (mplist_key (group) == Mtext) {
            MText *mt;
            gunichar *buf, *p;

            mt = (MText *) mplist_value (group);
            ibus_lookup_table_set_page_size (m17n->table, mtext_len (mt));

            buf = ibus_m17n_mtext_to_ucs4 (mt);
            for (p = buf + 1; *p != 0; p++) {
                ibus_lookup_table_append_candidate (m17n->table, ibus_text_new_from_unichar (*p));
            }
            g_free (buf);
        }
        else {
            MPlist *p;

            p = (MPlist *) mplist_value (group);
            ibus_lookup_table_set_page_size (m17n->table, mplist_length (p));

            for (; mplist_key (p) != Mnil; p = mplist_next (p)) {
                MText *mtext;
                gchar *buf;

                mtext = (MText *) mplist_value (p);
                buf = ibus_m17n_mtext_to_utf8 (mtext);
                if (buf) {
                    ibus_lookup_table_append_candidate (m17n->table, ibus_text_new_from_string (buf));
                    g_free (buf);
                }
            }
        }

        ibus_lookup_table_set_cursor_pos (m17n->table, m17n->context->candidate_index - i);
        text = ibus_text_new_from_printf ("( %d / %d )", page, mplist_length (m17n->context->candidate_list));

        ibus_engine_update_lookup_table ((IBusEngine *)m17n, m17n->table, TRUE);
        ibus_engine_update_auxiliary_text ((IBusEngine *)m17n, text, TRUE);
    }
    else {
        ibus_engine_hide_lookup_table ((IBusEngine *)m17n);
        ibus_engine_hide_auxiliary_text ((IBusEngine *)m17n);
    }
}

static void
ibus_m17n_engine_callback (MInputContext *context,
                           MSymbol        command)
{
    IBusM17NEngine *m17n = NULL;
    MPlist *p = NULL;

    p = mplist_find_by_key (context->plist,  msymbol ("IBusEngine"));
    if (p) {
        m17n = (IBusM17NEngine *) mplist_value (p);
    }

    if (m17n == NULL) {
        return;
    }

    if (command == Minput_preedit_start) {
        ibus_engine_hide_preedit_text ((IBusEngine *)m17n);
    }
    else if (command == Minput_preedit_draw) {
        IBusText *text;
        gchar *buf;

        buf = ibus_m17n_mtext_to_utf8 (m17n->context->preedit);
        if (buf) {
            text = ibus_text_new_from_static_string (buf);
            ibus_text_append_attribute (text, IBUS_ATTR_TYPE_FOREGROUND, 0x00ffffff, 0, -1);
            ibus_text_append_attribute (text, IBUS_ATTR_TYPE_BACKGROUND, 0x00000000, 0, -1);
            ibus_engine_update_preedit_text ((IBusEngine *) m17n,
                                             text,
                                             m17n->context->cursor_pos,
                                             mtext_len (m17n->context->preedit) > 0);
        }
    }
    else if (command == Minput_preedit_done) {
        ibus_engine_hide_preedit_text ((IBusEngine *)m17n);
    }
    else if (command == Minput_status_start) {
        ibus_engine_hide_preedit_text ((IBusEngine *)m17n);
    }
    else if (command == Minput_status_draw) {
        gchar *status;
        status = ibus_m17n_mtext_to_utf8 (m17n->context->status);

        if (status && strlen (status)) {
            IBusText *text;
            text = ibus_text_new_from_string (status);
            ibus_property_set_label (m17n->status_prop, text);
            ibus_property_set_visible (m17n->status_prop, TRUE);
        }
        else {
            ibus_property_set_label (m17n->status_prop, NULL);
            ibus_property_set_visible (m17n->status_prop, FALSE);
        }

        ibus_engine_update_property ((IBusEngine *)m17n, m17n->status_prop);
        g_free (status);
    }
    else if (command == Minput_status_done) {
    }
    else if (command == Minput_candidates_start) {
        ibus_engine_hide_lookup_table ((IBusEngine *) m17n);
        ibus_engine_hide_auxiliary_text ((IBusEngine *) m17n);
    }
    else if (command == Minput_candidates_draw) {
        ibus_m17n_engine_update_lookup_table (m17n);
    }
    else if (command == Minput_candidates_done) {
        ibus_engine_hide_lookup_table ((IBusEngine *) m17n);
        ibus_engine_hide_auxiliary_text ((IBusEngine *) m17n);
    }
    else if (command == Minput_set_spot) {
    }
    else if (command == Minput_toggle) {
    }
    else if (command == Minput_reset) {
    }
    else if (command == Minput_get_surrounding_text) {
    }
    else if (command == Minput_delete_surrounding_text) {
    }
}
