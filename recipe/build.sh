CFLAGS=$(echo "${CFLAGS}" | sed "s/-march=[a-zA-Z0-9]*//g")
CFLAGS=$(echo "${CFLAGS}" | sed "s/-mtune=[a-zA-Z0-9]*//g")

# Avoid sorting LDFLAGS
sed -i.bak 's/LDFLAGS := $(sort $(LDFLAGS))//g' common.mk


# Multithreading
MODEL="pthreads"


# Map platform to BLIS target architecture 
case $target_platform in
    *-64)
        arch="x86_64"
	;;
    *-aarch64)
        arch="arm64"
	;;
    *-arm64)
        arch="arm64"
	;;
    *-ppc64le)
        arch="power9"
	;;
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
        cfamily=""
	EXTRA="--enable-arg-max-hack"
	;;
esac


./configure --prefix=$PREFIX --disable-static --enable-cblas --enable-threading="$MODEL" $EXTRA $arch
make -j${CPU_COUNT}
make install

# On Windows, move DLLs to the binary folder
find $PREFIX/lib -iname "libblis.*.dll" -exec mv {} $PREFIX/bin/ \;

make check -j${CPU_COUNT}
