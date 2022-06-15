# # Syncfiles - Easy rsync
# Easily rsync WordPress theme files up and down from your local machine to your
# remote server, using a function named `syncfiles`.

# ## Features
# - Loads a `syncfiles.zsh` file from the current folder, which sets some
#   variables that are specific for that site, eg:
#     - user (cPanel username)
#     - host (domain name)
#     - the remote base directory (eg `public_html/`)
#     - the theme slug (eg `themename`)
#     - the rsync arguments (eg `-avzP`)
#     - excluded files and folders (preprocessor files, backup files, etc.)
# - Optional arguments/flags:
#   - Do a dry run
#       - `-d` | `--dry` | `--dryrun` | `--dry-run`  
#       - Dry-run is more critical than syncing downwards, so gets the -d 
#   - Specify a specific pattern
#       - `-o=*` | `--only=*`
#       - Wildcards need escaped
#       - ⚠️ Empty folders will downloaded. Not figured out how to avoid that.
#       - Example usage: 
#           - `syncfiles --down --only=\*.php`
#           - `syncfiles --down --only=navigation.js`
#   - Specify that you want to sync downwards
#       - `--down` | `--pull`
#       - For when files are on the server and you don't have them locally.
#   - Specify that you want to sync upwards
#       - `--up` | `--push`    
#       - This is the default behaviour
#   - Include the `/acf-json/` folder
#       - `--inc-acf`  
#   - Override the main arguments
#       - `-a=*` | `--args=*`
#       - https://devhints.io/rsync
#   - Specify the SSH port
#       - `-p=*` | `--port=*`
#       - Rarely non-default, always port 22 on ProISP
#   - Sync the WordPress uploads folder
#       - `--uploads`
#       - Changes to uploads folder and syncs it in the direction chosen.
#   - Sync the WordPress plugins folder
#       - `--plugins`
#       - Changes to plugins folder and syncs it in the direction chosen.
#   - Debug
#       - `--debug`
#       - Echo the full string just so we can check it, nothing fancy.
# ## Requirements
# You must have authorised your SSH key on the remote machine.
# ## Goals
# - Delete twenty-x themes, hello dolly, and akismet
# - Automatically set wp environment to production?
#
# ## Reference:
# - http://www.gnu.org/software/bash/manual/bashref.html#Single-Quotes
function syncfiles() {
    echo ""

    # Todo: Set the filename here, re-use in the if statement and elsewhere
    # configFile='syncfiles.zsh'

    # Set up colours
    local Black='\033[0;30m'        # Black
    local Red='\033[0;31m'          # Red
    local Green='\033[0;32m'        # Green
    local Yellow='\033[0;33m'       # Yellow
    local Blue='\033[0;34m'         # Blue
    local Purple='\033[0;35m'       # Purple
    local Cyan='\033[0;36m'         # Cyan
    local White='\033[0;37m'        # White
    local NC='\033[0m'              # No Color

    local arrow="${Cyan}->${NC}"
    local arrowError="${Red}->${NC}"
    local arrowSuccess="${Green}->${NC}"
    
    if [[ -f syncfiles.zsh ]]
    then
        echo "$arrowSuccess syncfiles.zsh exists in current directory"
        
        # Set the source file where our variables are set
        source 'syncfiles.zsh'
        
        # Check the variables exist and aren't empty
        if [[
                ! -z "$remoteUser" &&
                ! -z "$remoteHost" &&
                ! -z "$baseDirectory" &&
                ! -z "$themeSlug" &&
                ! -z "$rsyncArgs" &&
                ! -z "$rsyncExcludes"
        ]]
        then
            echo "$arrowSuccess Variables are populated" # 'Populated' - we don't know if they're valid
            
            local rsyncDryRun=false
            local rsyncDirection="up"
            local includeAcfJson=false

            # Check if the baseDirectory variable ends in a trailing slash
            # str="this/is/my/string"
            case "$baseDirectory" in
            */)
                echo "$arrowSuccess baseDirectory ends in a trailing slash"
                ;;
            *)
                echo "$arrowError ${Red}Error:${NC} baseDirectory needs to end in a trailing slash. Setting rsync to --dry-run as a precaution."
                rsyncDryRun=true
                ;;
            esac

            # Set an empty excludes string, then loop through the rsyncExcludes variable set
            # in syncfiles.zsh, and spit out an "--exclude=foo" for each entry. 
            # - Yes, you can use bracket expansion here, but for simplicity's sake in the 
            #   config file we're not.
            local excludeString=""
            for excludeItem in "${rsyncExcludes[@]}"; do
                excludeString+="--exclude=${excludeItem} "
            done
            
            # Set the SSH port
            # ! If you set the wrong rsync port, you'll need to exit the process yourself, it
            #   won't timeout on its own. Press ctrl+C to exit. 
            # - This is just a fallback.
            if [[ -z "$rsyncPort" ]]
            then
                local rsyncPort='22'
            fi

            # Start putting together the rsync string
            local rsyncFullString="rsync "

            # Set up command line flag options
            # ! These option arguments ONLY accept space arguments, not spaces.
            # - Adapted from https://stackoverflow.com/a/63653944/493159
            # 
            # Todo:
            # - Pull down plugins
            # - Pull down uploads
            # - Delete twenty-x themes, hello dolly, and akismet
            while [ $# -gt 0 ]; do
                case "$1" in
                    -d | --dry | --dryrun | --dry-run ) # Do a dry run
                        rsyncDryRun=true
                        ;;
                    -o=* | --only=* ) # Specify a specific pattern
                        local rsyncSpecific=true
                        excludeString='--include=\*/ --include=\'
                        excludeString+="${1#*=} "
                        excludeString+="--exclude=\* "
                        ;;
                    --down | --pull )   # Specify that you want to sync downwards
                        rsyncDirection="down"
                        ;;
                    --up | --push )     # Specify that you want to sync upwards
                        rsyncDirection="up"
                        ;;
                    --inc-acf )         # Include the /acf-json/ folder
                        includeAcfJson=true
                        ;;
                    -a=* | --args=* )   # Override the arguments
                        rsyncArgs="${1#*=}"
                        ;;
                    -p=* | --port=* )   # Override the SSH port
                        rsyncPort="${1#*=}"
                        ;;
                    --uploads )         # Sync the uploads folder
                        local uploads=true
                        excludeString=''
                        ;;
                    --plugins )         # Sync the plugins folder
                        local plugins=true
                        excludeString=''
                        ;;
                    --debug )           # Echo the string rather than doing it
                        local debug=true
                        ;;
                    -o | -a | -p )
                        printf "$arrowError ${Red}Error:${NC} An option that takes arguments is missing them\n"
                        ;;
                    * )
                        printf "$arrowError ${Red}Error:${NC} Unknown option: $1\n"
                        #exit 1
                esac
                shift
            done
            
            # Build the remote directory string
            local remoteDirectory="$baseDirectory"
            if [[ $uploads == true && $plugins == true ]]; then
                echo "$arrowError ${Red}Error:${NC} Sorry, you can't do --uploads and --plugins at the same time. Setting rsync to --dry-run as a precaution."
                rsyncDryRun=true
            
            elif [[ $uploads == true && -z $plugins || $uploads == true && $plugins == false ]]; then
                # Check to make sure we're a directory structure ending in /themes/themeslug
                if [[ "$PWD" = */themes/$themeSlug ]]; then
                    cd ../../uploads/
                    local changedDirectory=true
                fi
                remoteDirectory+="wp-content/uploads/"
                echo ""
                echo "Changed directory to: $PWD"
                echo "Remote dir (uploads): $remoteDirectory"
            
            elif [[ $plugins == true && -z $uploads || $plugins == true && $uploads == false ]]; then
                # Check to make sure we're a directory structure ending in /themes/themeslug
                if [[ "$PWD" = */themes/$themeSlug ]]; then
                    cd ../../plugins/
                    local changedDirectory=true
                fi
                remoteDirectory+="wp-content/plugins/"
                echo ""
                echo "Changed directory to: $PWD"
                echo "Remote dir (plugins): $remoteDirectory"            
            else
                remoteDirectory+="wp-content/themes/"
                remoteDirectory+="$themeSlug"
                remoteDirectory+="/"
                echo ""
                echo "Remote dir (theme):   $remoteDirectory"
            fi

            # Append the --dry-run flag to the string if requested
            if [[ $rsyncDryRun == true ]]; then
                rsyncFullString+="--dry-run "
            fi

            echo ""
            echo "Remote user:          $remoteUser"
            echo "Remote host:          $remoteHost"
            echo ""
            echo "Base directory:       $baseDirectory"
            echo "Theme slug:           $themeSlug"
            echo ""
            echo "rsync direction:      $rsyncDirection"
            echo "rsync dry-run:        $rsyncDryRun"
            echo "rsync arguments:      $rsyncArgs"
            echo "rsync port:           $rsyncPort"

            # If the --only flag has been passed, only need to echo that, else echo all excludes
            if [[ $rsyncSpecific == true ]]; then
                echo "rsync exclude string: $excludeString"
            else
                echo "rsync excludes:       ${rsyncExcludes//\\/}"  # https://stackoverflow.com/a/15249179
            fi
            echo ""

            # Append the main arguments to the rsync command
            rsyncFullString+="-$rsyncArgs -e 'ssh -p $rsyncPort' "

            # Check if the --inc-acf flag has been passed and append to the excludes string
            if [[ $includeAcfJson == true ]]; then
                excludeString+="--include=acf-json/\*.json "
            elif [[ $includeAcfJson == false || -z $includeAcfJson ]]; then
                excludeString+="--exclude=acf-json/ "
            fi 

            # Append our excludes to the rsync command
            rsyncFullString+="$excludeString"

            # Build the string to do the transfer in the direction we want
            # - Also includes the rsyncUpDelete/rsyncDownDelete setting
            if [[ $rsyncDirection == "down" ]]; then
                rsyncFullString+="$rsyncDownDelete $remoteUser@$remoteHost:$remoteDirectory ."
            elif [[ $rsyncDirection == "up" || -z $rsyncDirection ]]; then
                rsyncFullString+="$rsyncUpDelete . $remoteUser@$remoteHost:$remoteDirectory"
            fi 

            # Check for the --debug flag
            if [[ $debug == true ]]; then
                # Echo the full string just so we can check it, nothing fancy
                echo "The whole thing:      $rsyncFullString"
                echo ""
            else
                eval $rsyncFullString
            fi

            # If we changed the directory by passing --uploads or --plugins, change back
            if [[ $changedDirectory == true ]]; then
                # Return to the last folder we were in before the previous cd
                # cd - # This can work but it prints it out, we'll do that ourselves
                cd $OLDPWD  
                echo ""
                echo "Changed directory to: $PWD"
            fi
            
        else
            echo "$arrowError ${Red}Error:${NC} Check that all variables are set"
        fi
    else
        echo "$arrowError ${Red}Error:${NC} There is no syncfiles.zsh config file present in the current directory"
    fi
    
    echo ""
}

