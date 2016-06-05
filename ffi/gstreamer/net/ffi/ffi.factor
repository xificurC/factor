! Copyright (C) 2010 Anton Gorenko.
! See http://factorcode.org/license.txt for BSD license.
USING: alien alien.libraries alien.syntax combinators
gobject-introspection kernel system vocabs ;
in: gstreamer.net.ffi

<<
"gstreamer.ffi" require
>>

library: gstreamer.net

<<
"gstreamer.net" {
    { [ os windows? ] [ drop ] }
    { [ os macosx? ] [ drop ] }
    { [ os unix? ] [ "libgstnet-0.10.so" cdecl add-library ] }
} cond
>>

gir: GstNet-0.10.gir
