#!/bin/zsh

# Emulate zsh
# ==========
# Putting emulate -LR zsh near the beginning of a function definition is good 
# hygiene when the function is meant to be used in contexts where options are 
# potentially different, especially in interactive shells.
# ( https://unix.stackexchange.com/a/372866 )
emulate -LR zsh

# Remote settings
# ==========
remoteUser='yourcpanelusername' # cPanel username
remoteHost='yourdomain.tld' # Domain or IP

# Directory settings
# - Where is the WordPress installation? If it's on the root, chances are it's
#   in 'public_html/'
baseDirectory='public_html/' # Do include trailing slash
themeSlug='tangarholen' # Don't include the trailing slash

# remoteThemeDirectory='public_html/wp-content/themes/tangarholen/' # Include trailing slash!

# Rsync settings
# ==========
# Main arguments
# https://devhints.io/rsync
rsyncArgs='avzP'

# Deleting files on the destination side
# --delete: 
#   If you remove/delete files in the source directory you're transferring 
#   from, then those files will also be deleted on the destination 
#   directory. Be careful with this one!
# --delete-excluded:
#   Deletes files from the destination directory that are explicitly excluded 
#   from transferring from the source directory. So, if you've accidentally
#   uploaded .scss files for example, if those are in the rsyncExcludes list
#   then those will be deleted from the destination directory
rsyncDownDelete=''
rsyncUpDelete='--delete --delete-excluded'

# Specify the SSH port
# - Rarely non-default, always port 22 on ProISP
# rsyncPort='22' 

# Excluded files and folders
# ==========
# - Escape the wildcard asterisk
# - The /acf-json/ folder is excluded by default when syncing upwards, and is
#   included by default when syncing downwards. 
#   To override, use either:
#   --inc-acf
#   --exc-acf
rsyncExcludes=(
    ".DS_Store"
    ".\*lintrc\*"
    "._\*"
    ".git/"
    ".vscode/"
    "LICENSE"
    "Thumbs.db"
    "\*.ai"
    "\*.bak"
    "\*.config"
    "\*.dist"
    "\*.gitignore"
    "\*.indd"
    "\*.keep"
    "\*.md"
    "\*.psd"
    "\*.sh"
    "\*.wpress"
    "\*.zsh"
    "composer.json"
    "node_modules/"
    "package-lock.json"
    "package.json"
    "phpcs.\*"
    "report/"
    "template-parts/"
)
