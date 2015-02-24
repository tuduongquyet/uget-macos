Geany OS X
==========
Geany OS X is a project that contains all the necessary configuration
files, themes, scripts and instructions to create the Geany app bundle and 
a dmg installer image for OS X.

Files and Directories
---------------------
A brief description of the contents of the project directory:

### Directories
*	*Faience*: Faience icon theme combined with Faenza-Cupertino 
	icon theme (for better folder icons) and with lots of unneeded icons
	removed to save space.
*	*iconbuilder.iconset*: contains source icons for the Geany.icns
	file. Not needed for normal build, present just in case the icns file
	needs to be recreated for some reason.
*	*patches*: patches fixing VTE under OS X and enabling VTE bundling. 

### Configuration files
*	*geany.modules*: JHBuild modules file with Geany dependencies.
*	*geany.bundle*: configuration file describing the contents of the
	app bundle.
*	*Info.plist*: OS X application configuration file containing some basic
	information such as application name, version, etc. but also additional
	configuration including file types the application can open.
*	*gtkrc.theme, close.png*: GTK theme based on the Greybird theme and 
	modified to match the OS X Yosemite theme better.
*	*gtkrc*: GTK configuration file including the theme file and changing
	some Geany gtkrc settings.
*	*Geany.icns*: OS X Geany icon file.

### Scripts
*	*launcher.sh*: launcher script from the gtk-mac-bundler project setting
	all the necessary environment variables.
*	*replace_icons.sh*: script replacing the color icons distributed together
	with Geany with grey icons from the Faience theme.
*	*plist_filetypes.py*: script generating the file type portion of the
	Info.plist file from Geany's filetype_extensions.conf configuration
	file.
*	*create_dmg.sh*: script calling create-dmg to create the dmg installer
	image. 

General Instructions
--------------------
For more general instructions about building and bundling OS X applications
please visit

<https://wiki.gnome.org/Projects/GTK%2B/OSX/>

The HOWTO below contains just the portions necessary/relevant for
building and bundling Geany.

Prerequisities
--------------
*	OS X 10.7 or later (tested with OS X 10.10)
*	Xcode and command-line tools (tested with Xcode 6.1.1)

JHBuild Installation
--------------------
To create the bundle, you need to first install JHBuild and GTK as described below.

1.	Create a new account for jhbuild (not necessary but this makes sure
	jhbuild will not interfere with some other command-line tools installed
	on your system).

2.	Get `gtk-osx-build-setup.sh` from

	<https://git.gnome.org/browse/gtk-osx/plain/gtk-osx-build-setup.sh>

	and run it.

3.	Run

	```
	export PATH=$PATH:"~/.local/bin"
	```

	to set path to jhbuild installed in the previous step.

4.	By default, jhbuild compiles without optimization flags. To enable
	optimization, add `setup_release()` at the end of `~/.jhbuildrc-custom`.

5.	Install GTK 2 and all its dependencies using the following commands:

	```
	jhbuild bootstrap
	jhbuild build meta-gtk-osx-bootstrap
	jhbuild build meta-gtk-osx-core 
	```

	Instead of meta-gtk-osx-core (GTK 2) you can also use `meta-gtk-osx-gtk3` to
	install GTK 3. Note that both GTK 2 and GTK 3 cannot be installed at the 
	same time. Also note that there seem to be various problems with the OS X 
	support in GTK 3; for this reason I have not spent more time with the GTK 3 
	backend so there is no GTK3-specific theme or bundling support at this 
	moment.

7.	Run

	```
	jhbuild shell
	```

	to start jhbuild shell. 

	**The rest of this HOWTO assumes you are running from within the jhbuild shell!**

Geany Installation
------------------
1.	Docutils will fail if you do not set the following environment variables:

	```
	export LC_ALL=en_US.UTF-8
	export LANG=en_US.UTF-8
	```

2.	Inside the geany-osx directory run

	```
	jhbuild -m geany.modules build geany-bundle
	```

	There are other useful module installation options e.g. if you plan to develop
	Geany - check the geany.modules file for more options.

Bundling
--------
1.	To bundle all available Geany themes, get them from

	<https://github.com/codebrainz/geany-themes.git>

	and copy the colorschemes directory under `$PREFIX/share/geany`.

2.	Go to the geany-osx directory and copy the Faience icon theme to the 
	gtk icons directory:

	```
	cp -r Faience $PREFIX/share/icons
	```

3.	Replace Geany color icons by grey icons from the Faience theme by calling

	```
	./replace_icons.sh
	```

	from within the geany-osx directory.

4.	Create the app bundle by calling

	```
	gtk-mac-bundler geany.bundle
	```

	from within the geany-osx directory.

Distribution
------------
1.	Get the create-dmg script from

	<https://github.com/andreyvit/create-dmg.git>

	and put it to your $PATH.

2.	Create the dmg installation image by calling
	
	```
	./create_dmg.sh
	```

	from within the geany-osx directory.

Maintenance
-----------
This section describes some maintenance-related activities which do not
have to be performed during normal bundle/installer creation:

*	To get the Info.plist file associations in sync with 
	filetype_extensions.conf, copy the filetype extension portion from
	filetype_extensions.conf to the marked place in plist_filetypes.py
	and run the script. Copy the output of the script to the marked
	place in Info.plist.

*	The Geany.icns icon file can be regenerated from the iconbuilder.iconset
	directory using

	```
	iconutil -c icns ./iconbuilder.iconset
	```

---

Jiri Techet, 2015