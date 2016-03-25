# ps: I am no expert on security
# 
# http://unix.stackexchange.com/questions/10922/temporarily-suspend-bash-history-on-a-given-shell

# http://stackoverflow.com/a/2654048/2975300

# http://stackoverflow.com/a/28393320/2975300

github_username="luzfcb"
playbooks_repro_name="playbooks"

repro_zip_package_url="https://github.com/$github_username/$playbooks_repro_name/archive/master.zip"

current_user="$USER"


function run_as_full_echo_off()
{   
    
    # Disable echo.
    stty_orig=$(stty -g)
    stty -echo

    # Set up trap to ensure echo is enabled before exiting if the script
    # is terminated while echo is disabled.
    trap 'stty echo' EXIT

    # run command
    "$@"

    # Enable echo.
    stty "$stty_orig"
    stty echo
    trap - EXIT

    # Print a newline because the newline entered by the user after
    # entering the passcode is not echoed. This ensures that the
    # next line of output begins at a new line.
    echo
}

function read_secret(){
    run_as_full_echo_off read -p "[sudo] password for $current_user": user_passwd
}

function install_ansible_and_other_required_tools(){
    ansible_repro=$(ls /etc/apt/sources.list.d/ | grep ansible-ansible-)

    if [[ -z $ansible_repro ]]; then
        run_as_full_echo_off  sudo -S <<< "$user_passwd" add-apt-repository ppa:ansible/ansible --yes
    fi

    
    run_as_full_echo_off sudo -S <<< "$user_passwd" apt-get update
    run_as_full_echo_off sudo -S <<< "$user_passwd" apt-get install ansible wget unzip --yes
}

function run_playbook(){
    local file_name="$playbooks_repro_name.zip"
    local file_full_output_path="/tmp/deploy_my_machine/$file_name"
    cd /tmp || exit
    rm -r /tmp/deploy_my_machine 2> /dev/null 
    mkdir -p /tmp/deploy_my_machine
    cd /tmp/deploy_my_machine || exit
    wget -O $file_full_output_path "$repro_zip_package_url"

    unzip $playbooks_repro_name
    cd "$playbooks_repro_name-master" || exit
    
    echo "running playbook"
    ansible-playbook workstation.yml --extra-vars "ansible_become_pass=$user_passwd"
    rm -r /tmp/deploy_my_machine 2> /dev/null 
}


# temporary disable history record
set +o history

# read current user password
read_secret

# add ansible ppa and install ansible, wget and unzip
install_ansible_and_other_required_tools

run_playbook

unset user_passwd

# re-enable history record
set -o history

