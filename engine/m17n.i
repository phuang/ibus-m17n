/* vim:set et ts=4: */
/*
 * ibus-m17n - The m17n engine for IBus
 *
 * Copyright (c) 2007-2008 Huang Peng <shawn.p.huang@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

%module m17n

%{
#include <m17n.h>
%}

%init {
    M17N_INIT ();
}

/* inline c functions */
%{
/*
 * List all input methods
 */
PyObject *
minput_list_ims () {
    PyObject *result = NULL;
    MPlist *imlist;
    MPlist *elm;

    imlist = mdatabase_list(msymbol("input-method"), Mnil, Mnil, Mnil);

    result = PyList_New (0);

    for (elm = imlist; elm && mplist_key(elm) != Mnil; elm = mplist_next(elm)) {
        MDatabase *mdb = (MDatabase *) mplist_value(elm);
        MSymbol *tag = mdatabase_tag(mdb);
        if (tag[1] != Mnil && tag[2] != Mnil) {
            const char *im_lang = msymbol_name (tag[1]);
            const char *im_name = msymbol_name (tag[2]);

            if (im_lang && strlen (im_lang) && im_name && strlen (im_name)) {
                PyObject *lang = PyString_FromString (im_lang);
                PyObject *name = PyString_FromString (im_name);
                PyObject *im_info = PyTuple_New (2);
                PyTuple_SetItem (im_info, 0, name);
                PyTuple_SetItem (im_info, 1, lang);
                PyList_Append (result, im_info);
                Py_DECREF (im_info);
            }
        }
    }

    if (imlist) m17n_object_unref (imlist);
    return result;
}

/*
 * Get title of an input method
 */
MText *
minput_get_title (MSymbol lang, MSymbol name)
{
    MPlist *l = minput_get_title_icon (lang, name);
    if (l) {
        if (l && mplist_key (l) == Mtext) {
            return (MText*) mplist_value (l);
        }
    }
    return NULL;
}

/*
 * Get icon of an input method
 */
MText *
minput_get_icon (MSymbol lang, MSymbol name)
{
    MPlist *l = minput_get_title_icon (lang, name);
    if (l) {
        l = mplist_next (l);
        if (l && mplist_key (l) == Mtext) {
            return (MText*) mplist_value (l);
        }
    }
    return NULL;
}

/*
 * Convert MText * to PyUnicode *
 */
PyObject *
_conv_mtext_to_unicode (MText *text)
{
    PyObject *result = NULL;
    if (text) {
        static MConverter *converter = NULL;
        int bufsize;
        Py_UNICODE *buf;
        if (converter == NULL) {
#if Py_UNICODE_SIZE == 2
            converter = mconv_buffer_converter (Mcoding_utf_16, NULL, 0);
#else
            converter = mconv_buffer_converter (Mcoding_utf_32, NULL, 0);
#endif
        }
        else {
            mconv_reset_converter (converter);
        }

        bufsize = mtext_len (text) * 6 + 6;
        buf = (Py_UNICODE *)PyMem_Malloc (bufsize);

        mconv_rebind_buffer (converter, (char *)buf, bufsize);
        mconv_encode (converter, text);

        buf [converter->nchars + 1] = 0;
        result = PyUnicode_FromUnicode (buf + 1, converter->nchars);

        PyMem_Free (buf);
    }
    else {
        Py_INCREF (Py_None);
        result = Py_None;
    }
    return result;
}

/*
 * Create an input context
 */
MInputContext *
_create_ic (MInputMethod *im)
{
    MInputContext *ic = minput_create_ic (im, NULL);
    mplist_add (ic->plist, msymbol ("PythonDict"), PyDict_New ());
    return ic;
}


/*
 * Destroy an input context
 */
void
_destroy_ic (MInputContext *ic)
{
    MPlist *p = NULL;
    PyObject *dict = NULL;
    p = mplist_find_by_key (ic->plist,  msymbol ("PythonDict"));
    if (p) {
        dict = (PyObject *)mplist_value (p);
    }

    minput_destroy_ic (ic);
    Py_XDECREF (dict);
}

/*
 * input method callback function
 */
static void
_im_callback (MInputContext *ic, MSymbol command)
{
    MPlist *p = NULL;
    PyObject *_dict = NULL;
    PyObject *_callback = NULL;
    PyObject *_command = NULL;

    p = mplist_find_by_key (ic->plist,  msymbol ("PythonDict"));
    if (p) {
        _dict = (PyObject *)mplist_value (p);
    }

    if (_dict == NULL)
        return;

    _command = PyString_FromString (msymbol_name (command));

    _callback = PyDict_GetItem (_dict, _command);

    if (_callback && PyCallable_Check (_callback)) {
        PyObject *result = PyObject_CallFunction (_callback, "O", _command);
        if (result == NULL) {
            PyErr_Print ();
        }
    }
    Py_XDECREF (_command);
}

%}

/* define exception */
%exception {
    $action
    if (PyErr_Occurred ()) {
        return NULL;
    }
}


/* define typemap MSymbol */
%typemap (in) MSymbol {
    if (PyString_Check ($input)) {
        $1 = msymbol (PyString_AsString ($input));
    }
    else if (PyUnicode_Check ($input)) {
        PyObject *utf8_str = PyUnicode_AsUTF8String ($input);
        $1 = msymbol (PyString_AsString (utf8_str));
        Py_XDECREF (utf8_str);
    }
    else {
        void *p;
        if (SWIG_ConvertPtr ($input, &p,
                SWIGTYPE_p_MSymbolStruct, 0) == SWIG_OK)
            $1 = (MSymbol)p;
        else {
            PyErr_SetString (PyExc_TypeError,
                "arg must be string or MSymbol");
            return NULL;
        }
    }
}

%typemap (out) MSymbol {
    if ($1 == Mnil) {
        PY_INCREF (Py_None);
        $result = Py_None;
    }
    else {
        $result = PyString_FromString (msymbol_name ($1));
    }
}


/* define typemap PyObject * */
%typemap (out) PyObject * {
    $result = $1;
}

/* define typemap PyObject * */
%typemap (in) PyObject * {
    $1 = $input;
}

/* define typemap MText * */
%{
static PyObject *
PyUnicode_FromMText (MText *text) {
    return _conv_mtext_to_unicode (text);
}
%}

%typemap (out) MText * {
    $result = PyUnicode_FromMText ($1);
    if ($1) m17n_object_unref ($1);
}

%typemap (argout) MText * OUTPUT {
    PyObject *o = PyUnicode_FromMText ($1);
    $result = SWIG_AppendOutput ($result, o);
    if ($1) m17n_object_unref ($1);
}

%typemap (in, numinputs = 0) MText * OUTPUT {
    $1 = mtext ();
}


/* define MInputMethod structure */
struct MInputMethod {};
%extend MInputMethod {
    MInputMethod (MSymbol lang, MSymbol name) {
        MInputMethod *im = minput_open_im (lang, name, NULL);
        if (im == NULL) {
            PyErr_Format (PyExc_RuntimeError,
                "m17n does not have engine %s-%s",
                msymbol_name (lang), msymbol_name (name));
        }
        return im;
    }

    MInputContext *create_ic () {
        return _create_ic (self);
    }

    ~MInputMethod () {
        minput_close_im (self);
    }

}

/* define MInputContext struct */
struct MInputContext {};
%extend MInputContext {
    MInputContext (MInputMethod *im) {
        return _create_ic (im);
    }

    ~MInputContext () {
        _destroy_ic (self);
    }

    int
    filter (MSymbol key) {
        if (key == NULL) {
            PyErr_SetString (PyExc_TypeError,
                "Argumet 2 of filter must be a MSymbol.");
            return;
        }

        return minput_filter (self, key, NULL);
    }

    int
    lookup (MSymbol key, MText *OUTPUT) {

        if (key == NULL) {
            PyErr_SetString (PyExc_TypeError,
                "Argumet 2 of lookup must be a MSymbol.");
            return;
        }

        return minput_lookup (self, key, NULL, OUTPUT);
    }

    void
    reset () {
        minput_reset_ic (self);
    }

    void set_callback (MSymbol command, PyObject *func) {

        MPlist *p;
        PyObject *callbacks_dict = NULL;
        char *c_str = NULL;

        if (command == NULL) {
            PyErr_SetString (PyExc_TypeError,
                "Argumet 2 of set_callback must be a MSymbol.");
            return;
        }

        if (func != Py_None && !PyCallable_Check (func)) {
            PyErr_SetString (PyExc_TypeError,
                "Argumet 3 of set_callback must be a callable object.");
            return;
        }

        p = mplist_find_by_key (self->plist,  msymbol ("PythonDict"));
        if (p) {
            callbacks_dict = (PyObject *)mplist_value (p);
        }

        c_str = msymbol_name (command);

        if (func != Py_None) {
            PyDict_SetItem (callbacks_dict, PyString_FromString (c_str), func);
        }
        else {
            PyDict_DelItem (callbacks_dict, PyString_FromString (c_str));
        }

        mplist_put (self->im->driver.callback_list, command, (void *)_im_callback);
    }

    /* define properties */
    %immutable;

    MText *status;

    MText *preedit;
    int cursor_pos;

    PyObject *candidates;

    int candidate_index;
    int candidate_from;
    int candidate_to;
    int candidates_show;

    %mutable;

    %{
        MText *
        MInputContext_status_get (MInputContext *self) {
            m17n_object_ref (self->status);
            return self->status;
        }

        MText *
        MInputContext_preedit_get (MInputContext *self) {
            m17n_object_ref (self->preedit);
            return self->preedit;
        }

        int
        MInputContext_cursor_pos_get (MInputContext *self) {
            return self->cursor_pos;
        }

        int
        MInputContext_candidate_index_get (MInputContext *self) {
            return self->candidate_index;
        }

        int
        MInputContext_candidate_from_get (MInputContext *self) {
            return self->candidate_from;
        }

        int
        MInputContext_candidate_to_get (MInputContext *self) {
            return self->candidate_to;
        }

        int
        MInputContext_candidates_show_get (MInputContext *self) {
            return self->candidate_show != 0;
        }

        PyObject *
        MInputContext_candidates_get (MInputContext *self) {

            PyObject *list;
            MPlist *group;
            MConverter *converter;
            int bufsize;
            Py_UNICODE *buf;

            list = PyList_New (0);

            if (self->candidate_list == NULL)
                return list;

            bufsize = 64;
            buf = (Py_UNICODE *)PyMem_Malloc (bufsize);

        #if Py_UNICODE_SIZE == 2
            converter = mconv_buffer_converter (Mcoding_utf_16, NULL, 0);
        #else
            converter = mconv_buffer_converter (Mcoding_utf_32, NULL, 0);
        #endif

            for (group = self->candidate_list;
                mplist_key (group) != Mnil;
                group = mplist_next (group)) {
                if (mplist_key (group) == Mtext) {
                    MText *text = (MText *) mplist_value (group);
                    PyList_Append (list, _conv_mtext_to_unicode (text));
                }
                else {
                    PyObject *l = PyList_New (0);
                    MPlist *p = (MPlist *)mplist_value (group);

                    for (; mplist_key (p) != Mnil; p = mplist_next (p)) {
                        MText *text = (MText *) mplist_value (p);

                        PyList_Append (l, _conv_mtext_to_unicode (text));
                    }
                    PyList_Append (list, l);
                }
            }

            mconv_free_converter (converter);
            PyMem_Free (buf);

            return list;

        }

    %}
}

/* define minput functions */
PyObject *minput_list_ims ();
MText *minput_get_description (MSymbol lang, MSymbol name);
MText *minput_get_title (MSymbol lang, MSymbol name);
MText *minput_get_icon (MSymbol lang, MSymbol name);

/* define MSymbol structure */
%rename (MSymbol) MSymbolStruct;
struct MSymbolStruct {};
typedef struct MSymbolStruct *MSymbol;
%extend MSymbolStruct {
    MSymbolStruct (const char *name) {
        if (name == NULL)
            return Mnil;
        return msymbol (name);
    }

    char *name () {
        return msymbol_name (self);
    }

    char *__str__ () {
        return msymbol_name (self);
    }

    int is_managing_key () {
        return msymbol_is_managing_key (self);
    }

    ~SymbolStruct () {
    }
};


/* define some constant values */
%immutable;
extern MSymbol Mnil;
extern MSymbol Mt;
extern MSymbol Mstring;
extern MSymbol Msymbol;
extern MSymbol Mtext;
extern MSymbol Mcharset;
extern MSymbol Minput_preedit_start;
extern MSymbol Minput_preedit_done;
extern MSymbol Minput_preedit_draw;
extern MSymbol Minput_status_start;
extern MSymbol Minput_status_done;
extern MSymbol Minput_status_draw;
extern MSymbol Minput_candidates_start;
extern MSymbol Minput_candidates_done;
extern MSymbol Minput_candidates_draw;
extern MSymbol Minput_set_spot;
extern MSymbol Minput_toggle;
extern MSymbol Minput_reset;
extern MSymbol Minput_get_surrounding_text;
extern MSymbol Minput_delete_surrounding_text;
%mutable;

