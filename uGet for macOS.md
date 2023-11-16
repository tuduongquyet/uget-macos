uGet for macOS
===============

uGet for macOS is a project that contains all the necessary configuration files, themes, scripts, and instructions to create the uGet app bundle and a dmg installer image for macOS.

Binaries
--------

The macOS binaries can be downloaded from the uGet Releases page:

<https://github.com/tuduongquyet/uget2/releases>

Configuration
-------------  

In addition to standard uGet configuration, the macOS bundle creates its own configuration file under `~/.config/uget/uget_mac.conf` upon first start. In this configuration file, it is possible to override the used theme (light/dark) when autodetection based on the macOS system theme is not desired.

Files and Directories
---------------------

A brief description of the contents of the project directory:

### Directories  

* *launcher*: A binary launcher used to set up environment variables to run uGet.
* *Prof-Gnome*: Prof-Gnome 3.6 GTK 3 Theme with minor modifications.
* *Papirus, Papirus-Dark*: Papirus GTK 3 icon theme with many unnecessary icons removed to save space.
* *macos-icon-design*: Design file for macOS uGet icon.  
* *iconbuilder.iconset*: Source uGet icons for the bundle.
* *modulesets-stable, patches*: Copy of the modulesets-stable and patches directory from the [gtk-osx](https://gitlab.gnome.org/GNOME/gtk-osx/) project containing dependency specifications. Since the upstream project is sometimes unstable, this allows a snapshot of a working configuration for our build.
* *patches*: Various patches fixing dependencies to enable bundling.
* *utils*: Various utility scripts.

### Configuration files  

* *Info.plist*: macOS application configuration file containing basic information like application name, version, etc. Also additional configuration including file types the application can open.
* *uget.bundle*: Configuration file describing the contents of the app bundle.
* *uget.entitlements*: Runtime hardening entitlements file.
* *uget.modules*: JHBuild modules file with uGet dependencies.
* *settings.ini*: Default theme configuration file for GTK 3.

### Scripts

* *bundle.sh*: Script to create the app bundle.  
* *create_dmg.sh*: Script calling create-dmg to create the dmg installer image.
* *notarize.sh*: Script for notarizing the dmg using the Apple notary service.
* *sign.sh*: Script for signing the app bundle.

General Instructions
--------------------

For more general instructions about building and bundling macOS applications, please visit:

* <https://gitlab.gnome.org/GNOME/gtk-osx/>
* <https://gitlab.gnome.org/GNOME/gtk-mac-bundler/>

The HOWTO below contains just the portions necessary/relevant for building and bundling uGet.

Prerequisites
-------------

* macOS
* Xcode and command-line tools  

Building
--------

To create the bundle, you first need to install JHBuild and GTK as described below:

1. Create a new account for jhbuild to ensure it does not interfere with other command-line tools installed on your system.

2. When cross-compiling x86_64 binaries on a new ARM-based Apple computer, run:

 ```
env /usr/bin/arch -x86_64 /bin/zsh --login
```

to create an x86_64 shell. All compilation steps below must be executed in this shell.

3. Depending on the shell used, add the following lines to `.zprofile` or `.bash_profile` to define these variables and restart your shell:

 ```
export PATH=$PATH:"$HOME/.new_local/bin"
export LC_ALL=en_US.UTF-8  
export LANG=en_US.UTF-8
```

4. Get `gtk-osx-setup.sh` by running:

 ```
curl -L -o gtk-osx-setup.sh https://gitlab.gnome.org/GNOME/gtk-osx/raw/master/gtk-osx-setup.sh
```

And run it:

 ```  
bash gtk-osx-setup.sh
```

5. Add the following lines to `~/.config/jhbuildrc-custom`:

 ```
setup_sdk(target="10.13", architectures=["x86_64"]) 
#setup_sdk(target="11", architectures=["arm64"])
setup_release() # enables optimizations
```

With these settings, the build creates a 64-bit Intel binary that works on macOS 10.13 and later. Instead of `x86_64` you can specify `arm64` to produce binaries for Apple ARM processors. This only works when building on ARM processors - it is not possible to compile ARM binaries on Intel processors.

6. Install GTK and all its dependencies by running the following command inside the `uget-osx` directory:

 ```
jhbuild bootstrap-gtk-osx && jhbuild build meta-gtk-osx-bootstrap meta-gtk-osx-gtk3
```

If the upstream project fails to build, use our snapshot of modulesets that was used to build the last uGet release:

 ```
jhbuild bootstrap-gtk-osx && jhbuild -m "https://raw.githubusercontent.com/uget/uget-osx/master/modulesets-stable/gtk-osx.modules" build meta-gtk-osx-bootstrap meta-gtk-osx-gtk3
```

7. To build uGet, plugins, and all dependencies, run one of the following commands inside `uget-osx` depending on whether to use uGet sources from the latest release tarball or current git master:

* **tarball**  

  ```
  jhbuild -m `pwd`/uget.modules build uget-bundle-release
  ```

* **git master**

  ```
  jhbuild -m `pwd`/uget.modules build uget-bundle-git
  ```

Bundling
--------  

1. Build the launcher binary by running:

 ```
xcodebuild ARCHS=`uname -m` -project launcher/uget/uget.xcodeproj clean build
```

inside `uget-osx`.

2. Start the jhbuild shell:

 ```
jhbuild shell
```

*Steps 3 and 4 assume you are running from within the jhbuild shell.*

3. To bundle all available uGet themes, get them from <https://github.com/uget/uget-themes> and copy the `colorschemes` directory under `$PREFIX/share/uget`.

4. Inside `uget-osx`, create the app bundle:

 ```
./bundle.sh
```

5. Exit the jhbuild shell with `exit`.

6. Optionally, to sign the resulting bundle with a development Apple account, get the signing identities:

 ```
security find-identity -p codesigning
```

Use the whole string within apostrophes containing "Developer ID Application: ..." in:

 ```
export SIGN_CERTIFICATE="Developer ID Application: ..." 
```

Then run:

 ```
./sign.sh
```

Distribution
------------

1. Get `create-dmg` from <https://github.com/andreyvit/create-dmg.git> and add it to your `$PATH`.

2. Create the dmg installation image by running:

 ```
./create_dmg.sh
```

from `uget-osx`. If `SIGN_CERTIFICATE` is defined, the image gets signed.

3. Optionally, to get the image notarized by [Apple notary service](https://developer.apple.com/documentation/security/notarizing_your_app_before_distribution), run:

 ```
./notarize.sh <dmg_file> <apple_id> 
```

Where `<dmg_file>` is the generated dmg file and `<apple_id>` is the Apple ID used for your developer account. The script prompts for an [app-specific password](https://support.apple.com/en-us/HT204397) generated for your Apple ID.

Maintenance
-----------

Some maintenance activities not required for normal bundle/installer creation:

* Sync `Info.plist` file associations with `filetype_extensions.conf` by copying the filetype extension portion from `filetype_extensions.conf` to the marked place in `utils/plist_filetypes.py`, running the script, and copying the output to the marked place in `Info.plist`.

* Before release, update the uGet version and copyright years in `Info.plist` and `create_dmg.sh`. Also update the `-release` targets in `uget.modules` to the new release. Dependencies in `uget.modules` can also be updated.  

* Copy `modulesets-stable` from [gtk-osx](https://gitlab.gnome.org/GNOME/gtk-osx/) into this project to get the latest dependencies (if it builds) and possibly modify it if something does not work.

* To ensure nothing is left from a previous build when making a new release, run:

 ```
rm -rf .new_local .local Source gtk .cache/jhbuild
```

---

Tu Duong Quuet, 2023
