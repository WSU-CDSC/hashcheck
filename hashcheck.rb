#!/usr/bin/env ruby
# Version 2018-01-03

require 'csv'
require 'gmail'
require 'yaml'
require 'os'

#Enter Location of Configuration File between the single quotes In this section!!
########
configuration_file = '' 
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

if TargetList.empty? || HashDirectory.empty? || OutputDirectory.empty?
  puts "Missing settings found. Please recheck settings in configuration file. Exiting."
  exit
elsif ! Dir.exist?(HashDirectory) || ! Dir.exist?(OutputDirectory)
  puts "Directory specified in configuration not found. Please double check settings in configuration file. Exiting."
  exit
elsif MailOption == "Y" && MailFrom.empty? && MailTo.empty?
  puts "Missing email settings found. Please recheck settings in configuration file. Exiting."
  exit
end

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

TargetList.each.with_index do |targetlocation, index|
  # Confirm input
  if Dir.exist?(targetlocation)
    #Set up Variables
    starttime = Time.now
    runtimeextension = starttime.strftime("%Y%m%d_%H%M%S")
    collection = File.basename(targetlocation)
    hashlist = Dir.entries(HashDirectory).grep(/#{collection}/).sort.reject{|entry| entry[0] == "."}
    targetmanifest = hashlist.last
    hashname = "#{collection}_md5_manifest_#{runtimeextension}.txt"

    #Generate New Manifest
    if OS.windows?
      command = %{#{hashdeeppath} -e -c md5 -r "#{targetlocation}"}
    else
      command = "#{hashdeeppath} -e -c md5 -r '#{targetlocation}'"
    end
    writemanifest = `#{command}`
    finishtime = Time.now
    File.write("#{HashDirectory}/#{hashname}", "#{writemanifest}")

    #Exit if no prior manifest to compare
    if hashlist.empty?
      if index == TargetList.size-1
        exit
      else
        next
      end
    end

    #Compare Manifests
    oldmanifest = Array.new
    newmanifest = Array.new
    File.readlines("#{HashDirectory}/#{targetmanifest}").each do |line|
      if ! line.include?('Thumbs.db')
        if OS.windows?
          oldmanifest << line.gsub("\\", "/")
        else
          oldmanifest << line
        end
      end
    end
    File.readlines("#{HashDirectory}/#{hashname}").each do |line|
      if ! line.include?('Thumbs.db')
        if OS.windows?
          newmanifest << line.gsub("\\", "/")
        else
          newmanifest << line
        end
      end
    end
    neworchanged = (newmanifest - oldmanifest)
    deleted = (oldmanifest - newmanifest)
    confirmed = ((oldmanifest & newmanifest).reject{|entry| entry[0..1] == "##" || entry[0..3] == "%%%%"})

    #Check for new renamed or altered files
    changedfiles = Array.new
    renamedfiles = Array.new
    newfiles = Array.new
    deletedfiles = Array.new
    confirmedfiles = Array.new
    copiedfiles = Array.new

    # Get paths for confirmed files
    confirmed.each do |result|
      md5 = result.split(",")[1]
      path = result.split(",")[2]
      confirmedfiles << path
    end


    neworchanged.each do |result|
      md5 = result.split(",")[1]
      path = result.split(",")[2]
      pathtest = oldmanifest.grep(/#{path}/)
      md5test = oldmanifest.grep(/#{md5}/)
      md5pathtest = oldmanifest.grep(/#{md5},#{path}/)
      #Check if path exists in old manifest but "hash,path" doesn't (altered file)
      if pathtest.any? && md5pathtest.empty?
        changedfiles << path 
      end
      #Check if hash exists in old manifest but path doesn't AND paths returned in hash check do not exist in new manifest(renamed file)
      if pathtest.empty? && md5test.any?
        md5test.each do |line|
          originpath = line.split(",")[2]
          if newmanifest.grep(/#{line}/).empty? && renamedfiles.grep(/#{originpath}/).empty? && renamedfiles.grep(/#{path}/).empty?
            renamedfiles << "#{originpath},->,#{path}"
          elsif newmanifest.grep(/#{path}/) && renamedfiles.grep(/#{path}/).empty?
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

    #Check for deleted files ("md5,path" does not exist in new manifest and md5 does not exist in "New or Changed" files/path does not exist in changedfiles)
    deleted.each do |result|
      md5 = result.split(",")[1]
      path = result.split(",")[2]
      md5pathtest = newmanifest.grep(/#{md5},#{path}/)
        if md5pathtest.empty? && neworchanged.grep(/#{md5}/).empty? && changedfiles.grep(/#{path}/).empty?
        deletedfiles << path 
      end
    end

    # Remove false positives for copies
    copiedfiles.each do |copyline|
      renamedfiles.each do |renameline|
        if renameline.include?(copyline)
          copiedfiles.delete(copyline)
        end
      end
    end

    #Write csv
    csvpath = "#{OutputDirectory}/#{collection}_fixity_report_#{runtimeextension}.csv"
    CSV.open(csvpath, "ab") do |csv|

      csv << ["Target", targetlocation]
      csv << ["Comparing", targetmanifest, hashname]
      csv << ["Start Time", starttime]
      csv << ["End Time", finishtime]
      csv << ["New Files Total", newfiles.count]
      csv << ["Changed Files Total", changedfiles.count]
      csv << ["Copied Files Total", copiedfiles.count]
      csv << ["Renamed or Moved", renamedfiles.count]
      csv << ["Deleted Files Total", deletedfiles.count]
      csv << ["Confirmed Files Total", confirmed.count]

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
            subject  "Fixity report for #{targetlocation} on #{starttime}"
            body     "Fixity report for #{targetlocation} on #{starttime}\n
            Changed Files Total, #{changedfiles.count}\n
            Renamed Files Total, #{renamedfiles.count}\n
            Deleted Files Total, #{deletedfiles.count}\n
            New Files Total, #{newfiles.count}\n
            Confirmed Files Total, #{confirmed.count}"
            add_file :filename => "fixity_report_#{runtimeextension}.csv", :content => File.read(csvpath)
          end
          gmail.deliver(email)
        end
      end
    end
  else
    puts "Input: #{targetlocation} not found. Skipping"
    next
  end
end
