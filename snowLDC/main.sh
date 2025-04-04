#!/bin/bash

configure_unattended_upgrades() {
    sudo apt-get install unattended-upgrades -y
    sudo dpkg-reconfigure --priority=low unattended-upgrades
}

check_apt_directory() {
    echo "Checking for suspicious files in /etc/apt..."
    for file in $(ls /etc/apt); do
        if [[ "$file" != "sources.list" && "$file" != "trusted.gpg" && "$file" != "trusted.gpg.d" ]]; then
            echo "Suspicious file found: $file"
        fi
    done
}

update_system() {
    sudo apt-get update && sudo apt-get upgrade -y
}

# Function to configure UFW firewall
configure_firewall() {
    sudo apt-get install ufw -y
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw enable
    sudo ufw logging on
    sudo chmod 700 /var/log/ufw.log
}

# Function to configure PAM
configure_pam() {
    sudo tee /etc/pam.d/common-auth <<EOL
auth    required                        pam_tally2.so onerr=fail deny=5 unlock_time=900
auth    requisite                       pam_faillock.so audit deny=5 unlock_time=900 even_deny_root_account
auth    [success=1 default=ignore]      pam_unix.so
auth    requisite                       pam_deny.so
auth    required                        pam_permit.so
auth    optional                        pam_cap.so
EOL

    sudo tee /etc/pam.d/common-password <<EOL
password    requisite           pam_pwquality.so retry=4 minlen=14 difok=3 dcredit=-1 ucredit=-1 lcredit=-1 ocredit=-1 minclass=3 maxrepeat=2 maxsequence=3 gecoscheck enforce_for_root
password    [success=1 default=ignore]  pam_unix.so obscure use_authtok try_first_pass sha512 remember=5
password    required            pam_permit.so
# end of pam-auth-update config
EOL
}

# Function to configure login definitions
configure_login_defs() {
    sudo tee /etc/login.defs <<EOL
PASS_MAX_DAYS   15
PASS_MIN_DAYS   7
PASS_MIN_LEN    12
PASS_WARN_AGE   7
UID_MIN         1000
UID_MAX         60000
GID_MIN         1000
GID_MAX         60000
UMASK           027
ENCRYPT_METHOD  SHA512
EOL
}

# Function to purge malware and prohibited software
purge_malware() {
    local malware_list=(
        'xz-utils' 'pvpgn' 'unworkable' 'netcat-openbsd' 'apache2' '42' '4g8' 'adfind' 'adm' 'advancedipscanner' 'advancedrun' 'adore' 'aidra' 'autofs' 'aisleriot' 'aircrack' 'alaeda'
        'amap' 'angryipscanner' 'anydesk' 'arches' 'atera' 'asyncrat' 'autohotkey' 'backproxy' 'badbunny' 'binom' 'bliss' 'boldmove' 'brundle' 'bukowski' 'caveat' 'ccleaner' 'cephei'
        'cheese' 'cloudsnooper' 'cobaltstrike' 'coin' 'connectwise' 'crack' 'deluge' 'deluge-gtk' 'devnull' 'discord' 'dmitry' 'effusion' 'energymech' 'ettercap' 'ettermap' 'evilgnome'
        'ezuri' 'fcrackzip' 'firejail' 'gafgyt' 'gameconqueror' 'goldeneye' 'gonnacry' 'handofthief' 'hashcat' 'hasher' 'hotrat' 'hping' 'hummingbad' 'hydra' 'icedid' 'icecast'
        'icecast2' 'icefire' 'iodine' 'iodine_client' 'iobitdriverbooster' 'iobitunlocker' 'john' 'kaiten' 'keygen' 'kinsing' 'kork' 'kryptina' 'lacrimae' 'lazagne' 'lcrack' 'lightaidra'
        'lilocked' 'linuxdarlloz' 'linuxencoder' 'linuxlupper' 'linuxmillen' 'linuxremaiten' 'linuxlion' 'logkeys' 'luabot' 'mallox' 'manaplus' 'masscan' 'mayhem' 'medusa' 'megasync'
        'memcached' 'mighty' 'mimikatz' 'mirai' 'mozi' 'netcat' 'netcat-traditional' 'netpass' 'nessus' 'newaidra' 'nginx' 'nikto' 'nmap' 'nyadr-op' 'nuxbee' 'ophcrack' 'p0f' 'pchunter'
        'pdqdeploy' 'perfctl' 'pilot' 'pigmygoat' 'pnscan' 'podloso' 'processhacker' 'psexec' 'pyrit' 'pyxie' 'ramen' 'ransomexx' 'rclone' 'redis-cli' 'redis-server' 'regasm' 'relx'
        'revouninstaller' 'rexob' 'rike' 'rst' 'samba' 'slapper' 'slubstick' 'snakso' 'speakup' 'ssh' 'staog' 'syslogk' 'tcpdump' 'teamviewer' 'telnet' 'tightvnc' 'tsunami' 'turla'
        'tycoon' 'unicornscan' 'useradd' 'varnishd' 'vatetloader' 'vermilionstrike' 'vit' 'waterfall' 'winter' 'winux' 'wireshark' 'witvirus' 'xorddos' 'zariche' 'zeitgeist' 'zenmap'
        'zipworm' 'zmap' 'sucrack' 'changeme'
    )
    for malware in "${malware_list[@]}"; do
        echo "Purging $malware..."
        sudo apt-get purge --autoremove "$malware"
    done
}

# Function to delete non-work-related or troll applications
delete_troll_apps() {
    local troll_apps=(
        'sl' 'oneko' 'cowsay' 'fortune' 'toilet' 'cmatrix' 'nyancat' 'xeyes' 'kde-games' 'bb' 'fortune-mod'
    )
    for app in "${troll_apps[@]}"; do
        echo "Removing $app..."
        sudo apt-get purge --autoremove -y "$app"
    done
}

clear_crontab() {
    echo "Clearing crontab for all users..."
    for user in $(cut -f1 -d: /etc/passwd); do
        crontab -r -u "$user"
    done
    sudo rm -f /etc/cron.deny
    sudo touch /etc/cron.allow
    sudo chmod 600 /etc/cron.allow
    sudo chown root:root /etc/cron.allow
}

fix_gpg_permissions() {
    echo "Fixing GPG keys directory permissions..."
    sudo chmod 700 /etc/apt/trusted.gpg.d
}

set_file_permissions() {
    echo "Setting file permissions according to CIS Benchmark..."
    sudo chmod -R go-rwx /etc/cron.d
    sudo chmod -R go-rwx /etc/cron.daily
    sudo chmod -R go-rwx /etc/cron.hourly
    sudo chmod -R go-rwx /etc/cron.monthly
    sudo chmod -R go-rwx /etc/cron.weekly
    sudo chmod -R go-wx /etc/crontab
    sudo chmod -R go-rwx /etc/ssh/ssh_config
    sudo chmod -R go-rwx /etc/ssh/sshd_config
    sudo chmod -R go-rwx /etc/gshadow-
    sudo chmod -R go-rwx /etc/shadow-
    sudo chmod -R go-rwx /etc/group-
    sudo chmod -R go-rwx /etc/passwd-
    sudo chmod -R go-rwx /etc/securetty
    sudo chmod -R go-rwx /etc/sysctl.conf
    sudo chmod -R go-rwx /etc/hosts.allow
    sudo chmod -R go-rwx /etc/hosts.deny
    sudo chmod -R go-w /etc/issue
    sudo chmod -R go-w /etc/motd
}

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

# Directory to start the search
SEARCH_DIR="/"

# Log file to record deleted files
LOG_FILE="/var/log/dele ted_media_files.log"

# Function to find and delete mp3 and mp4 files
remove_media_files() {
    find "$SEARCH_DIR" -type f \( -iname "*.mp3" -o -iname "*.mp4" \) -print -delete | tee -a "$LOG_FILE"
}

configure_ipv4() {
    echo "Configuring IPv4 settings..."
    
    # Ensure IP forwarding is disabled
    sudo sysctl -w net.ipv4.ip_forward=0
    sudo sed -i 's/^net.ipv4.ip_forward.*/net.ipv4.ip_forward = 0/' /etc/sysctl.conf
    
    # Ensure packet redirect sending is disabled
    sudo sysctl -w net.ipv4.conf.all.send_redirects=0
    sudo sysctl -w net.ipv4.conf.default.send_redirects=0
    sudo sed -i 's/^net.ipv4.conf.all.send_redirects.*/net.ipv4.conf.all.send_redirects = 0/' /etc/sysctl.conf
    sudo sed -i 's/^net.ipv4.conf.default.send_redirects.*/net.ipv4.conf.default.send_redirects = 0/' /etc/sysctl.conf
    
    # Ensure source routed packets are not accepted
    sudo sysctl -w net.ipv4.conf.all.accept_source_route=0
    sudo sysctl -w net.ipv4.conf.default.accept_source_route=0
    sudo sed -i 's/^net.ipv4.conf.all.accept_source_route.*/net.ipv4.conf.all.accept_source_route = 0/' /etc/sysctl.conf
    sudo sed -i 's/^net.ipv4.conf.default.accept_source_route.*/net.ipv4.conf.default.accept_source_route = 0/' /etc/sysctl.conf
    
    # Ensure ICMP redirects are not accepted
    sudo sysctl -w net.ipv4.conf.all.accept_redirects=0
    sudo sysctl -w net.ipv4.conf.default.accept_redirects=0
    sudo sed -i 's/^net.ipv4.conf.all.accept_redirects.*/net.ipv4.conf.all.accept_redirects = 0/' /etc/sysctl.conf
    sudo sed -i 's/^net.ipv4.conf.default.accept_redirects.*/net.ipv4.conf.default.accept_redirects = 0/' /etc/sysctl.conf
    
    # Ensure secure ICMP redirects are not accepted
    sudo sysctl -w net.ipv4.conf.all.secure_redirects=0
    sudo sysctl -w net.ipv4.conf.default.secure_redirects=0
    sudo sed -i 's/^net.ipv4.conf.all.secure_redirects.*/net.ipv4.conf.all.secure_redirects = 0/' /etc/sysctl.conf
    sudo sed -i 's/^net.ipv4.conf.default.secure_redirects.*/net.ipv4.conf.default.secure_redirects = 0/' /etc/sysctl.conf
    
    # Ensure suspicious packets are logged
    sudo sysctl -w net.ipv4.conf.all.log_martians=1
    sudo sysctl -w net.ipv4.conf.default.log_martians=1
    sudo sed -i 's/^net.ipv4.conf.all.log_martians.*/net.ipv4.conf.all.log_martians = 1/' /etc/sysctl.conf
    sudo sed -i 's/^net.ipv4.conf.default.log_martians.*/net.ipv4.conf.default.log_martians = 1/' /etc/sysctl.conf
    
    # Ensure broadcast ICMP requests are ignored
    sudo sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1
    sudo sed -i 's/^net.ipv4.icmp_echo_ignore_broadcasts.*/net.ipv4.icmp_echo_ignore_broadcasts = 1/' /etc/sysctl.conf
    
    # Ensure bogus ICMP responses are ignored
    sudo sysctl -w net.ipv4.icmp_ignore_bogus_error_responses=1
    sudo sed -i 's/^net.ipv4.icmp_ignore_bogus_error_responses.*/net.ipv4.icmp_ignore_bogus_error_responses = 1/' /etc/sysctl.conf
    
    # Ensure Reverse Path Filtering is enabled
    sudo sysctl -w net.ipv4.conf.all.rp_filter=1
    sudo sysctl -w net.ipv4.conf.default.rp_filter=1
    sudo sed -i 's/^net.ipv4.conf.all.rp_filter.*/net.ipv4.conf.all.rp_filter = 1/' /etc/sysctl.conf
    sudo sed -i 's/^net.ipv4.conf.default.rp_filter.*/net.ipv4.conf.default.rp_filter = 1/' /etc/sysctl.conf
    
    # Ensure TCP SYN Cookies is enabled
    sudo sysctl -w net.ipv4.tcp_syncookies=1
    sudo sed -i 's/^net.ipv4.tcp_syncookies.*/net.ipv4.tcp_syncookies = 1/' /etc/sysctl.conf
}

# Function to configure IPv6 settings according to CIS Benchmark
configure_ipv6() {
    echo "Configuring IPv6 settings..."
    
    # Ensure IPv6 router advertisements are not accepted
    sudo sysctl -w net.ipv6.conf.all.accept_ra=0
    sudo sysctl -w net.ipv6.conf.default.accept_ra=0
    sudo sed -i 's/^net.ipv6.conf.all.accept_ra.*/net.ipv6.conf.all.accept_ra = 0/' /etc/sysctl.conf
    sudo sed -i 's/^net.ipv6.conf.default.accept_ra.*/net.ipv6.conf.default.accept_ra = 0/' /etc/sysctl.conf
    
    # Ensure IPv6 redirects are not accepted
    sudo sysctl -w net.ipv6.conf.all.accept_redirects=0
    sudo sysctl -w net.ipv6.conf.default.accept_redirects=0
    sudo sed -i 's/^net.ipv6.conf.all.accept_redirects.*/net.ipv6.conf.all.accept_redirects = 0/' /etc/sysctl.conf
    sudo sed -i 's/^net.ipv6.conf.default.accept_redirects.*/net.ipv6.conf.default.accept_redirects = 0/' /etc/sysctl.conf
    
    # Ensure IPv6 is disabled if not required
    sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
    sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
    sudo sed -i 's/^net.ipv6.conf.all.disable_ipv6.*/net.ipv6.conf.all.disable_ipv6 = 1/' /etc/sysctl.conf
    sudo sed -i 's/^net.ipv6.conf.default.disable_ipv6.*/net.ipv6.conf.default.disable_ipv6 = 1/' /etc/sysctl.conf
}

configure_bootloader_password() {
    echo "Configuring Bootloader password..."
    sudo grub-mkpasswd-pbkdf2 | tee /boot/grub2/grub.cfg
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet console=tty0 console=ttyS0,115200n8"/g' /etc/default/grub
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg
}

# Function to configure ptrace scope
configure_ptrace_scope() {
    echo "Configuring ptrace scope..."
    echo "kernel.yama.ptrace_scope = 1" | sudo tee -a /etc/sysctl.d/10-ptrace.conf
    sudo sysctl -p /etc/sysctl.d/10-ptrace.conf
}

# Function to restrict core dumps
restrict_core_dumps() {
    echo "Restricting core dumps..."
    echo "* hard core 0" | sudo tee -a /etc/security/limits.conf
    echo "fs.suid_dumpable = 0" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
}

# Function to configure /etc/motd
configure_motd() {
    echo "Configuring /etc/motd..."
    sudo tee /etc/motd <<EOL
Authorized uses only. All activity may be monitored and reported.
EOL
}

# Function to configure /etc/issue
configure_issue() {
    echo "Configuring /etc/issue..."
    sudo tee /etc/issue <<EOL
Authorized uses only. All activity may be monitored and reported.
EOL
}

# Function to configure /etc/issue.net
configure_issue_net() {
    echo "Configuring /etc/issue.net..."
    sudo tee /etc/issue.net <<EOL
Authorized uses only. All activity may be monitored and reported.
EOL
}

# Function to ensure package manager repositories are configured
ensure_package_manager_repositories() {
    echo "Ensuring package manager repositories are configured..."
    # Example command to add a repository
    sudo add-apt-repository -y universe
    sudo add-apt-repository -y multiverse
}

# Function to ensure GPG keys are configured
ensure_gpg_keys() {
    echo "Ensuring GPG keys are configured..."
    # Example command to add a GPG key
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
}

# Function to ensure APT package manager repositories are configured
ensure_apt_repositories() {
    echo "Ensuring APT package manager repositories are configured..."
    sudo apt-get update
}

# Function to ensure the system is updated with the latest security patches
ensure_system_updated() {
    echo "Ensuring the system is updated with the latest security patches..."
    sudo apt-get upgrade -y
}

# Function to ensure automatic updates are enabled
ensure_automatic_updates() {
    echo "Ensuring automatic updates are enabled..."
    sudo apt-get install unattended-upgrades -y
    sudo dpkg-reconfigure --priority=low unattended-upgrades
}

ensure_necessary_services() {
    echo "Ensuring only necessary services are enabled..."
    # Disable unnecessary services (example: avahi-daemon)
    sudo systemctl disable avahi-daemon
    sudo systemctl stop avahi-daemon
}

# Function to ensure services do not run as root unless necessary
ensure_services_not_root() {
    echo "Ensuring services do not run as root unless necessary..."
    # Example: Ensure nginx runs as www-data
    sudo sed -i 's/^user .*/user www-data;/' /etc/nginx/nginx.conf
    sudo systemctl restart nginx
}

# Function to ensure only necessary client services are enabled
ensure_necessary_client_services() {
    echo "Ensuring only necessary client services are enabled..."
    # Disable unnecessary client services (example: cups)
    sudo systemctl disable cups
    sudo systemctl stop cups
}

# Function to ensure client services are configured with least privilege
configure_client_services_least_privilege() {
    echo "Configuring client services with least privilege..."
    # Example: Ensure NetworkManager runs with least privilege
    sudo sed -i 's/^#dns=dnsmasq/dns=dnsmasq/' /etc/NetworkManager/NetworkManager.conf
    sudo systemctl restart NetworkManager
}

# Function to ensure client services do not run as root unless necessary
ensure_client_services_not_root() {
    echo "Ensuring client services do not run as root unless necessary..."
    # Example: Ensure cron runs as a non-root user
    sudo sed -i 's/^#user .*/user cronuser;/' /etc/cron.d
    sudo systemctl restart cron
}

# Function to ensure time synchronization is in use
ensure_time_synchronization() {
    echo "Ensuring time synchronization is in use..."
    timedatectl set-ntp true
}

# Function to ensure systemd-timesyncd is configured
configure_systemd_timesyncd() {
    echo "Configuring systemd-timesyncd..."
    sudo apt-get install -y systemd-timesyncd
    sudo systemctl enable systemd-timesyncd
    sudo systemctl start systemd-timesyncd
}

# Function to ensure chrony is configured
configure_chrony() {
    echo "Configuring chrony..."
    sudo apt-get install -y chrony
    sudo systemctl enable chrony
    sudo systemctl start chrony
    # Add common chrony configurations
    echo "server 0.ubuntu.pool.ntp.org iburst" | sudo tee -a /etc/chrony/chrony.conf
    echo "server 1.ubuntu.pool.ntp.org iburst" | sudo tee -a /etc/chrony/chrony.conf
    echo "server 2.ubuntu.pool.ntp.org iburst" | sudo tee -a /etc/chrony/chrony.conf
    echo "server 3.ubuntu.pool.ntp.org iburst" | sudo tee -a /etc/chrony/chrony.conf
    echo "driftfile /var/lib/chrony/chrony.drift" | sudo tee -a /etc/chrony/chrony.conf
    echo "makestep 1.0 3" | sudo tee -a /etc/chrony/chrony.conf
}

# Function to ensure ntp is configured
configure_ntp() {
    echo "Configuring ntp..."
    sudo apt-get install -y ntp
    sudo systemctl enable ntp
    sudo systemctl start ntp
    # Add common ntp configurations
    echo "server 0.ubuntu.pool.ntp.org iburst" | sudo tee -a /etc/ntp.conf
    echo "server 1.ubuntu.pool.ntp.org iburst" | sudo tee -a /etc/ntp.conf
    echo "server 2.ubuntu.pool.ntp.org iburst" | sudo tee -a /etc/ntp.conf
    echo "server 3.ubuntu.pool.ntp.org iburst" | sudo tee -a /etc/ntp.conf
    echo "driftfile /var/lib/ntp/ntp.drift" | sudo tee -a /etc/ntp.conf
}

# Function to disable autofs service
disable_autofs() {
    echo "Disabling autofs service..."
    sudo systemctl disable autofs
    sudo systemctl stop autofs
}

# Function to disable dhcp service
disable_dhcp() {
    echo "Disabling dhcp service..."
    sudo systemctl disable isc-dhcp-server
    sudo systemctl stop isc-dhcp-server
}

# Function to disable dnsmasq service
disable_dnsmasq() {
    echo "Disabling dnsmasq service..."
    sudo systemctl disable dnsmasq
    sudo systemctl stop dnsmasq
}

# Function to disable iscsid service
disable_iscsid() {
    echo "Disabling iscsid service..."
    sudo systemctl disable iscsid
    sudo systemctl stop iscsid
}

# Function to disable print server service
disable_print_server() {
    echo "Disabling print server service..."
    sudo systemctl disable cups
    sudo systemctl stop cups
}

# Function to disable rpcbind service
disable_rpcbind() {
    echo "Disabling rpcbind service..."
    sudo systemctl disable rpcbind
    sudo systemctl stop rpcbind
}

# Function to disable rsync service
disable_rsync() {
    echo "Disabling rsync service..."
    sudo systemctl disable rsync
    sudo systemctl stop rsync
}

# Function to disable xinetd service
disable_xinetd() {
    echo "Disabling xinetd service..."
    sudo systemctl disable xinetd
    sudo systemctl stop xinetd
}

# Function to disable X Window System
disable_x_window() {
    echo "Disabling X Window System..."
    sudo systemctl disable lightdm
    sudo systemctl stop lightdm
}

modprobe(){
l_output="" l_output2="" l_output3="" l_dl=""

# Set module name and type
l_mname="cramfs"
l_mtype="fs"
l_searchloc="/lib/modprobe.d/*.conf /usr/local/lib/modprobe.d/*.conf /run/modprobe.d/*.conf /etc/modprobe.d/*.conf"
l_mpath="/lib/modules/**/kernel/$l_mtype"
l_mpname="$(tr '-' '_' <<< "$l_mname")"
l_mndir="$(tr '-' '/' <<< "$l_mname")"

l_output="" l_output2="" l_output3="" l_dl="" # Unset output variables
l_mname="freevxfs" # set module name
l_mtype="fs" # set module type
l_searchloc="/lib/modprobe.d/*.conf /usr/local/lib/modprobe.d/*.conf /run/modprobe.d/*.conf /etc/modprobe.d/*.conf"
l_mpath="/lib/modules/**/kernel/$l_mtype"
l_mpname="$(tr '-' '_' <<< "$l_mname")"
l_mndir="$(tr '-' '/' <<< "$l_mname")"
}


# Main script execution
update_system
configure_firewall
configure_pam
configure_login_defs
purge_malware
delete_troll_apps
clear_crontab
ensure_apt_repositories
ensure_system_updated
ensure_automatic_updates
ensure_necessary_services 
ensure_services_not_root
fix_gpg_permissions
set_file_permissions
configure_unattended_upgrades
check_apt_directory
configure_kernel_module_files
configure_tmp
configure_dev_shm
configure_home
configure_var
configure_var_tmp
configure_var_log
configure_var_log_audit

# Unset output variables


# Check and report existence of the module
check_module_existence
report_results

# Repeat the process for freevxfs


check_module_existence_freevxfs
report_results_freevxfs
remove_media_files
configure_ipv4
configure_ipv6
configure_bootloader_password
configure_ptrace_scope
restrict_core_dumps
configure_motd
configure_issue
configure_issue_net
ensure_package_manager_repositories
ensure_gpg_keys
ensure_necessary_client_services
configure_client_services_least_privilege
ensure_client_services_not_root
ensure_time_synchronization
configure_systemd_timesyncd
configure_chrony
configure_ntp
disable_autofs
disable_dhcp
disable_dnsmasq
disable_iscsid
disable_print_server
disable_rpcbind
disable_rsync
disable_xinetd
disable_x_window
modprobe
