CFLAGS=$(echo "${CFLAGS}" | sed "s/-march=[a-zA-Z0-9]*//g")
CFLAGS=$(echo "${CFLAGS}" | sed "s/-mtune=[a-zA-Z0-9]*//g")

# Avoid sorting LDFLAGS
sed -i.bak 's/LDFLAGS := $(sort $(LDFLAGS))//g' common.mk


# Multithreading
MODEL="pthreads"


# Map platform to BLIS target architecture 
case $target_platform in
    osx-64)
        arch="intel64"
        ;;
    *-64)
        arch="x86_64"
        ;;
    *-aarch64)
        arch="arm64"
        ;;
    *-arm64)
        arch="arm64"
        ;;
    #*-ppc64le)
    #    arch="power9"
    #   ;;
    *)
        echo "Unsupported architecture: $target_platform"
        exit 1
esac


# Define target-specific options
case $target_platform in
    osx-*)
        export CC_VENDOR=clang
        EXTRA=""
        ;;
    linux-*)
        ln -s `which $CC` $BUILD_PREFIX/bin/gcc
        export CC_VENDOR=gcc
        EXTRA=""
        ;;
    win-*)
        export LIBPTHREAD=""
        EXTRA="--enable-arg-max-hack --disable-shared --enable-static"
        ;;
esac


# General case
./configure --prefix=$PREFIX --enable-cblas --enable-threading="$MODEL" $EXTRA $arch
make -j${CPU_COUNT}
make install
make check -j${CPU_COUNT}


# Windows-specific shenanigans (builds twice; first static above, then shared below)
case $target_platform in win-*)
    ./configure --enable-shared --disable-static --prefix=$PREFIX --enable-cblas --enable-threading="$MODEL" --enable-arg-max-hack $arch
    make -j${CPU_COUNT}
    make install 
    find $PREFIX/lib -iname "libblis.*.dll" -exec mv {} $PREFIX/bin/ \;
    mv $PREFIX/lib/libblis.lib $PREFIX/lib/blis.lib
    mv $PREFIX/lib/libblis.a $PREFIX/lib/libblis.lib
esac
