prefix=/usr/local/opt/libsass
exec_prefix=${prefix}
libdir=${exec_prefix}/lib
includedir=${prefix}/include
Name: LibSass
Description: Sass C API
Version: 1.0.0
Cflags: -I${includedir}
Libs: -L${libdir} -lsass
