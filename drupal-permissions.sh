#!/bin/bash

##
# Based from script found at: https://drupal.org/node/244924
#
# See README or code below for usage
##

# Is this really necessary?
if [ $(id -u) != 0 ]; then
  printf "This script must be run as root.\n"
  exit 1
fi

# Set (default) script arguments.
drupal_path=${1%/}
drupal_user=${2}
httpd_group=${3}

if [ -z "${httpd_group}" ]; then
	httpd_group=www-data
fi

# Help menu.
print_help() {
cat <<-HELP

This script is used to fix permissions of a Drupal installation
you need to provide the following arguments:

1) Path to your Drupal installation.
2) Username of the user that you want to give files/directories ownership.
3) HTTPD group name (defaults to www-data for Apache).

Usage: (sudo) bash ${0##*/} --drupal_path=PATH --drupal_user=USER --httpd_group=GROUP

Example: (sudo) bash ${0##*/} --drupal_path=/usr/local/apache2/htdocs --drupal_user=john --httpd_group=www-data

HELP
exit 0
}

# Parse command line arguments.
while [ $# -gt 0 ]; do
  case "$1" in
    --drupal_path=*) 
      drupal_path="${1#*=}"
      ;;
    --drupal_user=*)
      drupal_user="${1#*=}"
      ;;
    --httpd_group=*)
      httpd_group="${1#*=}"
      ;;
    --help) print_help;;
    *)
      printf "Invalid argument, run --help for valid arguments.\n";
      exit 1
  esac
  shift
done

# Basic check to see if this is a valid Drupal install.
if [ -z "${drupal_path}" ] || [ ! -d "${drupal_path}/sites" ] || [ ! -f "${drupal_path}/modules/system/system.module" ]; then
  printf "Please provide a valid Drupal path.\n"
  print_help
  exit 1
fi

# Basic check to see if a valid user is provided.
if [ -z "${drupal_user}" ] || [ $(id -un ${drupal_user} 2> /dev/null) != "${drupal_user}" ]; then
  printf "Please provide a valid user.\n"
  print_help
  exit 1
fi

cd $drupal_path
printf "Changing ownership of all contents in ${drupal_path} to\n"
printf "\tuser:  ${drupal_user}\n"
printf "\tgroup: ${httpd_group}\n"

chown -R ${drupal_user}:${httpd_group} .

printf "Changing permissions...\n"
printf "rwxr-x--- on all directories inside ${drupal_path}\n"
find . -type d -exec chmod u=rwx,g=rx,o= '{}' \;

printf "rw-r----- on all files       inside ${drupal_path}\n"
find . -type f -exec chmod u=rw,g=r,o= '{}' \;

printf "rwx------ on all files       inside ${drupal_path}/scripts\n"
cd ${drupal_path}/scripts
find . -type f -exec chmod u=rwx,g=,o= '{}' \;

printf "rwxrwx--- on \"files\" directories in ${drupal_path}/sites\n"
cd ${drupal_path}/sites
find . -type d -name files -exec chmod ug=rwx,o= '{}' \;

printf "rw-rw---- on all files       inside all /files directories in ${drupal_path}/sites,\n"
printf "rwxrwx--- on all directories inside all /files directories in ${drupal_path}/sites:\n"
for x in ./*/files; do
  printf "\tChanging permissions in ${drupal_path}/sites/${x}\n"
  find ${x} -type d -exec chmod ug=rwx,o= '{}' \;
  find ${x} -type f -exec chmod ug=rw,o= '{}' \;
done

cd ${drupal_path}
if [ -d ".git" ]; then
	printf "rwx------ on .git/ directories and files in ${drupal_path}/.git\n"
	cd ${drupal_path}
	chmod -R u=rwx,go= .git
	chmod u=rwx,go= .gitignore
fi

printf "rwx------ on various Drupal text files in   ${drupal_path}\n"
cd ${drupal_path}
chmod u=rwx,go= CHANGELOG.txt
chmod u=rwx,go= COPYRIGHT.txt
chmod u=rwx,go= INSTALL.mysql.txt
chmod u=rwx,go= INSTALL.pgsql.txt
chmod u=rwx,go= INSTALL.txt
chmod u=rwx,go= LICENSE.txt
chmod u=rwx,go= MAINTAINERS.txt
chmod u=rwx,go= UPGRADE.txt


# Boost module permissions as recommended in https://www.drupal.org/node/1459690.
cd ${drupal_path}
if [ -d "cache" ]; then
	printf "rwxrwxr-x on Boost module cache directory   ${drupal_path}\n"
	cd ${drupal_path}/cache
	for x in ./*
	do
		 find ${x} -type d -exec chmod ug=rwx,o= '{}' \;
		 find ${x} -type f -exec chmod ug=rw,o= '{}' \;
	done
fi

echo "Done setting proper permissions on files and directories."
