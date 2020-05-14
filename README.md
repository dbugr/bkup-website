# bkup-website
Create website backup files. Bash script. WSL, Docker, Wordpress, Drupal

# Handy script to backup Wordpress or Drupal website
# database and files.
# Assume database is in Devilbox Docker containers.
# http://devilbox.org/
# Assume running this script from 
# WSL Ubuntu 20.04 Bash command line

# Author: Chuckster
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

