# Drupal Permissions

A bash script to help set Drupal permission correctly.  Please do not use blindly, read the code first.  Based from script found on [Drupal.org](https://drupal.org/node/244924).

This script is used to fix permissions of a Drupal installation you need to provide the following arguments:
  
1. Path to your Drupal installation.
2. Username of the user that you want to give files/directories ownership.
3. HTTPD group name (defaults to www-data for Apache).

Usage:
    
		(sudo) bash ${0##*/} DRUPAL_PATH DRUPAL_USER [HTTPD_GROUP]

Examples: 

		(sudo) bash ${0##*/} . john
		(sudo) bash ${0##*/} . john www-data
