#!/bin/bash

# Function to update and upgrade the system
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
        sudo apt-get purge --autoremove -y "$malware"
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

# Function to clear crontab
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

# Function to fix GPG keys directory permissions
fix_gpg_permissions() {
    echo "Fixing GPG keys directory permissions..."
    sudo chmod 700 /etc/apt/trusted.gpg.d
}

# Function to set file permissions according to CIS Benchmark
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

# Main script execution
update_system
configure_firewall
configure_pam
configure_login_defs
purge_malware
delete_troll_apps
clear_crontab
fix_gpg_permissions
set_file_permissions
