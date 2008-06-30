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
 /* Put header files here or function declarations like below */
#include <m17n.h>
static PyObject * _ic_dict = NULL;

%}

%init %{
    M17N_INIT ();
    _ic_dict = PyDict_New ();
%}

%{
typedef MPlist IMList;
typedef MPlist *CandidateList;
typedef PyObject *PyInputFunc;

/* 
 * List all input methods
 */
IMList *
list_input_methods () {
    MPlist *imlist;
    imlist = mdatabase_list(msymbol("input-method"), Mnil, Mnil, Mnil);
    return (IMList *) imlist;
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

MInputContext *
_create_ic (MInputMethod *im)
{
    MInputContext *ic = minput_create_ic (im, NULL);
    PyDict_SetItem (_ic_dict,  PyInt_FromLong ((unsigned long) ic), PyDict_New ());
    return ic;
}

void
_destroy_ic (MInputContext *ic)
{
    minput_destroy_ic (ic);
    PyDict_DelItem (_ic_dict, PyInt_FromLong ((unsigned long) ic));
}

void
_im_callback (MInputContext *ic, MSymbol command)
{
    PyObject *_dict = NULL;
    PyObject *_callback = NULL;
    PyObject *_command = NULL;

    _dict = PyDict_GetItem (_ic_dict, PyInt_FromLong ((unsigned long)ic));

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

/* define typemap MSymbol */
%typemap (in) MSymbol {
    if ($input == Py_None)
        $1 = Mnil;
    else
        $1 =  msymbol (PyString_AsString ($input));
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

/* define typemap MText * */
%typemap (argout) MText * OUTPUT {
    PyObject * text;
    if ($1) {
        MConverter *utf8_converter;
        int bufsize;
        char *buf;
        
        utf8_converter = mconv_buffer_converter (msymbol ("utf8"), NULL, 0);
        bufsize = mtext_len ($1) * 6;
        buf = (char *)PyMem_Malloc (bufsize);
        
        mconv_rebind_buffer (utf8_converter, buf, bufsize);
        mconv_encode (utf8_converter, $1);
        buf[utf8_converter->nbytes] = 0;
        m17n_object_unref ($1);
        
        text = PyString_FromString (buf);
        
        PyMem_Free (buf);
        mconv_free_converter (utf8_converter);
    }
    else {
        PY_INCREF (Py_None);
        text = Py_None;
    }

    $result = SWIG_AppendOutput ($result, text);
}

/* define typemap MText * */
%typemap (out) CandidateList {
    PyObject *list = PyList_New (0);
    
    MPlist *group = $1;
    MConverter *utf8_converter;
    int bufsize;
    char *buf;
    
    bufsize = 64;
    buf = PyMem_Malloc (bufsize);
    utf8_converter = mconv_buffer_converter (msymbol ("utf8"), NULL, 0);
     
    for (group = $1; mplist_key (group) != Mnil; group = mplist_next (group)) {
        if (mplist_key (group) == Mtext) {
            MText *text = (MText *) mplist_value (group);
            
            if (bufsize < mtext_len (text) * 6) {
                bufsize = mtext_len (text) * 6;
                buf = PyMem_Realloc (buf, bufsize);
            }
            
            mconv_rebind_buffer (utf8_converter, buf, bufsize);
            mconv_encode (utf8_converter, text);
            buf[utf8_converter->nbytes] = 0;
            PyList_Append (list, PyString_FromString (buf));
        }
        else {
            PyObject *l = PyList_New (0);
            MPlist *p = (MPlist *)mplist_value (group);
            for (; mplist_key (p) != Mnil; p = mplist_next (p)) {
                MText *text = (MText *) mplist_value (p);
                
                if (bufsize < mtext_len (text) * 6) {
                    bufsize = mtext_len (text) * 6;
                    buf = PyMem_Realloc (buf, bufsize);
                }
                
                mconv_rebind_buffer (utf8_converter, buf, bufsize);
                mconv_encode (utf8_converter, text);
                buf[utf8_converter->nbytes] = 0;
                PyList_Append (l, PyString_FromString (buf));
            }
            PyList_Append (list, l);
        }
    }

    mconv_free_converter (utf8_converter);
    PyMem_Free (buf);
    
    $result = list;

}
/* define typemap PyInputFunc */
%typemap (in) PyInputFunc {
    $1 = $input;
}

%typemap (in, numinputs = 0) MText * OUTPUT (MText * temp = mtext ());
%typemap (out) MText * {
    if ($1) {
        MConverter *utf8_converter;
        int bufsize;
        char *buf;
        
        utf8_converter = mconv_buffer_converter (msymbol ("utf8"), NULL, 0);
        bufsize = mtext_len ($1) * 6;
        buf = (char *)PyMem_Malloc (bufsize);
        
        mconv_rebind_buffer (utf8_converter, buf, bufsize);
        mconv_encode (utf8_converter, $1);
        buf[utf8_converter->nbytes] = 0;
        m17n_object_unref ($1);
        
        $result = PyString_FromString (buf);
        
        PyMem_Free (buf);
        mconv_free_converter (utf8_converter);
    }
    else {
        Py_INCREF (Py_None);
        $result = Py_None;
    }
}

/* define typemap IMList * */
%typemap(out) IMList * {
    $result = PyList_New (0);
    MPlist *elm;
    for (elm = $1; elm && mplist_key(elm) != Mnil; elm = mplist_next(elm)) {
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
                PyList_Append ($result, im_info);
                Py_DECREF (im_info);
            }
        }
    }
}

/* define MInputMethod structure */
struct MInputMethod {};
%extend MInputMethod {
    MInputMethod (MSymbol lang, MSymbol name) {
        return minput_open_im (lang, name, NULL);
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

    int filter (MSymbol key) {
        return minput_filter (self, key, NULL);
    }

    MText *lookup (MSymbol key) {
        MText *text = mtext ();
        if (minput_lookup (self, key, NULL, text) == 0)
            return text;
        m17n_object_unref (text);
        return NULL;
    }

    void reset () {
        minput_reset_ic (self);
    }

    void set_callback (MSymbol name, PyInputFunc func) {
        PyObject *callbacks = NULL;
        char *_name = NULL;

        if (PyCallable_Check (func) == 0)
            return;

        _name = msymbol_name (name);
        callbacks = PyDict_GetItem (_ic_dict, PyInt_FromLong ((unsigned long)self));

        PyDict_SetItem (callbacks, PyString_FromString (_name), func);

        mplist_put (self->im->driver.callback_list, name, (void *)_im_callback);

    }

    %immutable;

    MText *status;
    
    MText *preedit;
    int cursor_pos;

    CandidateList candidates;
    
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

        CandidateList
        MInputContext_candidates_get (MInputContext *self) {
            return self->candidate_list;
        }
 
    %}
}


IMList *list_input_methods ();
MText *minput_get_description (MSymbol lang, MSymbol name);
MText *minput_get_title (MSymbol lang, MSymbol name);
MText *minput_get_icon (MSymbol lang, MSymbol name);

%rename (MSymbol) MSymbolStruct;
struct MSymbolStruct {};
typedef struct MSymbolStruct *MSymbol;
%extend MSymbolStruct {
    MSymbolStruct (const char *name) {
        return msymbol (name);
    }
    
    char *name () {
        return msymbol_name (self);
    }

    int is_managing_key () {
        return msymbol_is_managing_key (self);
    }

    ~SymbolStruct () {
    }
};

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
