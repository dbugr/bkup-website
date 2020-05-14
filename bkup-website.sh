#!/bin/bash

# Handy script to backup Wordpress or Drupal website
# database and files.
# Assume database is in Devilbox Docker containers.
# http://devilbox.org/
# Assume running this script from 
# WSL Ubuntu 20.04 Bash command line

# Author: Chuck Segal
# 05/14/2020

# dump the database to .sql file in website project folder
# create website backup tar.gz file which contains the .sql dump file
# add hostname, time and date stamp to output file.

# easy to use:
# 1 set name of development pc
# 2 edit the source and destination path variables
# 3,4 make any desired changes to the mysqldump and tar command lines
# 5 create ~/.my.cnf file with [mysqldump], db username and db password
# 6 mysqldump will use the credentials in #4 when running
# 7 run the command

# examples: 
# ./bkup-website.sh -w mywebsite -d database_name
# ./bkup-website.sh -w wpsite -d wpdb
# mywebsite == name of folder that contains the website
# database_name == name of mysql database
# suggest: chmod 700 bkup-website.sh

# set the "nice" command level to reduce load on production server
NiceLevel=-14
# number of backup files to keep;
# older files if number of files > Keep
Keep=20

Scriptname=`basename "$0"`
echo "Scriptname: "$Scriptname
echo

# 1 use hostname to set path to backup files
laptop=dev_pc
HostMixedCase=$(hostname)
# convert to lowercase
echo "Running on hostname: "$HostMixedCase
HostLowerCase="$(echo ${HostMixedCase} | awk '{print tolower($0)}')"
echo "Running on hostname: "$HostLowerCase
ShortHostname=`hostname -s`
ShortHostLowerCase="$(echo ${ShortHostname} | awk '{print tolower($0)}')"
echo "ShortHostLowerCase: "$ShortHostLowerCase

# 2 edit the source and destination path variables
# for both the local development pc and live production server
if [ $HostLowerCase = $laptop ]; then
    # laptop local dev system
    echo "Host is laptop local dev system"
    SrcFolderBase=/c/Users/dev_pc/code/data/www/
    DstFolderBase=/c/Users/dev_pc/backup/
    DevilboxFolder=/c/Users/dev_pc/code/devilbox/
else
    # live production server
    echo "Host is live production server"
    SrcFolderBase=/var/www/
    DstFolderBase=/var/www/bak/
fi

echo "SrcFolderBase: ${SrcFolderBase}"
echo "DstFolderBase: ${DstFolderBase}"


# get command line options / arguments
# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
WebsiteName=""
DatabaseName=""
local=0
Error=0

function show_help {
        echo Usage: bkup-website.sh -h -l -w WebsiteName -d DatabaseName
}

while getopts ":hlw:d:" opt; do
    #echo "Opt is: $opt"
    #echo "Optarg is: $OPTARG"
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    l)  local=1
        ;;
    w)  WebsiteName=$OPTARG
	#echo "-w was triggered, Parameter: $OPTARG" >&2
        ;;
    d)  DatabaseName=$OPTARG
	#echo "-d was triggered, Parameter: $OPTARG" >&2
        ;;
    \?)
        echo "Invalid option -$OPTARG" >&2
        Error=1
        ;;
    :)
        echo "Option -$OPTARG requires an argument." >&2
        Error=1
        ;;
    esac
done

if [ -z $WebsiteName ]; then
        echo "Error: you must specify a website name!"
        Error=1
fi

if [ -z $DatabaseName ]; then
        echo "Error: you must specify a database name!"
        Error=1
fi

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

if [ $Error -eq 1 ]; then
	echo "Error value: ${Error}"
	show_help
	echo "Terminating execution"
        exit 1
fi

echo "Cmd Line Options: "
echo "local=$local, WebsiteName='$WebsiteName', DatabaseName='$DatabaseName' Leftovers: $@"

# setup environment variables
# src folder contains the website files
SrcFolder=$SrcFolderBase$WebsiteName
SrcFolderSql=/shared/httpd/$WebsiteName
DstFolder=$DstFolderBase$WebsiteName/gz

# if destination folder does not exist, create it
if [ ! -d "$DstFolder" ]; then
    mkdir -p $DstFolder
fi

# Format:$StartTimeStamp YEAR MONTH DAY - HOUR MINUTE SECOND
StartTime=$(date +%s)
StartTimeStamp=$(date +%Y-%m-%d_%H.%M.%S)

# where to write the .sql database dump file
SqlFilePathName="$SrcFolderSql/dump_${WebsiteName}_${ShortHostLowerCase}_$DatabaseName.sql"

# where to write the tar file
TarFilePathName="$DstFolder/${WebsiteName}_${ShortHostLowerCase}_${StartTimeStamp}.tar.gz"

#"Echoing environment variables"
echo "WebsiteName: ${WebsiteName}"
echo
echo "Databasename: ${DatabaseName}"
echo "SrcFolder: ${SrcFolder}"
echo "DstFolder: ${DstFolder}"
echo "SqlFilePathName: ${SqlFilePathName}"
echo "TarFilePathName: ${TarFilePathName}"
echo
echo "Start Timestamp: ${StartTimeStamp}"
echo

# 2 mysqldump command
#echo "dumping mysql data to file $SqlFilePathName ..."
#mysqldump --add-drop-table $DatabaseName >$SqlFilePathName
#echo
CMD="docker exec -u root devilbox_php_1 /usr/bin/mysqldump -h mysql --result-file=${SqlFilePathName} --add-drop-table ${DatabaseName}"
#CMD="docker exec devilbox_php_1 --user root nice -14 /usr/bin/mysqldump -h mysql --result-file=${SqlFilePathName} --add-drop-table ${DatabaseName}"
echo RUNNING: ${CMD}
`${CMD}`
echo 

echo $(date +%Y-%m-%d_%H.%M.%S)
echo
echo SQL Dump File listing:
CMD="docker exec -it devilbox_php_1 /bin/ls -lh ${SqlFilePathName}"
echo RUNNING: ${CMD}
`${CMD}`
CMD="docker exec -it devilbox_php_1 /bin/ls -l ${SqlFilePathName}"
echo RUNNING: ${CMD}
`${CMD}`
echo

# give the OS time to finish writing data to the disk
echo "Waiting 1 seconds for OS to finish writing data to the disk"
sleep 1s
echo $(date +%Y-%m-%d_%H.%M.%S)
echo

# 3 create tar archive
#echo Writing tar archive file to TarFilePathName: $TarFilePathName
#tar -czf $TarFilePathName $SrcFolder
if [ $HostLowerCase = $laptop ]; then
    CMD="nice ${NiceLevel} /bin/tar -czf $TarFilePathName $SrcFolder $DevilboxFolder.env $DevilboxFolder/cfg/php-ini-7.2/*.ini"
else
    CMD="nice ${NiceLevel} /bin/tar -czf $TarFilePathName $SrcFolder"
fi
echo RUNNING: ${CMD}
`${CMD}`
echo 

echo $(date +%Y-%m-%d_%H.%M.%S)
echo
echo Tar Archive file listing:
ls -lh $TarFilePathName
ls -l $TarFilePathName
echo 

# if backup failed to create a file, do NOT purge older files!!!!
if [ -f $TarFilePathName ]; then
    echo "Deleting the following files, retaining the most recent 20 files"
	echo
    ls -1 $DstFolder/$WebsiteName*.gz | head -n -${Keep}
    ls -1 $DstFolder/$WebsiteName*.gz | head -n -${Keep} | xargs rm
	echo
    echo "File delete completed"
fi

# copy sql dump file to backup share
#rsync -avz $SqlFilePathName $DstFolderDumps/

# delete local sql file dump to save disk space
#rm $SqlFilePathName

#echo "Waiting 1 seconds for OS to finish writing data to the disk"
#sleep 1s

EndTimeStamp=$(date +%Y-%m-%d_%H.%M.%S)
EndTime=$(date +%s)
echo "EndTimeStamp: ${EndTimeStamp}"
echo
echo "Elapsed time: $((${EndTime} - ${StartTime})) seconds"
echo "Elapsed time: $(((${EndTime} - ${StartTime})/60)) minutes"
echo

