Turbosh is an SSH project manager. It's good at viewing files, editing them, and launching tasks on your server.

Turbosh lets you view and edit files while offline. It'll synchronize them back to the server at the next opportunity.

* Please see the Known Issues section below *


### Typical Workflow ###

A typical workflow with Turbosh may look like:

1. Add SSH login/password and set the path for your project.
2. Select what files you would like to edit in Turbosh.
3. Select what tasks you would like to launch from Turbosh. Tasks are any files with user executable permission in your project directory.
4. Start viewing files, editing files, or launching tasks.


### Origin of Turbosh ###

Turbosh came from a time on a plane. I wanted to make a few small tweaks to some code I was thinking about. Flying in coach, it was incredibly uncomfortable to use my laptop on the plane. I was wishing that I had a way to edit those files on my iPad. Turbosh is that way!


### Syntax Highlighting ###

The following languages are syntax highlighted in the file viewer:

C, C++, C#, CSS, HTML, Java, Javascript, LaTeX, Perl, PHP, Python, Ruby, Scala, SQL, Tcl, XML

Please note that the file editor does not show the files syntax-highlighted.


### Known Issues ###

There's a limit of the number files in a path that Turbosh can handle.  I have had success with folders up to 50,000 files.  A customer sent in a report that it was failing against a folder of about 700,000 files.  The limit is somewhere in the middle.

Turbosh does not work if /bin/sh is not bash. This is fixed in v2.0.

Please email me at alexmchale@gmail.com if you run into any troubles with Turbosh.


### Changes ###

v2.0

* Turbosh is now an iPad/iPhone hybrid app!
* Support for fast app switching (iOS4 only).
* The synchronizer will now run one time when the app is put in the background (iOS4 only).
* Tasks should now launch faster, even if the synchronizer is running.
* Fixed a bug that caused systems that had /bin/sh as a shell other than bash.
* Fixed a bug that could cause the synchronizer to stall if no valid authentication mode could be found.

v1.3

* Feature: There is now a gear in the file viewer to change the font size. Five sizes are available.
* Feature: There is a new screen that lets you synchronize a directory. This causes all new files that appear in that directory to be downloaded when synchronizing.
* Feature: New screen to edit the parameters passed to a task when it is run. Ability to run arbitrary commands as tasks.
* Feature: Public key authentication is now supported. Turbosh now has a public key that will be tried before the password for authentication.
* The current project is now marked with a checkmark in the file list.
* When adding a new project, Turbosh will now clone the current project's host, port, username, password and path settings.
* Bug Fix: Turbosh now only uses POSIX parameters when calling find. This enables support for Solaris.
* Bug Fix: Project paths that contain files the user cannot read would cause files lists to fail.
* Improve support for UTF-8, UTF-16 and UTF-32 files.

v1.2

* Paths or filenames with spaces are now handled correctly.
* Shells other than bash (zsh, csh, tcsh, etc) are now supported.
* Files are now initially downloaded in the background. A warning will be shown if you try to access them before they have been downloaded.
* A clear button is now presented when editing project settings fields.
* After saving a file, that project will be synchronized. Previously all projects were synchronized, causing a long delay before uploading the changes.
* Fixed all known crash bugs, overall performance and stability improvements.

v1.1

* The toolbar acts better.
* Adding/deleting projects should work more reliably.
* Connecting to OSX now works properly.
* The editor will no longer go all-white in landscape mode.
* Cancel/save buttons can no longer be tapped while the synchronized-files/task-executables screens are loading.
* The synchronization status messages should be more useful now.
* Show the user an alert when neither the md5 nor md5sum commands exist on the server.
* Fixed a bug where sometimes a server failing to connect during synchronization could lock up the app until it times out.
* Fixed a bug caused by UTF-8 characters in filenames.  The bug would cause the app to lock up or crash.
* Fixed a bug when the file or task lists fail, the Cancel button would not be replaced by the Project button in portrait mode.
