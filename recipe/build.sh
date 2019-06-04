CFLAGS=$(echo "${CFLAGS}" | sed "s/-march=[a-zA-Z0-9]*//g")
CFLAGS=$(echo "${CFLAGS}" | sed "s/-mtune=[a-zA-Z0-9]*//g")

case `uname` in
    Darwin)
        export CC=$BUILD_PREFIX/bin/clang
        ./configure --prefix=$PREFIX --enable-cblas --enable-threading=pthreads intel64
        make CC_VENDOR=clang -j${CPU_COUNT}
        make install
        make check -j${CPU_COUNT}
        ;;
    Linux)
        ln -s `which $CC` $BUILD_PREFIX/bin/gcc
        export CC=$BUILD_PREFIX/bin/gcc
        ./configure --prefix=$PREFIX --enable-cblas --enable-threading=pthreads x86_64
        make CC_VENDOR=gcc -j${CPU_COUNT}
        make install
        make check -j${CPU_COUNT}
        ;;
    MINGW*)
        export PATH="$PREFIX/Library/bin:$BUILD_PREFIX/Library/bin:$PATH"
        export CC=clang
        export RANLIB=echo
        export LIBPTHREAD=
        export AS=llvm-as
        export AR=llvm-ar
        export CFLAGS="-MD -I$PREFIX/Library/include"
        export LDFLAGS="$LDFLAGS -L$PREFIX/Library/lib"
        clang --version
        llvm-as --version
        llvm-ar --version
        ./configure --enable-shared --enable-static --prefix=$PREFIX/Library --enable-cblas --enable-threading=pthreads --enable-arg-max-hack x86_64
        make -j${CPU_COUNT}
        make install
        mv $PREFIX/Library/lib/libblis.lib $PREFIX/Library/lib/blis.lib
        mv $PREFIX/Library/lib/libblis.a $PREFIX/Library/lib/libblis.lib
        mv $PREFIX/Library/lib/libblis.*.dll $PREFIX/Library/bin/
        make check -j${CPU_COUNT}
        ;;
esac
