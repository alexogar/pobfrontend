#!/bin/bash
pushd Lua-cURLv3

# We only replace `lua` with `luajit` once
sed -i '' 's/?= lua$/?= luajit/' Makefile
# We use pkg-config to find the right path for curl libraries
BREW_BIN="${BREW:-brew}"
if [[ -n "${ARCH_PREFIX}" ]]; then
  BREW_PREFIX_CMD="${ARCH_PREFIX} ${BREW_BIN}"
else
  BREW_PREFIX_CMD="${BREW_BIN}"
fi
sed -i '' "s@shell .* --libs libcurl@shell PKG_CONFIG_PATH=\$\$(${BREW_PREFIX_CMD} --prefix --installed curl)/lib/pkgconfig \$(PKG_CONFIG) --libs libcurl@" Makefile
# Prefer Homebrew's gcc-12 when available (installed by `make tools`).
sed -i '' 's@?= \$(MAC_ENV) gcc$@?= \$(MAC_ENV) gcc-12@' Makefile
# We target only MacOS 10.8 or later; otherwise, we get an error. We get an
# error for targeting <10.5 and a warning for <10.8
sed -i '' "s@MACOSX_DEPLOYMENT_TARGET='10.3'@MACOSX_DEPLOYMENT_TARGET='10.8'@" Makefile

# Some users on old versions of MacOS 10.13 run into the error:
# dyld: cannot load 'PathOfBuilding' (load command 0x80000034 is unknown)
#
# It looks like 0x80000034 is associated with the fixup_chains optimization
# that improves startup time:
# https://www.emergetools.com/blog/posts/iOS15LaunchTime
#
# For compatibility, we disable that using the flag from this thread:
# https://github.com/python/cpython/issues/97524
if ! grep -q "LDFLAGS           =" Makefile; then
  sed -i '' '/LIBS              =/a\
LDFLAGS           = -Wl,-no_fixup_chains
' Makefile
fi
popd
