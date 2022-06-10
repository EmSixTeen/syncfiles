# Syncfiles - Easy rsync

## Features:
- Loads a syncfiles.zsh file from the current folder, which sets some
  variables that are specific for that site, eg:
    - user (cPanel username)
    - host (domain name)
    - the remote base directory (eg `public_html/`)
    - the theme slug (eg `themename`)
    - the rsync arguments (eg `-avzP`)
    - excluded files and folders (preprocessor files, backup files, etc.)
- Optional arguments/flags:
  - Do a dry run
      - `-d` | `--dry` | `--dryrun` | `--dry-run`  
      - Dry-run is more critical than syncing downwards, so gets the -d 
  - Specify a specific pattern
      - `-o=*` | `--only=*`
      - Wildcards need escaped
      - ⚠️ Empty folders will downloaded. Not figured out how to avoid that.
      - Example usage: 
          - `syncfiles --down --only=\*.php`
          - `syncfiles --down --only=navigation.js`
  - Specify that you want to sync downwards
      - `--down` | `--pull`
      - For when files are on the server and you don't have them locally.
  - Specify that you want to sync upwards
      - `--up` | `--push`    
      - This is the default behaviour
  - Include the `/acf-json/` folder
      - `--inc-acf`  
  - Override the main arguments
      - `-a=*` | `--args=*`
      - https://devhints.io/rsync
  - Specify the SSH port
      - `-p=*` | `--port=*`
      - Rarely non-default, always port 22 on ProISP
  - Sync the uploads folder
      - `--uploads`
      - Changes to uploads folder and syncs it in the direction chosen.
  - Sync the plugins folder
      - `--plugins`
      - Changes to plugins folder and syncs it in the direction chosen.
  - Debug
      - `--debug`
      - Echo the full string just so we can check it, nothing fancy.

## Goals:
- Pull down plugins
- Pull down uploads
- Delete twenty-x themes, hello dolly, and akismet
- Automatically set wp environment to production?