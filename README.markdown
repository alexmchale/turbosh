# TurboShell #

## Description ##

*TurboShell* is a development environment for the iPad.

## Features ##

* Integrates with the popular version control system *Git*.
* Use *SSH* to compile and run the software on a remote server.
* Support *syntax highlighting* and *autoindentation*.
* Local files exist on the iPad and are synchronized.  Works off-line.
* The destination folder may be considered volitale.  Perhaps recommend that it
  is a clone of the real repository.

## Workflow (Straight Copy) ##

* Create a new project.
  * Assign it a name.
  * Assign your SSH credentials - hostname, port, username, password, path.
  * The path is the folder to use on the remote server.
* Select files to manage from the remote server.
* Those files will be downloaded to TurboShell.
* They will be uploaded back to the server when it is updated.
* The server will be periodically checked to see if a new version is available.
* A large question is how to merge the two files if they differ.

## Workflow (Local Git) ##

* Create a new project.
  * Assign your git url and password or key.
  * Assign your SSH credentials - username, password, key.
  * Create various SSH tasks - stored commands.
* Pull from one or more remote repositories.
* Edit your code.  All code is stored locally on the iPad.
* Commit locally.  The repo on your iPad is a full-flegded git clone.
* Push your changes to your git origin.
* Run your build task.

## Problems ##

* Need a clean way to upload in-progress code.  *rsync* is a good candidate
  for this task.
* Tightly coupling the local revision to the remote side may be the best
  solution.  Git would run only on the server, but the IDE would interpret its
  output.
* Instead of having a local Git repository, perhaps synchronize selected files.
* Git, Hg, SVN integration could be added later via the SSH layer.

## Major Implementation Tasks ##

* Git
* SSH
* Editor widget with syntax highlighting and autoindentation.
* Configuration screens
* File list / switcher

## Road Map ##

1. An editor, no saving, just a single view
2. Syntax highlighting
3. Auto-indentation
4. File saving & any other editor finishing touches
5. Create project, add SSH configuration, download files
6. At start-up, file-save and button-press synchronize files
7. Configurable tasks to run on the SSH server & provide output
