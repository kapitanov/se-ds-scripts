se-ds-scripts
=============

Script to install **Space Engineers Dedicated Server** on a server.

Installation
------------

Run the following command in Powershell console:

```shell
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/kapitanov/se-ds-scripts/master/install.ps1'))
```

It's important to run this command in evelated terminal.

This command will:

* install SteamCMD
* install Space Engineers DS from Steam
* install scripts and shortcuts to run and update Space Engineers DS

Usage
-----

Installation script will add two shortcuts to your desktop:

* `Start SpaceEngineers DS`
* `Update SpaceEngineers DS`

Their names should be self-explanatory.
