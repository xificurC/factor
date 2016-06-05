! Copyright (C) 2010 Anton Gorenko.
! See http://factorcode.org/license.txt for BSD license.
USING: alien alien.libraries alien.syntax combinators
gobject-introspection kernel system vocabs ;
in: clutter.gtk.ffi

<<
"clutter.ffi" require
"gtk.ffi" require
>>

library: clutter.gtk

<<
"clutter.gtk" {
    { [ os windows? ] [ drop ] }
    { [ os macosx? ] [ drop ] }
    { [ os unix? ] [ "libclutter-gtk-1.0.so" cdecl add-library ] }
} cond
>>

gir: GtkClutter-1.0.gir
