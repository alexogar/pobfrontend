PoBFrontend
===========

A cross-platform [Path of Building](https://github.com/Openarl/PathOfBuilding) driver.

Building
--------

### Steps to build on Apple Silicon (arm64)

If you're using the default Apple Silicon Homebrew prefix (`/opt/homebrew`), you can install dependencies with:

```sh
make tools
```

### Steps to build an x86_64 binary on M1 Macs

Before starting, you need to install Homebrew for x86_64.

1. Install Rosetta if you haven't via `softwareupdate --install-rosetta`
2. Run the [Homebrew installation command](https://docs.brew.sh/Installation),
   but prepend `arch --x86_64`. The command will be `arch --x86_64 bash -c ...`
3. Create a `~/.intelbrew` file with these contents:
   ```sh
   eval "$(/usr/local/bin/brew shellenv)"
   alias brew='arch --x86_64 /usr/local/bin/brew'
   ```
4. Include it to update your environment variables by running `. ~/.intelbrew`
5. Edit Homebrew to fetch packages for Ventura (10.13), since the Qt package
   for Sonoma (10.14) breaks compatibility with libc++: see [this error](https://www.pathofexile.com/forum/view-thread/3009944/page/34#:~:text=__ZTVNSt3__13pmr25monotonic_buffer_resourceE)

```sh
vim /usr/local/Homebrew/Library/Homebrew/brew.sh
# Edit the file to comment out the version and hardcode it:
# #HOMEBREW_MACOS_VERSION="$(/usr/bin/sw_vers -productVersion)"
# HOMEBREW_MACOS_VERSION="12.0.0"

# Run this only once after installing Homebrew to install dependencies
ARCH_PREFIX="arch -x86_64" BREW=/usr/local/bin/brew make tools

# Build the entire app
export PATH="$(brew --prefix qt@5)/bin:$PATH"
make

# Optionally sign it for distribution
make sign
```

### Dependencies:

- Qt5
- luajit
- zlib
- opengl
- lua-curl (see below)
- Bitstream-Vera and Liberation TTF fonts. Will work without these but most likely look terrible.

### Build dependencies:

- meson
- pkg-config
- ninja (optional, can tell meson to generate makefiles if you prefer)

### Ensuring old versions of Mac are compatible:

By default, the built lcurl.so links to the local version of cURL. Old
versions of cURL on old Macs may be too old to include the relevant functions and run into this error:

```
Error loading main script: error loading module 'lcurl.safe' from file './lcurl.so':
  dlopen(./lcurl.so, 6): Symbol not found: _curl_easy_option_by_id
    Referenced from: ./lcurl.so (which was built for Mac OS X 13.0)
    Expected in: /usr/lib/libcurl.4.dylib
```

To try to fix this issue, we include the libcurl.4.dylib in our app
using dylibbundler.

We change it in mesonInstaller.sh based on https://stackoverflow.com/a/38709580/319066

- `otool -L lcurl.so` can be used to debug the paths.
- `install_name_tool ...` is used to change the paths behind the scenes, but
  dylibbundler does all the work for us.

## Old manual steps to build:

### Build Lua-Curl:

You need to build [Lua-Curl](https://github.com/Lua-cURL/Lua-cURLv3) for luajit.

Edit the Lua-Curl Makefile:

```diff
@@ -7,7 +7,7 @@ DESTDIR          ?= /
 PKG_CONFIG       ?= pkg-config
 INSTALL          ?= install
 RM               ?= rm
-LUA_IMPL         ?= lua
+LUA_IMPL         ?= luajit
 CC               ?= $(MAC_ENV) gcc
 
 LUA_VERSION       = $(shell $(PKG_CONFIG) --print-provides --silence-errors $(LUA_IMPL))
```
 
Run make. You should get `lcurl.so`.

### Get the PoBFrontend sources:

`git clone https://github.com/philroberts/pobfrontend.git`

### Build:

```bash
meson -Dbuildtype=release pobfrontend build
cd build
ninja
```

Run the thing:

```bash
cd /path/to/PathOfBuilding # <- a pathofbuilding git clone
for f in tree*.zip; do unzip $f;done # <- use the provided tree data because reasons
unzip runtime-win32.zip lua/xml.lua lua/base64.lua lua/sha1.lua
mv lua/*.lua .
rmdir lua
cp /path/to/lcurl.so . # our lcurl.so from earlier
/path/to/build/pobfrontend
```

You can adjust the font size up or down with a command line argument:

```bash
pobfrontend -2
```

### Notes:

I have the following edit in my PathOfBuilding clone, stops it from saving builds even when I tell it not to:

```diff
--- a/Modules/Build.lua
+++ b/Modules/Build.lua
@@ -599,7 +599,7 @@ function buildMode:CanExit(mode)
 end
 
 function buildMode:Shutdown()
-       if launch.devMode and self.targetVersion and not self.abortSave then
+       if false then --launch.devMode and self.targetVersion and not self.abortSave then
                if self.dbFileName then
                        self:SaveDBFile()
                        elseif self.unsaved then
```

###### OS X

On mac you need to invoke meson with some extra flags, per the luajit documentation:

```bash
LDFLAGS="-pagezero_size 10000 -image_base 100000000" meson pobfrontend build
```


