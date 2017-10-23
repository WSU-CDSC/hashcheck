# A script to aid in checksum creation and verification!

## About
This is a script that interfaces with the program hashdeep (project website at [http://md5deep.sourceforge.net/start-hashdeep.html](http://md5deep.sourceforge.net/start-hashdeep.html))to generate and compare md5 checksum manifests. It can be run manually or added as an automated process.

## Requirements and Installation

Requires hashdeep, and the Ruby scripting language to be installed.

Ruby must be configured by running `gem install mail` and `gem install os`.

Information for installing Ruby can be found at [https://www.ruby-lang.org/en/documentation/installation/](https://www.ruby-lang.org/en/documentation/installation/)

Hashdeep can be installed via the following methods:

Windows: Move the included hashdeep64.exe file to your path.

Linux: Many linux distributions can install hashdeep with the command `sudo apt-get hashdeep`

Mac: Hashdeep can be installed via Homebrew.  First configure homebrew following the instructions at [https://brew.sh/](https://brew.sh/).  Then run the command `brew install hashdeep`
