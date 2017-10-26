# A script to aid in checksum creation and verification!

## About
This is a script that interfaces with the program [hashdeep](http://md5deep.sourceforge.net/start-hashdeep.html) to generate and compare md5 checksum manifests. It can be run manually or added as an automated process.

## Requirements and Installation

Requires hashdeep, and the Ruby scripting language to be installed.

### Linux Installation (Ubuntu):
Many linux distributions can install necessary elements via their built in package manager. Use the following commands in Terminal:

`sudo apt-get install hashdeep` (Install Hashdeep). Alternatively, the 'hashcheck' script will look for hashdeep in its same directory so you can use the included version.

`sudo apt-get install ruby` (Install Ruby). Alternately information on installing the most recent release of Ruby can be found at the [Ruby Documentaion](https://www.ruby-lang.org/en/documentation/installation/) site.

`sudo gem install gmail && sudo gem install os` (Install required Ruby libraries).

### Windows Installation:
Install Ruby using the tool ['Ruby Installer.'](https://rubyinstaller.org/)

Use the Command Prompt and run the following commands:

`gem install gmail && gem install os` (Install required Ruby libraries).

Move the file hashdeep64.exe that is supplied with this repository into a folder that is on your 'Environment Variable' path. Alternatively, if the included hashdeep64.exe file is left in the same directory as the 'hashcheck' script, it will be found and used by the script.

### Mac Installation

Since Ruby comes included in macOS, you don't have to worry about installing it.

Hashdeep can be installed via Homebrew.  First configure homebrew following the instructions at [https://brew.sh/](https://brew.sh/).  Then run the commands:

`brew install hashdeep` (Install hashdeep) Alternatively, the 'hashcheck' script will look for hashdeep in its same directory so you can use the included version.

`sudo gem install gmail && sudo gem install os` (Install required Ruby libraries).

## Configuration

The 'hashcheck' script includes a configuration file called `hashcheck_config.txt` that must be configured with your desired settings. To configure, open `hashcheck_config.txt` in a text editor and insert your setting between the sets of empty single quotes. Settings include:

`'Target for Hashing': ''` (The path to the location(s) you would like to hash/verify. Multiple locations can be entered, and __must be separated by commas with no spaces__)

`'Hash Manifest Storage': ''` (The path to the location to store created hash manifests)

`'Report Destination': ''` (The path to the location to create verification reports when the script is run)

`'Send Email': ''` (Set this to `Y` to enable email copies of verification reports).

`'Send Email From': ''` (The email address used to send copies of verification reports (must be a gmail account))

`'Send Email To': ''` (The email destination(s) for copies of verification reports. Multiple email addesses can be entered and __must be separated by commas with no spaces__)

`'Email Password': ''` (The password for the gmail account used for fixity reporting)

The hashcheck script will automatically find a config file stored in the same directory as itself. Alternatively, to change the location of the config file, its location can be specified within the hashcheck script.

This can be done by opening `hashcheck.rb` in a text editor and adding the path to the location of the configuration file between the single quote marks on __Line 10__.

The result should look something like this: `configuration_file = '/PathToLocation/hashcheck_config.txt'`

## Usage

Once the hashcheck script is configured, it can be run to generate an initial hash manifest for its target. Running the script subseqent times will compare a newly generated manifest against the most recent previous manifest. It will then generate a csv file report that gives totals for/lists: New files, Changed Files, Copied Files, Renamed or Moved Files, Deleted Files, and Confirmed Files. Optionally, this report can be configured for email delivery via a gmail account.

Hashcheck can either be run manually or set as a scheduled task.

## Email Usage

The 'hashcheck' script is set to use a gmail account for fixity report delivery. As you will need to change security settings on that account to enable the script to access it, it is recommended to create a dedicated account specifically for fixity reports.

The settings for this account must be configured according to [these instructions](https://github.com/gmailgem/gmail#troubleshooting).


