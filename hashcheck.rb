#!/usr/bin/env ruby

require 'csv'
require 'gmail'
require 'yaml'
require 'os'

#Enter Location of Configuration File between the single quotes In this section!!
########
configuration_file = '/home/weaver/Desktop/fixityconfig.txt' 
########

path2script = __dir__
DefaultConfigLocation = "#{path2script}/hashcheck_config.txt"
if configuration_file.empty?
	configuration_file = DefaultConfigLocation
end

if ! File.exist? configuration_file
	puts "Selected configuration file not found. Exiting"
	exit
end

config = YAML::load_file(configuration_file)
TargetList = config['Target for Hashing'].split(",")
HashDirectory = config['Hash Manifest Storage']
OutputDirectory = config['Report Destination']
MailFrom = config['Send Email From']
MailTo = config['Send Email To'].split(",")
MailPassword = config['Email Password']
MailOption = config['Send Email']

TargetList.each do |targetlocation|
  if targetlocation.empty? || HashDirectory.empty? || OutputDirectory.empty?
  	puts "Missing settings found. Please recheck settings in configuration file. Exiting."
  	exit
  elsif MailOption == "Y" && MailFrom.empty? && MailTo.empty?
  	puts "Missing email settings found. Please recheck settings in configuration file. Exiting."
  	exit
  end

  		

  #Set up Variables
  StartTime = Time.now
  RunTimeExtenstion = StartTime.strftime("%Y%m%d_%H%M%S")
  HashList = Dir.entries(HashDirectory).sort.reject{|entry| entry[0] == "."}
  TargetManifest = HashList.last
  HashName = "md5_manifest_#{RunTimeExtenstion}.txt"

  #Check for hashdeep
  if OS.windows?
    DefaultHashdeepLocation = "#{path2script}/hashdeep64.exe"
    if ! system('hashdeep64.exe -h', [:out, :err] => File::NULL) && ! File.exist?(DefaultHashdeepLocation)
      puts "Required program Hashdeep not found. Please see installation information at http://md5deep.sourceforge.net/start-hashdeep.html"
      exit
  elsif ! system('hashdeep64.exe -h', [:out, :err] => File::NULL) && File.exist?(DefaultHashdeepLocation)
    hashdeeppath = DefaultHashdeepLocation
    else
      hashdeeppath = 'hashdeep64.exe'
    end
  else
    DefaultHashdeepLocation = "#{path2script}/hashdeep"
    if ! system('hashdeep -h', [:out, :err] => File::NULL) && ! File.exist?(DefaultHashdeepLocation)
      puts "Required program Hashdeep not found. Please see installation information at http://md5deep.sourceforge.net/start-hashdeep.html"
      exit
    elsif ! system('hashdeep -h', [:out, :err] => File::NULL) && File.exist?(DefaultHashdeepLocation)
      hashdeeppath = DefaultHashdeepLocation
    else
      hashdeeppath = 'hashdeep'
    end
  end

  #Generate New Manifest
  if OS.windows?
    command = "#{hashdeeppath} -c md5 -r #{targetlocation}"
  else
    command = "#{hashdeeppath} -c md5 -r #{targetlocation}"
  end
  WriteManifest = `#{command}`
  FinishTime = Time.now
  File.write("#{HashDirectory}/#{HashName}", "#{WriteManifest}")

  #Exit if no prior manifest to compare
  if HashList.empty?
    exit
  end

  #Compare Manifests
  OldManifest = Array.new
  NewManifest = Array.new
  File.readlines("#{HashDirectory}/#{TargetManifest}").each do |line|
  	if OS.windows?
  		OldManifest << line.gsub("\\", "/")
  	else
  	  OldManifest << line
  	end
  end
  File.readlines("#{HashDirectory}/#{HashName}").each do |line|
  	if OS.windows?
  		NewManifest << line.gsub("\\", "/")
  	else
  		NewManifest << line
  	end
  end
  NewOrChanged = (NewManifest - OldManifest)
  Deleted = (OldManifest - NewManifest)
  Confirmed = ((OldManifest & NewManifest).reject{|entry| entry[0..1] == "##" || entry[0..3] == "%%%%"})

  #Check for new renamed or altered files
  changedfiles = Array.new
  renamedfiles = Array.new
  newfiles = Array.new
  deletedfiles = Array.new
  confirmedfiles = Array.new
  copiedfiles = Array.new

  # Get paths for confirmed files
  Confirmed.each do |result|
    md5 = result.split(",")[1]
    path = result.split(",")[2]
    confirmedfiles << path
  end


  NewOrChanged.each do |result|
    md5 = result.split(",")[1]
    path = result.split(",")[2]
    pathtest = OldManifest.grep(/#{path}/)
    md5test = OldManifest.grep(/#{md5}/)
    md5pathtest = OldManifest.grep(/#{md5},#{path}/)
    #Check if path exists in old manifest but "hash,path" doesn't (altered file)
    if pathtest.any? && md5pathtest.empty?
      changedfiles << path 
    end
    #Check if hash exists in old manifest but path doesn't AND paths returned in hash check do not exist in new manifest(renamed file)
    if pathtest.empty? && md5test.any?
      md5test.each do |line|
        originpath = line.split(",")[2]
        if NewManifest.grep(/#{line}/).empty? && renamedfiles.grep(/#{originpath}/).empty? && renamedfiles.grep(/#{path}/).empty?
          renamedfiles << "#{originpath},->,#{path}"
        elsif NewManifest.grep(/#{path}/) && renamedfiles.grep(/#{path}/).empty?
            copiedfiles << "#{path}"
        end
        copiedfiles = copiedfiles.uniq
      end
    end
    #Check if neither hash nor path exist in old manifest manifest (new file)
    if pathtest.empty? && md5test.empty?
      newfiles << path 
    end
  end

  #Check for deleted files ("md5,path" does not exist in new manifest and md5 does not exist in "New or Changed" files)
  Deleted.each do |result|
    md5 = result.split(",")[1]
    path = result.split(",")[2]
    md5pathtest = NewManifest.grep(/#{md5},#{path}/)
      if md5pathtest.empty? && NewOrChanged.grep(/#{md5}/).empty?
      deletedfiles << path 
    end
  end

  #Write csv
  CSV.open("#{OutputDirectory}/fixity_report_#{RunTimeExtenstion}.csv", "ab") do |csv|

    csv << ["Target", targetlocation]
    csv << ["Comparing", TargetManifest, HashName]
    csv << ["Start Time", StartTime]
    csv << ["End Time", FinishTime]
    csv << ["New Files Total", newfiles.count]
    csv << ["Changed Files Total", changedfiles.count]
    csv << ["Copied Files Total", copiedfiles.count]
    csv << ["Renamed or Moved", renamedfiles.count]
    csv << ["Deleted Files Total", deletedfiles.count]
    csv << ["Confirmed Files Total", Confirmed.count]

    if OS.windows?
      newfiles.each do |result|
        towrite = ["New File", result.gsub("/", "\\")]
        csv << towrite
      end
      changedfiles.each do |result|
        towrite = ["Changed File", result.gsub("/", "\\")]
        csv << towrite
      end
      renamedfiles.each do |result|
        resulttoarray = result.split(",")
        towrite = ["Renamed or Moved File", resulttoarray[0].gsub("/", "\\"), resulttoarray[1].gsub("/", "\\"), resulttoarray[2].gsub("/", "\\")]
        csv << towrite
      end
      copiedfiles.each do |result|
        towrite = ["Copied File", result.gsub("/", "\\")]
        csv << towrite
      end
      deletedfiles.each do |result|
        towrite = ["Deleted File", result.gsub("/", "\\")]
        csv << towrite
      end
      confirmedfiles.each do |result|
        towrite = ["Confirmed File", result.gsub("/", "\\")]
        csv << towrite
      end
    else
      newfiles.each do |result|
        towrite = ["New File", result]
        csv << towrite
      end
      changedfiles.each do |result|
        towrite = ["Changed File", result]
        csv << towrite
      end
      renamedfiles.each do |result|
        resulttoarray = result.split(",")
        towrite = ["Renamed or Moved File", resulttoarray[0], resulttoarray[1], resulttoarray[2]]
        csv << towrite
      end
      copiedfiles.each do |result|
        towrite = ["Copied File", result]
        csv << towrite
      end
      deletedfiles.each do |result|
        towrite = ["Deleted File", result]
        csv << towrite
      end
      confirmedfiles.each do |result|
        towrite = ["Confirmed File", result]
        csv << towrite
      end
    end
  end

  #Email Report
  if MailOption.eql? 'Y'
    MailTo.each do |targetaddress|
      Gmail.connect(MailFrom, MailPassword) do |gmail|
        email = gmail.compose do
          from     MailFrom
          to       targetaddress
          subject  "Fixity report for #{targetlocation} on #{StartTime}"
          body     "Fixity report for #{targetlocation} on #{StartTime}\n
          Changed Files Total, #{changedfiles.count}\n
          Renamed Files Total, #{renamedfiles.count}\n
          Deleted Files Total, #{deletedfiles.count}\n
          New Files Total, #{newfiles.count}\n
          Confirmed Files Total, #{Confirmed.count}"
          add_file :filename => "fixity_report_#{RunTimeExtenstion}.csv", :content => File.read("#{OutputDirectory}/fixity_report_#{RunTimeExtenstion}.csv")
        end
        gmail.deliver(email)
      end
    end
  end
end
