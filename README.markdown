Turbosh is an SSH project manager. It's good at viewing files, editing them, and launching tasks on your server.

Turbosh lets you view and edit files while offline. It'll synchronize them back to the server at the next opportunity.

* Please see the Known Issues section below *

* Version 1.2 has been submitted to Apple for review *


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

Turbosh does not play nice if you have your shell set to something other than bash or sh. This is fixed in v1.2.  For now, consider changing your shell or adding a second user account that uses bash.

Paths or filenames with spaces in them do not work properly. This is fixed in v1.2.

There's a limit of the number files in a path that Turbosh can handle.  I have had success with folders up to 50,000 files.  A customer sent in a report that it was failing against a folder of about 700,000 files.  The limit is somewhere in the middle.

Please email me at alexmchale@gmail.com if you run into any troubles with Turbosh.


### Changes ###

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
