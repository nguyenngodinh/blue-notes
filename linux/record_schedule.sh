#!/usr/bin/env bash

# A best practices Bash script template with many useful functions. This file
# combines the source.sh & script.sh files into a single script. If you want
# your script to be entirely self-contained then this should be what you want!

# A better class of script...
set -o errexit          # Exit on most errors (see the manual)
set -o errtrace         # Make sure any error trap is inherited
set -o nounset          # Disallow expansion of unset variables
set -o pipefail         # Use last non-zero exit code in a pipeline
#set -o xtrace          # Trace the execution of the script (debug)

# DESC: Handler for unexpected errors
# ARGS: $1 (optional): Exit code (defaults to 1)
# OUTS: None
function script_trap_err() {
    local exit_code=1

    # Disable the error trap handler to prevent potential recursion
    trap - ERR

    # Consider any further errors non-fatal to ensure we run to completion
    set +o errexit
    set +o pipefail

    # Validate any provided exit code
    if [[ ${1-} =~ ^[0-9]+$ ]]; then
        exit_code="$1"
    fi

    # Output debug data if in Cron mode
    if [[ -n ${cron-} ]]; then
        # Restore original file output descriptors
        if [[ -n ${script_output-} ]]; then
            exec 1>&3 2>&4
        fi

        # Print basic debugging information
        printf '%b\n' "$ta_none"
        printf '***** Abnormal termination of script *****\n'
        printf 'Script Path:            %s\n' "$script_path"
        printf 'Script Parameters:      %s\n' "$script_params"
        printf 'Script Exit Code:       %s\n' "$exit_code"

        # Print the script log if we have it. It's possible we may not if we
        # failed before we even called cron_init(). This can happen if bad
        # parameters were passed to the script so we bailed out very early.
        if [[ -n ${script_output-} ]]; then
            printf 'Script Output:\n\n%s' "$(cat "$script_output")"
        else
            printf 'Script Output:          None (failed before log init)\n'
        fi
    fi

    # Exit with failure status
    exit "$exit_code"
}


# DESC: Handler for exiting the script
# ARGS: None
# OUTS: None
function script_trap_exit() {
    cd "$orig_cwd"

    # Remove Cron mode script log
    if [[ -n ${cron-} && -f ${script_output-} ]]; then
        rm "$script_output"
    fi

    # Remove script execution lock
    if [[ -d ${script_lock-} ]]; then
        rmdir "$script_lock"
    fi

    # Restore terminal colours
    printf '%b' "$ta_none"
}


# DESC: Exit script with the given message
# ARGS: $1 (required): Message to print on exit
#       $2 (optional): Exit code (defaults to 0)
# OUTS: None
function script_exit() {
    if [[ $# -eq 1 ]]; then
        printf '%s\n' "$1"
        exit 0
    fi

    if [[ ${2-} =~ ^[0-9]+$ ]]; then
        printf '%b\n' "$1"
        # If we've been provided a non-zero exit code run the error trap
        if [[ $2 -ne 0 ]]; then
            script_trap_err "$2"
        else
            exit 0
        fi
    fi

    script_exit 'Missing required argument to script_exit()!' 2
}


# DESC: Generic script initialisation
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: $orig_cwd: The current working directory when the script was run
#       $script_path: The full path to the script
#       $script_dir: The directory path of the script
#       $script_name: The file name of the script
#       $script_params: The original parameters provided to the script
#       $ta_none: The ANSI control code to reset all text attributes
# NOTE: $script_path only contains the path that was used to call the script
#       and will not resolve any symlinks which may be present in the path.
#       You can use a tool like realpath to obtain the "true" path. The same
#       caveat applies to both the $script_dir and $script_name variables.
function script_init() {
    # Useful paths
    readonly orig_cwd="$PWD"
    readonly script_path="${BASH_SOURCE[0]}"
    readonly script_dir="$(dirname "$script_path")"
    readonly script_name="$(basename "$script_path")"
    readonly script_params="$*"

    # Important to always set as we use it in the exit handler
    readonly ta_none="$(tput sgr0 2> /dev/null || true)"
}


# DESC: Initialise colour variables
# ARGS: None
# OUTS: Read-only variables with ANSI control codes
# NOTE: If --no-colour was set the variables will be empty
function colour_init() {
    if [[ -z ${no_colour-} ]]; then
        # Text attributes
        readonly ta_bold="$(tput bold 2> /dev/null || true)"
        printf '%b' "$ta_none"
        readonly ta_uscore="$(tput smul 2> /dev/null || true)"
        printf '%b' "$ta_none"
        readonly ta_blink="$(tput blink 2> /dev/null || true)"
        printf '%b' "$ta_none"
        readonly ta_reverse="$(tput rev 2> /dev/null || true)"
        printf '%b' "$ta_none"
        readonly ta_conceal="$(tput invis 2> /dev/null || true)"
        printf '%b' "$ta_none"

        # Foreground codes
        readonly fg_black="$(tput setaf 0 2> /dev/null || true)"
        printf '%b' "$ta_none"
        readonly fg_blue="$(tput setaf 4 2> /dev/null || true)"
        printf '%b' "$ta_none"
        readonly fg_cyan="$(tput setaf 6 2> /dev/null || true)"
        printf '%b' "$ta_none"
        readonly fg_green="$(tput setaf 2 2> /dev/null || true)"
        printf '%b' "$ta_none"
        readonly fg_magenta="$(tput setaf 5 2> /dev/null || true)"
        printf '%b' "$ta_none"
        readonly fg_red="$(tput setaf 1 2> /dev/null || true)"
        printf '%b' "$ta_none"
        readonly fg_white="$(tput setaf 7 2> /dev/null || true)"
        printf '%b' "$ta_none"
        readonly fg_yellow="$(tput setaf 3 2> /dev/null || true)"
        printf '%b' "$ta_none"

        # Background codes
        readonly bg_black="$(tput setab 0 2> /dev/null || true)"
        printf '%b' "$ta_none"
        readonly bg_blue="$(tput setab 4 2> /dev/null || true)"
        printf '%b' "$ta_none"
        readonly bg_cyan="$(tput setab 6 2> /dev/null || true)"
        printf '%b' "$ta_none"
        readonly bg_green="$(tput setab 2 2> /dev/null || true)"
        printf '%b' "$ta_none"
        readonly bg_magenta="$(tput setab 5 2> /dev/null || true)"
        printf '%b' "$ta_none"
        readonly bg_red="$(tput setab 1 2> /dev/null || true)"
        printf '%b' "$ta_none"
        readonly bg_white="$(tput setab 7 2> /dev/null || true)"
        printf '%b' "$ta_none"
        readonly bg_yellow="$(tput setab 3 2> /dev/null || true)"
        printf '%b' "$ta_none"
    else
        # Text attributes
        readonly ta_bold=''
        readonly ta_uscore=''
        readonly ta_blink=''
        readonly ta_reverse=''
        readonly ta_conceal=''

        # Foreground codes
        readonly fg_black=''
        readonly fg_blue=''
        readonly fg_cyan=''
        readonly fg_green=''
        readonly fg_magenta=''
        readonly fg_red=''
        readonly fg_white=''
        readonly fg_yellow=''

        # Background codes
        readonly bg_black=''
        readonly bg_blue=''
        readonly bg_cyan=''
        readonly bg_green=''
        readonly bg_magenta=''
        readonly bg_red=''
        readonly bg_white=''
        readonly bg_yellow=''
    fi
}


# DESC: Initialise silent mode
# ARGS: None
# OUTS: $script_output: Path to the file stdout & stderr was redirected to
function silent_init() {
    if [[ -n ${cron-} ]]; then
        # Redirect all output to a temporary file
        readonly script_output="$(mktemp --tmpdir "$script_name".XXXXX)"
        exec 3>&1 4>&2 1>"$script_output" 2>&1
    fi
}


# DESC: Acquire script lock
# ARGS: $1 (optional): Scope of script execution lock (system or user)
# OUTS: $script_lock: Path to the directory indicating we have the script lock
# NOTE: This lock implementation is extremely simple but should be reliable
#       across all platforms. It does *not* support locking a script with
#       symlinks or multiple hardlinks as there's no portable way of doing so.
#       If the lock was acquired it's automatically released on script exit.
function lock_init() {
    local lock_dir
    if [[ $1 = 'system' ]]; then
        lock_dir="/tmp/$script_name.lock"
    elif [[ $1 = 'user' ]]; then
        lock_dir="/tmp/$script_name.$UID.lock"
    else
        script_exit 'Missing or invalid argument to lock_init()!' 2
    fi

    if mkdir "$lock_dir" 2> /dev/null; then
        readonly script_lock="$lock_dir"
        verbose_print "Acquired script lock: $script_lock"
    else
        script_exit "Unable to acquire script lock: $lock_dir" 2
    fi
}


#DESC: active configuration value
#ARGS: None
#OUTS: configuration value of database name, user, port, tables
function config_init() {
	if [ -f "$orig_cwd/.configrs" ]; then
		source "$orig_cwd/.configrs"
	else
		pretty_print "It is a lovely day!"
		pretty_print "Create a configuration file $orig_cwd/.configrs"
		touch "$orig_cwd/configrs"
	fi
	
	if [ -z "$(grep RECORD_DB_HOST $orig_cwd/.configrs)" ]
	then
		echo 'export RECORD_DB_HOST='127.0.0.1'' >> "$orig_cwd/.configrs"
		export RECORD_DB_HOST='127.0.0.1'
	fi

	if [ -z "$(grep RECORD_DB_NAME $orig_cwd/.configrs)" ]
	then
		echo 'export RECORD_DB_NAME='replay_database'' >> "$orig_cwd/.configrs"
		export RECORD_DB_NAME='replay_database'
	fi

	if [ -z "$(grep RECORD_DB_USER $orig_cwd/.configrs)" ] 
	then
		echo 'export RECORD_DB_USER='postgres'' >> "$orig_cwd/.configrs"
		export RECORD_DB_USER='postgres'
	fi
	
	if [ -z "$(grep RECORD_DB_PORT $orig_cwd/.configrs)" ] 
	then
		echo 'export RECORD_DB_PORT=5869' >> "$orig_cwd/.configrs"
		export RECORD_DB_PORT=5869
	fi

	if [ -z "$(grep RECORD_LIFE_CYCLE $orig_cwd/.configrs)" ] 
	then
		echo 'export RECORD_LIFE_CYCLE='data_record.object_lifecycle'' >> "$orig_cwd/.configrs"
		export RECORD_LIFE_CYCLE='data_record.object_lifecycle'
	fi

	if [ -z "$(grep RECORD_OBJECT_EVENT $orig_cwd/.configrs)" ] 
	then
		echo 'export RECORD_OBJECT_EVENT='data_record.object_event'' >> "$orig_cwd/.configrs"
		export RECORD_OBJECT_EVENT='data_record.object_event'
	fi

	if [ -z "$(grep RECORD_EXP_TIME $orig_cwd/.configrs)" ] 
	then
		echo 'export RECORD_EXP_TIME=30' >> "$orig_cwd/.configrs"
		export RECORD_EXP_TIME=30
	fi

	if [ -z "$(grep RECORD_CRONTAB $orig_cwd/.configrs)" ] 
	then
		echo "export RECORD_CRONTAB=/var/spool/cron/crontabs/$USER" >> "$orig_cwd/.configrs"
		export RECORD_CRONTAB="/var/spool/cron/crontabs/$USER"
	fi

	if [ -z "$(grep RECORD_ROOT_PASS $orig_cwd/.configrs)" ] 
	then
		echo 'export RECORD_ROOT_PASS=1' >> "$orig_cwd/.configrs"
		export RECORD_ROOT_PASS=1
	fi
}

function show_config(){
	pretty_print "$RECORD_DB_HOST"
	pretty_print "$RECORD_DB_NAME"
	pretty_print "$RECORD_DB_USER"
	pretty_print "$RECORD_DB_PORT"
	pretty_print "$RECORD_LIFE_CYCLE"
	pretty_print "$RECORD_OBJECT_EVENT"
	pretty_print "$RECORD_EXP_TIME"
	pretty_print "$RECORD_CRONTAB"
	pretty_print "$RECORD_ROOT_PASS"
}

# DESC: Pretty print the provided string
# ARGS: $1 (required): Message to print (defaults to a green foreground)
#       $2 (optional): Colour to print the message with. This can be an ANSI
#                      escape code or one of the prepopulated colour variables.
#       $3 (optional): Set to any value to not append a new line to the message
# OUTS: None
function pretty_print() {
    if [[ $# -lt 1 ]]; then
        script_exit 'Missing required argument to pretty_print()!' 2
    fi

    if [[ -z ${no_colour-} ]]; then
        if [[ -n ${2-} ]]; then
            printf '%b' "$2"
        else
            printf '%b' "$fg_green"
        fi
    fi

    # Print message & reset text attributes
    if [[ -n ${3-} ]]; then
        printf '%s%b' "$1" "$ta_none"
    else
        printf '%s%b\n' "$1" "$ta_none"
    fi
}


# DESC: Only pretty_print() the provided string if verbose mode is enabled
# ARGS: $@ (required): Passed through to pretty_pretty() function
# OUTS: None
function verbose_print() {
    if [[ -n ${verbose-} ]]; then
        pretty_print "$@"
    fi
}


# DESC: Combines two path variables and removes any duplicates
# ARGS: $1 (required): Path(s) to join with the second argument
#       $2 (optional): Path(s) to join with the first argument
# OUTS: $build_path: The constructed path
# NOTE: Heavily inspired by: https://unix.stackexchange.com/a/40973
function build_path() {
    if [[ $# -lt 1 ]]; then
        script_exit 'Missing required argument to build_path()!' 2
    fi

    local new_path path_entry temp_path

    temp_path="$1:"
    if [[ -n ${2-} ]]; then
        temp_path="$temp_path$2:"
    fi

    new_path=
    while [[ -n $temp_path ]]; do
        path_entry="${temp_path%%:*}"
        case "$new_path:" in
            *:"$path_entry":*) ;;
                            *) new_path="$new_path:$path_entry"
                               ;;
        esac
        temp_path="${temp_path#*:}"
    done

    # shellcheck disable=SC2034
    build_path="${new_path#:}"
}


# DESC: Check a binary exists in the search path
# ARGS: $1 (required): Name of the binary to test for existence
#       $2 (optional): Set to any value to treat failure as a fatal error
# OUTS: None
function check_binary() {
    if [[ $# -lt 1 ]]; then
        script_exit 'Missing required argument to check_binary()!' 2
    fi

    if ! command -v "$1" > /dev/null 2>&1; then
        if [[ -n ${2-} ]]; then
            script_exit "Missing dependency: Couldn't locate $1." 1
        else
            verbose_print "Missing dependency: $1" "${fg_red-}"
            return 1
        fi
    fi

    verbose_print "Found dependency: $1"
    return 0
}


# DESC: Validate we have superuser access as root (via sudo if requested)
# ARGS: $1 (optional): Set to any value to not attempt root access via sudo
# OUTS: None
function check_superuser() {
    local superuser test_euid
    if [[ $EUID -eq 0 ]]; then
        superuser=true
    elif [[ -z ${1-} ]]; then
        if check_binary sudo; then
            pretty_print 'Sudo: Updating cached credentials ...'
            if ! sudo -v; then
                verbose_print "Sudo: Couldn't acquire credentials ..." \
                              "${fg_red-}"
            else
                test_euid="$(sudo -H -- "$BASH" -c 'printf "%s" "$EUID"')"
                if [[ $test_euid -eq 0 ]]; then
                    superuser=true
                fi
            fi
        fi
    fi

    if [[ -z ${superuser-} ]]; then
        verbose_print 'Unable to acquire superuser credentials.' "${fg_red-}"
        return 1
    fi

    verbose_print 'Successfully acquired superuser credentials.'
    return 0
}


# DESC: Run the requested command as root (via sudo if requested)
# ARGS: $1 (optional): Set to zero to not attempt execution via sudo
#       $@ (required): Passed through for execution as root user
# OUTS: None
function run_as_root() {
    if [[ $# -eq 0 ]]; then
        script_exit 'Missing required argument to run_as_root()!' 2
    fi

    local try_sudo
    if [[ ${1-} =~ ^0$ ]]; then
        try_sudo=true
        shift
    fi

    if [[ $EUID -eq 0 ]]; then
        "$@"
    elif [[ -z ${try_sudo-} ]]; then
        sudo -H -- "$@"
    else
        script_exit "Unable to run requested command as root: $*" 1
    fi
}


# DESC: Usage help
# ARGS: None
# OUTS: None
function script_usage() {
    cat << EOF
Usage:
     -h|--help                  Displays this help
     -v|--verbose               Displays verbose output
    -nc|--no-colour             Disables colour output
    -s|--silentt                Run silently unless we encounter an error
    -host|--hostname            Display system's hostname
    -cf|--show_configuration    Show configuration info
    -as|--active_schedule       Active recorder's schedule
    -ds|--deactive_schedule     Deactive recorder's schedule
    -ci|--create_index          Create database index
    -a|--about                  About $0
EOF
}


# DESC: Parameter parser
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: Variables indicating command-line parameters and options
function parse_params() {
    local param
    while [[ $# -gt 0 ]]; do
        param="$1"
        shift
        case $param in
            -h|--help)
                script_usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                ;;
            -nc|--no-colour)
                no_colour=true
                ;;
            -s|--silent)
                cron=true
                ;;
            -host|--hostname)
                hostname=true
                ;;
            -cf|--show_configuration)
				show_configuration=true
				;;
            -as|--active_schedule)
				active_sch=true
				;;
			-ds|--deactive_schedule)
				active_sch=false
				;;
			-ci|--create_index)
				create_index=true
				;;
			-a|--about)
				about=true
				;;
            *)
                script_exit "Invalid parameter was provided: $param" 2
                ;;
        esac
    done
}

# DESC: Active schedule
# ARGS: None
# OUTS:
function active_schedule() {
	pretty_print "active schedule!"
	crontab -l | grep -v "$0" | crontab -
	(crontab -l && echo "0 1 * * * $orig_cwd/$0") | crontab -
	echo $RECORD_ROOT_PASS | sudo -S service cron restart
}

# DESC: Deactive schedule
# ARGS: None
# OUTS:
function deactive_schedule() {
	pretty_print "deactive schedule!"
	crontab -l | grep -v "$0" | crontab -
	echo $RECORD_ROOT_PASS | sudo -S service cron restart
}


# DESC: Print old data task
# ARGS: None
# OUTS: None
function print_old_data(){
	pretty_print "Print out of date data satisfy time range $TIME_RANGE"
	psql $RECORD_DB_NAME $RECORD_DB_USER -p $RECORD_DB_PORT  -h $RECORD_DB_HOST -c "select object_id from $RECORD_LIFE_CIRCLE where lifetime && $TIME_RANGE";
}


# DESC: Backup task
# ARGS: None
# OUTS: None
function backup_old_data(){
	OBJECT_FILE="$orig_cwd/object_lifecycle.csv"
	EVENT_FILE="$orig_cwd/object_event.csv"
	pretty_print "Backup out of date data satisfy $TIME_RANGE!"
	touch $OBJECT_FILE
	touch $EVENT_FILE
	psql $RECORD_DB_NAME $RECORD_DB_USER -p $RECORD_DB_PORT  -h $RECORD_DB_HOST -c "\COPY (select * from $RECORD_LIFE_CYCLE where lifetime && $TIME_RANGE) to "\'$OBJECT_FILE\'"";	
	psql $RECORD_DB_NAME $RECORD_DB_USER -p $RECORD_DB_PORT  -h $RECORD_DB_HOST -c "\COPY (select * from $RECORD_OBJECT_EVENT WHERE object_id in (select object_id from $RECORD_LIFE_CYCLE where lifetime && $TIME_RANGE)) to "\'$EVENT_FILE\'"";
	BACKUP_FILE=".records.$(date --date="$ST day ago" '+%Y%m%d%H%M%S')_$(date --date="$ET day ago" '+%Y%m%d%H%M%S').tar.gz"
	tar cvf - *.csv | gzip -9 -> $BACKUP_FILE
	rm -f $OBJECT_FILE $EVENT_FILE
}

# DESC: Log event task
# ARGS: None
# OUTS:
function schedule_log_task(){
	echo "$(date '+%Y-%m-%d %H:%M:%S') Run schedule task for data satisfy $TIME_RANGE ---> $BACKUP_FILE" >> .record_schedule.log
}

# DESC: Erase old task
# ARGS: None
# OUTS: None
function erase_old_data(){
	pretty_print "Start erase old data satisfy time range $TIME_RANGE"
	psql $RECORD_DB_NAME $RECORD_DB_USER -p $RECORD_DB_PORT  -h $RECORD_DB_HOST -c "delete from $RECORD_LIFE_CYCLE where lifetime && $TIME_RANGE";
}


# DESC: schedule task
# ARGS: None
# OUTS: None
function schedule_task(){
	ST="$(($RECORD_EXP_TIME + 1))"
	ET=$RECORD_EXP_TIME
	START_TIME="$(date --date="$ST day ago" '+%Y-%m-%d %H:%M:%S')"
	END_TIME="$(date --date="$ET day ago" '+%Y-%m-%d %H:%M:%S')"
	TIME_RANGE="tsrange('$START_TIME','$END_TIME')"
	
	pretty_print "Time range: $TIME_RANGE"

	#print_old_data
	backup_old_data 
	erase_old_data
	schedule_log_task
}

# DESC: create database index
# ARGS: None
# OUTS: None
function create_dbindex(){
	psql $RECORD_DB_NAME $RECORD_DB_USER -p $RECORD_DB_PORT -h $RECORD_DB_HOST -c "create index object_id_index_lifecycle ON $RECORD_LIFE_CYCLE  USING btree (object_id NULLS FIRST)";
	psql $RECORD_DB_NAME $RECORD_DB_USER -p $RECORD_DB_PORT -h $RECORD_DB_HOST -c "create index object_id_index_objectevent ON $RECORD_OBJECT_EVENT USING btree (object_id NULLS FIRST)";
}

# DESC: About
# ARGS: None
# OUTS: None
function about(){
	pretty_print "About $0"
	pretty_print "Author nguyennd5@viettel.com.vn"
	pretty_print "Date 2019-01-08"
}

# DESC: Main control flow
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: None
function main() {
    trap script_trap_err ERR
    trap script_trap_exit EXIT

    script_init "$@"
    parse_params "$@"
    silent_init
    colour_init
    config_init

    #lock_init system
    if [[ -n ${hostname-} ]]; then
        pretty_print "Hostname is: $(hostname)"
    fi
    
    if [[ -n ${active_sch-} ]]
    then
    	echo $active_sch
    	if [ $active_sch = true ]; then
    		active_schedule
    	else
    		deactive_schedule
    	fi
    	exit
	fi
	if [[ -n ${show_configuration-} ]]; then
		show_config
		exit
	fi

	if [[ -n ${create_index-} ]]; then
		create_dbindex
		exit
	fi

	if [[ -n ${about-} ]]; then
		about
		exit
	fi


	
	schedule_task


}


# Make it rain
main "$@"

# vim: syntax=sh cc=80 tw=79 ts=4 sw=4 sts=4 et sr
