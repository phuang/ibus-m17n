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
%}

%init %{
    M17N_INIT ();
%}
%{
typedef MPlist IMList;

IMList *
list_input_methods () {
    MPlist *imlist;
    imlist = mdatabase_list(msymbol("input-method"), Mnil, Mnil, Mnil);
    return (IMList *) imlist;
}

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
%mutable;
