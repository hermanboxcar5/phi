#!/bin/bash

# Function to check for insmod entries in startup scripts
check_insmod_in_startup() {
    echo "Checking for insmod entries in startup scripts..."
    grep -r "insmod" /etc/init.d /etc/rc.local /etc/profile /etc/bash.bashrc ~/.bashrc ~/.profile
}

# Function to check and ensure /etc/modprobe.d/*.conf files are correctly configured
check_modprobe_conf() {
    echo "Checking /etc/modprobe.d/*.conf files..."
    for file in /etc/modprobe.d/*.conf; do
        echo "Checking $file..."
        cat "$file"
    done
}

# Function to check for insmod entries in /lib/modprobe.d/
check_modprobe_lib() {
    echo "Checking for insmod entries in /lib/modprobe.d/..."
    grep -r "insmod" /lib/modprobe.d/
}

# Function to ensure all module loading entries reside in /etc/modprobe.d/*.conf files
ensure_modprobe_conf() {
    echo "Ensuring all module loading entries reside in /etc/modprobe.d/*.conf files..."
    for dir in /lib/modprobe.d/; do
        for file in "$dir"*.conf; do
            echo "Moving $file to /etc/modprobe.d/"
            sudo mv "$file" /etc/modprobe.d/
        done
    done
}

# Function to ensure the preferred way to load modules is with modprobe
ensure_modprobe_usage() {
    echo "Ensuring the preferred way to load modules is with modprobe..."
    echo "alias insmod modprobe" | sudo tee -a /etc/modprobe.d/aliases.conf
}

# Function to check module loadable status
module_loadable_chk() {
    # Check if the module is currently loadable
    l_loadable="$(modprobe -n -v "$l_mname")"
    [ "$(wc -l <<< "$l_loadable")" -gt "1" ] && l_loadable="$(grep -P -- "(^\h*install|\b$l_mname)\b" <<< "$l_loadable")"
    if grep -Pq -- '^\h*install \/bin\/(true|false)' <<< "$l_loadable"; then
        l_output="$l_output\n - module: \"$l_mname\" is not loadable: \"$l_loadable\""
    else
        l_output2="$l_output2\n - module: \"$l_mname\" is loadable: \"$l_loadable\""
    fi
}

# Function to check module loaded status
module_loaded_chk() {
    # Check if the module is currently loaded
    if ! lsmod | grep "$l_mname" > /dev/null 2>&1; then
        l_output="$l_output\n - module: \"$l_mname\" is not loaded"
    else
        l_output2="$l_output2\n - module: \"$l_mname\" is loaded"
    fi
}

# Function to check module deny list status
module_deny_chk() {
    # Check if the module is deny listed
    l_dl="y"
    if modprobe --showconfig | grep -Pq -- '^\h*blacklist\h+'"$l_mpname"'\b'; then
        l_output="$l_output\n - module: \"$l_mname\" is deny listed in: \"$(grep -Pls -- "^\h*blacklist\h+$l_mname\b" "$l_searchloc")\""
    else
        l_output2="$l_output2\n - module: \"$l_mname\" is not deny listed"
    fi
}

# Function to check if the module exists on the system
check_module_existence() {
    for l_mdir in $l_mpath; do
        if [ -d "$l_mdir/$l_mndir" ] && [ -n "$(ls -A "$l_mdir"/"$l_mndir")" ]; then
            l_output3="$l_output3\n - \"$l_mdir\""
            [ "$l_dl" != "y" ] && module_deny_chk
            if [ "$l_mdir" = "/lib/modules/$(uname -r)/kernel/$l_mtype" ]; then
                module_loadable_chk
                module_loaded_chk
            fi
        else
            l_output="$l_output\n - module: \"$l_mname\" doesn't exist in \"$l_mdir\""
        fi
    done
}

# Function to report results
report_results() {
    [ -n "$l_output3" ] && echo -e "\n\n -- INFO --\n - module: \"$l_mname\" exists in:$l_output3"
    if [ -z "$l_output2" ]; then
        echo -e "\n- Audit Result:\n ** PASS **\n$l_output\n"
    else
        echo -e "\n- Audit Result:\n ** FAIL **\n - Reason(s) for audit failure:\n$l_output2\n"
        [ -n "$l_output" ] && echo -e "\n- Correctly set:\n$l_output\n"
    fi
}

# Function to check module loadable status for freevxfs
module_loadable_chk_freevxfs() {
    # Check if the module is currently loadable
    l_loadable="$(modprobe -n -v "$l_mname")"
    [ "$(wc -l <<< "$l_loadable")" -gt "1" ] && l_loadable="$(grep -P -- "(^\h*install|\b$l_mname)\b" <<< "$l_loadable")"
    if grep -Pq -- '^\h*install \/bin\/(true|false)' <<< "$l_loadable"; then
        l_output="$l_output\n - module: \"$l_mname\" is not loadable: \"$l_loadable\""
    else
        l_output2="$l_output2\n - module: \"$l_mname\" is loadable: \"$l_loadable\""
    fi
}

# Function to check module loaded status for freevxfs
module_loaded_chk_freevxfs() {
    # Check if the module is currently loaded
    if ! lsmod | grep "$l_mname" > /dev/null 2>&1; then
        l_output="$l_output\n - module: \"$l_mname\" is not loaded"
    else
        l_output2="$l_output2\n - module: \"$l_mname\" is loaded"
    fi
}

# Function to check module deny list status for freevxfs
module_deny_chk_freevxfs() {
    # Check if the module is deny listed
    l_dl="y"
    if modprobe --showconfig | grep -Pq -- '^\h*blacklist\h+'"$l_mpname"'\b'; then
        l_output="$l_output\n - module: \"$l_mname\" is deny listed in: \"$(grep -Pls -- "^\h*blacklist\h+$l_mname\b" "$l_searchloc")\""
    else
        l_output2="$l_output2\n - module: \"$l_mname\" is not deny listed"
    fi
}

# Function to check if the freevxfs module exists on the system
check_module_existence_freevxfs() {
    for l_mdir in $l_mpath; do
        if [ -d "$l_mdir/$l_mndir" ] && [ -n "$(ls -A "$l_mdir"/"$l_mndir")" ]; then
            l_output3="$l_output3\n - \"$l_mdir\""
            [ "$l_dl" != "y" ] && module_deny_chk_freevxfs
            if [ "$l_mdir" = "/lib/modules/$(uname -r)/kernel/$l_mtype" ]; then
                module_loadable_chk_freevxfs
                module_loaded_chk_freevxfs
            fi
        else
            l_output="$l_output\n - module: \"$l_mname\" doesn't exist in \"$l_mdir\""
        fi
    done
}

# Function to report results for freevxfs
report_results_freevxfs() {
    [ -n "$l_output3" ] && echo -e "\n\n -- INFO --\n - module: \"$l_mname\" exists in:$l_output3"
    if [ -z "$l_output2" ]; then
        echo -e "\n- Audit Result:\n ** PASS **\n$l_output\n"
    else
        echo -e "\n- Audit Result:\n ** FAIL **\n - Reason(s) for audit failure:\n$l_output2\n"
        [ -n "$l_output" ] && echo -e "\n- Correctly set:\n$l_output\n"
    fi
}

# Function to configure kernel module files
configure_kernel_module_files() {
    # Check and ensure /etc/modprobe.d/*.conf files are correctly configured
    check_modprobe_conf

    # Ensure all module loading entries reside in /etc/modprobe.d/*.conf files
    ensure_modprobe_conf

    # Ensure the preferred way to load modules is with modprobe
    ensure_modprobe_usage
}

# Function to configure /tmp
configure_tmp() {
    echo "Configuring /tmp..."
    sudo mkdir -p /tmp
    sudo chmod 1777 /tmp
    sudo mount -o remount,nodev,nosuid,noexec /tmp
    echo "tmpfs /tmp tmpfs defaults,nodev,nosuid,noexec 0 0" | sudo tee -a /etc/fstab
}

# Function to configure /dev/shm
configure_dev_shm() {
    echo "Configuring /dev/shm..."
    sudo mount -o remount,nodev,nosuid,noexec /dev/shm
    echo "tmpfs /dev/shm tmpfs defaults,nodev,nosuid,noexec 0 0" | sudo tee -a /etc/fstab
}

# Function to configure /home
configure_home() {
    echo "Configuring /home..."
    sudo mkdir -p /home
    sudo chmod 755 /home
    sudo mount -o remount,nodev /home
    echo "/dev/sdX /home ext4 defaults,nodev 0 2" | sudo tee -a /etc/fstab
}

# Function to configure /var
configure_var() {
    echo "Configuring /var..."
    sudo mkdir -p /var
    sudo chmod 755 /var
    sudo mount -o remount,nodev /var
    echo "/dev/sdX /var ext4 defaults,nodev 0 2" | sudo tee -a /etc/fstab
}

# Function to configure /var/tmp
configure_var_tmp() {
    echo "Configuring /var/tmp..."
    sudo mkdir -p /var/tmp
    sudo chmod 1777 /var/tmp
    sudo mount -o remount,nodev,nosuid,noexec /var/tmp
    echo "tmpfs /var/tmp tmpfs defaults,nodev,nosuid,noexec 0 0" | sudo tee -a /etc/fstab
}

# Function to configure /var/log
configure_var_log() {
    echo "Configuring /var/log..."
    sudo mkdir -p /var/log
    sudo chmod 755 /var/log
    sudo mount -o remount,nodev /var/log
    echo "/dev/sdX /var/log ext4 defaults,nodev 0 2" | sudo tee -a /etc/fstab
}

# Function to configure /var/log/audit
configure_var_log_audit() {
    echo "Configuring /var/log/audit..."
    sudo mkdir -p /var/log/audit
    sudo chmod 755 /var/log/audit
    sudo mount -o remount,nodev /var/log/audit
    echo "/dev/sdX /var/log/audit ext4 defaults,nodev 0 2" | sudo tee -a /etc/fstab
}

# Main script execution
configure_kernel_module_files
configure_tmp
configure_dev_shm
configure_home
configure_var
configure_var_tmp
configure_var_log
configure_var_log_audit

# Unset output variables
l_output="" l_output2="" l_output3="" l_dl=""

# Set module name and type
l_mname="cramfs"
l_mtype="fs"
l_searchloc="/lib/modprobe.d/*.conf /usr/local/lib/modprobe.d/*.conf /run/modprobe.d/*.conf /etc/modprobe.d/*.conf"
l_mpath="/lib/modules/**/kernel/$l_mtype"
l_mpname="$(tr '-' '_' <<< "$l_mname")"
l_mndir="$(tr '-' '/' <<< "$l_mname")"

# Check and report existence of the module
check_module_existence
report_results

# Repeat the process for freevxfs
l_output="" l_output2="" l_output3="" l_dl="" # Unset output variables
l_mname="freevxfs" # set module name
l_mtype="fs" # set module type
l_searchloc="/lib/modprobe.d/*.conf /usr/local/lib/modprobe.d/*.conf /run/modprobe.d/*.conf /etc/modprobe.d/*.conf"
l_mpath="/lib/modules/**/kernel/$l_mtype"
l_mpname="$(tr '-' '_' <<< "$l_mname")"
l_mndir="$(tr '-' '/' <<< "$l_mname")"

check_module_existence_freevxfs
report_results_freevxfs
