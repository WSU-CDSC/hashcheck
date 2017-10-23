# A script to aid in checksum creation and verification!

## About
This is a script that interfaces with the program [hashdeep](http://md5deep.sourceforge.net/start-hashdeep.html) to generate and compare md5 checksum manifests. It can be run manually or added as an automated process.

## Requirements and Installation

Requires hashdeep, and the Ruby scripting language to be installed.

### Linux Installation:
Many linux distributions can install necessary elements via their built in package manager. Use the following commands in Terminal:

`sudo apt-get install hashdeep` (Install Hashdeep).

`sudo apt-get install ruby` (Install Ruby). Alternately information on installing the most recent release of Ruby can be found at the [Ruby Documentaion](https://www.ruby-lang.org/en/documentation/installation/) site.

`sudo gem install mail && sudo gem install os` (Install required Ruby libraries).

### Windows Installation:
Install Ruby using the tool ['Ruby Installer.'](https://rubyinstaller.org/)

Use the Command Prompt and run the following commands:

`gem install mail && gem install os` (Install required Ruby libraries).

Move the file hashdeep64.exe that is supplied with this repository into a folder that is on your 'Environment Variable' path.

### Mac Installation

Mac: Hashdeep can be installed via Homebrew.  First configure homebrew following the instructions at [https://brew.sh/](https://brew.sh/).  Then run the commands:

`brew install hashdeep` (Install hashdeep)
`sudo gem install mail && sudo gem install os` (Install required Ruby libraries).

