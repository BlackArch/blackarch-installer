source "$(pwd)/lib/globals.cfg"

# print formatted output
wprintf()
{
    fmt="${1}"

    shift
    printf "%s${fmt}%s" "${WHITE}" "${@}" "${NC}"

    return $SUCCESS
}


# print warning
warn()
{
    printf "%s[!] WARNING: %s%s\n" "${YELLOW}" "${@}" "${NC}"

    return $SUCCESS
}


# print error and exit
err()
{
    printf "%s[-] ERROR: %s%s\n" "${RED}" "${@}" "${NC}"
    exit $FAILURE

    return $SUCCESS
}


# leet banner (very important)
banner()
{
    columns="$(tput cols)"
    str="--==[ blackarch-installer ${VERSION} ]==--"

    printf "${REDB}%*s${NC}\n" "${COLUMNS:-$(tput cols)}" | tr ' ' '-'

    echo "${str}" |
    while IFS= read -r line
    do
        printf "%s%*s\n%s" "${WHITEB}" $(( (${#line} + columns) / 2)) \
            "$line" "${NC}"
    done

    printf "${REDB}%*s${NC}\n\n\n" "${COLUMNS:-$(tput cols)}" | tr ' ' '-'

    return "$SUCCESS"
}


# sleep and clear
sleep_clear()
{
    sleep $1
    clear

    return $SUCCESS
}


# confirm user inputted yYnN
confirm()
{
    header="${1}"
    ask="${2}"

    while true
    do
        title "${header}"
        wprintf "${ask}"
        read input
        if [ "${input}" = "y" -o "${input}" = "Y" ]
        then
            return $TRUE
        elif [ "${input}" = "n" -o "${input}" = "N" ]
        then
            return $FALSE
        else
            clear
            continue
        fi
    done

    return $SUCCESS
}


# print menu title
title()
{
    banner
    printf "${GREEN}>> %s${NC}\n\n\n" "${@}"

    return "${SUCCESS}"
}


# check for environment issues
check_env()
{
    if [ -f "/var/lib/pacman/db.lck" ]
    then
        err "pacman locked - Please remove /var/lib/pacman/db.lck"
    fi
}


# check user id
check_uid()
{
    if [ `id -u` -ne 0 ]
    then
        err "You must be root to run the BlackArch installer!"
    fi

    return $SUCCESS
}


# welcome and ask for installation mode
ask_install_mode()
{
    while [ \
        "${INSTALL_MODE}" != "${INSTALL_REPO}" -a \
        "${INSTALL_MODE}" != "${INSTALL_BLACKMAN}" -a \
        "${INSTALL_MODE}" != "${INSTALL_ISO}" ]
    do
        title "Welcome to the BlackArch Linux installation!"
        wprintf "[+] Available installation modes:"
        printf "\n
    1. Install from repository using pacman
    2. Install from sources using blackman
    3. Install from Live-ISO (not implemented yet)\n\n"
        wprintf "[?] Choose an installation mode: "
        read INSTALL_MODE
    clear
    done

    return $SUCCESS
}


# ask for keymap to use
ask_keymap()
{
    while [ \
        "${keymap_opt}" != "${SET_KEYMAP}" -a \
        "${keymap_opt}" != "${LIST_KEYMAP}" ]
    do
        title "Keymap Setup"
        wprintf "[+] Available keymap options:"
        printf "\n
    1. Set a keymap
    2. List available keymaps\n\n"
        wprintf "[?] Make a choice: "
        read keymap_opt

        if [ "${keymap_opt}" = "${SET_KEYMAP}" ]
        then
            break
        fi
        if [ "${keymap_opt}" = "${LIST_KEYMAP}" ]
        then
            localectl list-keymaps
            echo
        fi
        clear
    done

    clear

    return $SUCCESS
}


# set keymap to use
set_keymap()
{
    title "Keymap Setup"
    wprintf "[?] Set keymap [us]: "
    read KEYMAP

    # default keymap
    if [ -z "${KEYMAP}" ]
    then
        KEYMAP="us"
    fi

    localectl set-keymap --no-convert "${KEYMAP}"
    loadkeys "${KEYMAP}"

    return $SUCCESS
}


# enable multilib in pacman.conf if x86_64 present
enable_pacman_multilib()
{
    title "Update pacman.conf"

    if [ "`uname -m`" = "x86_64" ]
    then
        wprintf "[+] Enabling multilib support"
        printf "\n\n"
        if grep -q "#\[multilib\]" /etc/pacman.conf
        then
            # it exists but commented
            sed -i '/\[multilib\]/{ s/^#//; n; s/^#//; }' /etc/pacman.conf
        elif ! grep -q "\[multilib\]" /etc/pacman.conf
        then
            # it does not exist at all
            printf "[multilib]\nInclude = /etc/pacman.d/mirrorlist\n" \
                >> /etc/pacman.conf
        fi
    fi

    return $SUCCESS
}


# enable color mode in pacman.conf
enable_pacman_color()
{
    title "Update pacman.conf"

    wprintf "[+] Enabling color mode"
    printf "\n\n"

    sed -i 's/^#Color/Color/' /etc/pacman.conf

    return $SUCCESS
}


# update pacman.conf
update_pacman_conf()
{
    enable_pacman_multilib
    sleep_clear 1

    enable_pacman_color
    sleep_clear 1

    return $SUCCESS
}


# ask user for hostname
ask_hostname()
{
    while [ -z "${HOST_NAME}" ]
    do
        title "Network Setup"
        wprintf "[?] Set your hostname: "
        read HOST_NAME
        clear
    done

    return $SUCCESS
}

# get available network interfaces
get_net_ifs()
{
    NET_IFS="`ls /sys/class/net`"

    return $SUCCESS
}


# ask user for network interface
ask_net_if()
{
    while true
    do
        title "Network Setup"
        wprintf "[+] Available network interfaces:"
        printf "\n\n"
        for i in ${NET_IFS}
        do
            echo "    > ${i}"
        done
        echo
        wprintf "[?] Please choose a network interface: "
        read NET_IF
        if echo ${NET_IFS} | grep "\<${NET_IF}\>" > /dev/null
        then
            clear
            break
        fi
        clear
    done

    return $SUCCESS
}


# ask for networking configuration mode
ask_net_conf_mode()
{
    while [ \
        "${NET_CONF_MODE}" != "${NET_CONF_AUTO}" -a \
        "${NET_CONF_MODE}" != "${NET_CONF_MANUAL}" -a \
        "${NET_CONF_MODE}" != "${NET_CONF_SKIP}" ]
    do
        title "Network setup - Configure network interface"
        wprintf "[+] Configuruation modes for network interfaces:"
        printf "\n
    1. Auto (DHCP)
    2. Manual
    3. Skip\n\n"
        wprintf "[?] Please choose a mode: "
        read NET_CONF_MODE
        clear
    done

    return $SUCCESS
}


# ask for network addresses
ask_net_addr()
{
    while [ \
        "${HOST_IPV4}" = "" -o "${GATEWAY}" = "" -o "${SUBNETMASK}" = "" \
        -o "${BROADCAST}" = "" -o "${NAMESERVER}" = "" ]
    do
        title "Network Setup"
        wprintf "[+] Configuring network interface '${NET_IF}' via USER: "
        printf "\n
    > Host ipv4
    > Gateway ipv4
    > Subnetmask
    > Broadcast
    > Nameserver
        \n"
        wprintf "[?] Host ipv4: "
        read HOST_IPV4
        wprintf "[?] Gateway ipv4: "
        read GATEWAY
        wprintf "[?] Subnetmask: "
        read SUBNETMASK
        wprintf "[?] Broadcast: "
        read BROADCAST
        wprintf "[?] Nameserver: "
        read NAMESERVER
        clear
    done

    return $SUCCESS
}


# manual network interface configuration
net_conf_manual()
{
    ip addr flush dev ${NET_IF}
    ip link set ${NET_IF} up
    ip addr add ${HOST_IPV4}/${SUBNETMASK} broadcast ${BROADCAST} dev ${NET_IF}
    ip route add default via ${GATEWAY}
    echo "nameserver ${NAMESERVER}" > /etc/resolv.conf

    return $SUCCESS
}


# auto (dhcp) network interface configuration
net_conf_auto()
{
    opts="-h noleak -i noleak -v ,noleak -I noleak"

    title "Network Setup"
    wprintf "[+] Configuring network interface '${NET_IF}' via DHCP: "
    printf "\n\n"

    dhcpcd ${opts} -i ${NET_IF}

    return $SUCCESS
}


# check for internet connection
check_inet_conn()
{
    if ! ping -c1 google.com > /dev/null 2>&1
    then
        err "No Internet connection! Check your network (settings)."
    fi

    return $SUCCESS
}


# ask user for luks encrypted partition
ask_luks()
{
    while [ "${LUKS}" = "" ]
    do
        if confirm "Hard Drive Setup" "[?] Full encrypted root [y/n]: "
        then
            LUKS=$TRUE
            echo
            warn "The root partition will be encrypted"
        else
            LUKS=$FALSE
            echo
            warn "The root partition will NOT be encrypted"
        fi
        sleep_clear 2
    done
    return $SUCCESS
}


# get available hard disks
get_hd_devs()
{
    HD_DEVS="`lsblk | grep disk | awk '{print $1}'`"

    return $SUCCESS
}


# ask user for device to format and setup
ask_hd_dev()
{
    while true
    do
        title "Hard Drive Setup"

        wprintf "[+] Available hard drives for installation:"
        printf "\n\n"

        for i in ${HD_DEVS}
        do
            echo "    > ${i}"
        done
        echo
        wprintf "[?] Please choose a device: "
        read HD_DEV
        if echo ${HD_DEVS} | grep "\<${HD_DEV}\>" > /dev/null
        then
            HD_DEV="/dev/${HD_DEV}"
            clear
            break
        fi
        clear
    done


    return $SUCCESS
}


# ask user to create partitions using cfdisk
ask_cfdisk()
{
    if confirm "Hard Drive Setup" "[?] Create partitions with cfdisk (root and \
boot, optional swap) [y/n]: "
    then
        cfdisk -z "${HD_DEV}"
        sync
    else
        echo
        err "Are you kidding me? No partitions no fun!"
    fi

    return $SUCCESS
}


# get partition label
get_partition_label()
{
    PART_LABEL="`parted -m ${HD_DEV} print | grep ${HD_DEV} | cut -d ':' -f 6`"

    return $SUCCESS
}


# get partitions
get_partitions()
{
    partitions=`ls ${HD_DEV}* | grep -v "${HD_DEV}\>"`

    while [ \
        "${BOOT_PART}" = "" -o \
        "${ROOT_PART}" = "" -o \
        "${BOOT_FS_TYPE}" = "" -o \
        "${ROOT_FS_TYPE}" = "" ]
    do
        title "Hard Drive Setup"
        wprintf "[+] Created partitions:"
        printf "\n\n"

        for i in ${partitions}
        do
            echo "    > ${i}"
        done
        echo

        wprintf "[?] Boot partition (/dev/sdXY): "
        read BOOT_PART
        wprintf "[?] Boot FS type (ext2, ext3, ext4, fat32): "
        read BOOT_FS_TYPE
        wprintf "[?] Root partition (/dev/sdXY): "
        read ROOT_PART
        wprintf "[?] Root FS type (ext2, ext3, ext4): "
        read ROOT_FS_TYPE
        wprintf "[?] Swap parition (/dev/sdXY - empty for none): "
        read SWAP_PART

        if [ "${SWAP_PART}" = "" ]
        then
            SWAP_PART="none"
        fi
        clear
    done

    return $SUCCESS
}


# print partitions and ask for confirmation
print_partitions()
{
    i=""

    while true
    do
        title "Hard Drive Setup"
        wprintf "[+] Current Partition table"
        printf "\n
    > /boot     : ${BOOT_PART} (${BOOT_FS_TYPE})
    > /         : ${ROOT_PART} (${ROOT_FS_TYPE})
    > swap      : ${SWAP_PART} (swap)
    \n"
        wprintf "[?] Partition table correct [y/n]: "
        read i
        if [ "${i}" = "y" -o "${i}" = "Y" ]
        then
            clear
            break
        elif [ "${i}" = "n" -o "${i}" = "N" ]
        then
            echo
            err "B00m! Hard Drive Setup aborted."
        else
            clear
            continue
        fi
        clear
    done

    return $SUCCESS
}


# ask user and get confirmation for formatting
ask_formatting()
{
    if confirm "Hard Drive Setup" "[?] Formatting partitions. Are you sure? \
[y/n]: "
    then
        return $SUCCESS
    else
        echo
        err "Seriously? No formatting no fun!"
    fi

    return $SUCCESS
}


# create LUKS encrypted partition
make_luks_partition()
{
    part="${1}"

    title "Hard Drive Setup"

    wprintf "[+] Creating LUKS partition"
    printf "\n"
    cryptsetup -y -v -s 512 luksFormat "${part}"

    return $SUCCESS
}


# open LUKS partition
open_luks_partition()
{
    part="${1}"
    name="${2}"

    title "Hard Drive Setup"

    wprintf "[+] Opening LUKS partition"
    printf "\n\n"
    cryptsetup open "${part}" "${name}"

    return $SUCCESS
}


# create swap partition
make_swap_partition()
{
    title "Hard Drive Setup"

    wprintf "[+] Creating SWAP partition"
    printf "\n\n"
    mkswap "${SWAP_PART}"

    return $SUCCESS
}


# make and format root partition
make_root_partition()
{
    if [ ${LUKS} = ${TRUE} ]
    then
        make_luks_partition "${ROOT_PART}"
        sleep_clear 1
        open_luks_partition "${ROOT_PART}" "${CRYPT_ROOT}"
        sleep_clear 1
        title "Hard Drive Setup"
        wprintf "[+] Creating encrypted ROOT partition"
        printf "\n\n"
        mkfs.${ROOT_FS_TYPE} "/dev/mapper/${CRYPT_ROOT}"
        sleep_clear 1
    else
        title "Hard Drive Setup"
        wprintf "[+] Creating ROOT partition"
        printf "\n\n"
        mkfs.${ROOT_FS_TYPE} -F ${ROOT_PART}
        sleep_clear 1
    fi

    return $SUCCESS
}


# make and format boot partition
make_boot_partition()
{
    title "Hard Drive Setup"

    wprintf "[+] Creating BOOT partition"
    printf "\n\n"
    if [ "${PART_LABEL}" = "gpt" ]
    then
        mkfs.fat -F32 ${BOOT_PART}
    else
        mkfs.${BOOT_FS_TYPE} -F ${BOOT_PART}
    fi

    return $SUCCESS
}


# make and format partitions
make_partitions()
{
    make_boot_partition
    sleep_clear 1

    make_root_partition
    sleep_clear 1

    if [ "${SWAP_PART}" != "none" ]
    then
        make_swap_partition
        sleep_clear 1
    fi

    return $SUCCESS
}


# mount filesystems
mount_filesystems()
{
    title "Hard Drive Setup"

    wprintf "[+] Mounting filesystems"
    printf "\n\n"

    # ROOT
    if [ ${LUKS} = ${TRUE} ]
    then
        mount "/dev/mapper/${CRYPT_ROOT}" ${CHROOT} > /dev/null 2>&1
    else
        mount ${ROOT_PART} ${CHROOT} > /dev/null 2>&1
    fi

    # BOOT
    mkdir /mnt/boot > /dev/null 2>&1
    mount ${BOOT_PART} "${CHROOT}/boot" > /dev/null 2>&1

    # SWAP
    swapon "${SWAP_PART}" > /dev/null 2>&1

    return $SUCCESS
}


# unmount filesystems
umount_filesystems()
{
    routine="${1}"

    if [ "${routine}" = "harddrive" ]
    then
        title "Hard Drive Setup"
    else
        title "Game Over"
    fi

    wprintf "[+] Unmounting filesystems"
    printf "\n\n"

    umount -Rf ${CHROOT} > /dev/null 2>&1
    umount -Rf "${BOOT_PART}" > /dev/null 2>&1
    umount -Rf "${CHROOT}/proc" > /dev/null 2>&1
    umount -Rf "${CHROOT}/sys" > /dev/null 2>&1
    umount -Rf "${CHROOT}/dev" > /dev/null 2>&1
    umount -Rf "${BOOT_PART}" > /dev/null 2>&1
    umount -Rf "${ROOT_PART}" > /dev/null 2>&1
    umount -Rf "/dev/mapper/${CRYPT_ROOT}" > /dev/null 2>&1
    cryptsetup luksClose "${CRYPT_ROOT}" > /dev/null 2>&1
    swapoff "${SWAP_PART}" > /dev/null 2>&1

    return $SUCCESS
}


# install ArchLinux base and base-devel packages
install_base_packages()
{
    title "Base System Installation"

    wprintf "[+] Installing ArchLinux base packages"
    printf "\n\n"

    pacstrap ${CHROOT} base base-devel

    return $SUCCESS
}


# setup fstab
setup_fstab()
{
    title "Base System Setup"

    wprintf "[+] Setting up /etc/fstab"
    printf "\n\n"

    if [ "${PART_LABEL}" = "gpt" ]
    then
        genfstab -U ${CHROOT} >> "${CHROOT}/etc/fstab"
    else
        genfstab -L ${CHROOT} >> "${CHROOT}/etc/fstab"
    fi

    return $SUCCESS
}


# setup locale and keymap
setup_locale()
{
    title "Base System Setup"

    wprintf "[+] Setting up default locale (en_US.UTF-8)"
    printf "\n\n"

    sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' "${CHROOT}/etc/locale.gen"
    chroot ${CHROOT} locale-gen
    echo "KEYMAP=${KEYMAP}" > "${CHROOT}/etc/vconsole.conf"

    return $SUCCESS
}


# setup time and timezone
setup_time()
{
    title "Base System Setup"

    wprintf "[+] Setting up default time and timezone: Europe/Berlin"
    printf "\n\n"

    chroot ${CHROOT} tzselect


    return $SUCCESS
}


# setup initramfs
setup_initramfs()
{
    title "Base System Setup"

    wprintf "[+] Setting up initramfs"
    printf "\n\n"

    if [ ${LUKS} = ${TRUE} ]
    then
        sed -i 's/block filesystems/block keymap encrypt filesystems/g' \
            "${CHROOT}/etc/mkinitcpio.conf"
    fi

    chroot ${CHROOT} mkinitcpio -p linux

    return $SUCCESS
}


# mount /proc, /sys and /dev
setup_proc_sys_dev()
{
    title "Base System Setup"

    wprintf "[+] Setting up /proc, /sys and /dev"
    printf "\n\n"

    mkdir -p ${CHROOT}{proc,sys,dev} > /dev/null 2>&1

    mount -t proc proc "${CHROOT}/proc"
    mount --rbind /sys "${CHROOT}/sys"
    mount --make-rslave "${CHROOT}/sys"
    mount --rbind /dev "${CHROOT}/dev"
    mount --make-rslave "${CHROOT}/dev"

    return $SUCCESS
}


# setup hostname
setup_hostname()
{
    title "Base System Setup"

    wprintf "[+] Setting up hostname"
    printf "\n\n"

    echo "${HOST_NAME}" > "${CHROOT}/etc/hostname"

    return $SUCCESS
}


# setup boot loader for UEFI/GPT or BIOS/MBR
setup_bootloader()
{
    uuid="`blkid ${ROOT_PART} | cut -d ' ' -f 2 | cut -d '"' -f 2`"

    title "Base System Setup"

    if [ "${PART_LABEL}" = "gpt" ]
    then
        wprintf "[+] Setting up EFI boot loader"
        printf "\n\n"

        chroot ${CHROOT} bootctl install

        if [ ${LUKS} = ${TRUE} ]
        then
            cat >> "${CHROOT}/boot/loader/entries/arch.conf" << EOF
title       Arch Linux
linux       /vmlinuz-linux
initrd      /initramfs-linux.img
options     cryptdevice=UUID=${uuid}:${CRYPT_ROOT} root=/dev/mapper/${CRYPT_ROOT} rw
EOF

        else
            cat >> "${CHROOT}/boot/loader/entries/arch.conf" << EOF
title       Arch Linux
linux       /vmlinuz-linux
initrd      /initramfs-linux.img
options     root=UUID=${uuid} rw
EOF
        fi
    else
        wprintf "[+] Setting up GRUB boot loader"
        printf "\n\n"

        chroot ${CHROOT} pacman -S grub --noconfirm --force --needed

        if [ -f "data/boot/grub/splash.png" ]
        then
            cp data/boot/grub/splash.png "${CHROOT}/boot/grub/splash.png"
        else
            cp /usr/share/blackarckarch-installer/data/boot/grub/splash.png \
                "${CHROOT}/boot/grub/splash.png"
        fi
        if [ ${LUKS} = ${TRUE} ]
        then
            sed -i "s|quiet|cryptdevice=${ROOT_PART}:${CRYPT_ROOT} root=/dev/mapper/${CRYPT_ROOT}|" "${CHROOT}/etc/default/grub"
        fi
        sed -i 's/quiet//g' "${CHROOT}/etc/default/grub"
        sed -i 's/Arch/BlackArch/g' "${CHROOT}/etc/default/grub"
        echo "GRUB_BACKGROUND=\"/boot/grub/splash.png\"" >> \
            "${CHROOT}/etc/default/grub"
        chroot ${CHROOT} grub-install --target=i386-pc "${HD_DEV}"
        chroot ${CHROOT} grub-mkconfig -o /boot/grub/grub.cfg
        sed -i 's/Arch Linux/BlackArch Linux/g' "${CHROOT}/boot/grub/grub.cfg"
        chroot ${CHROOT} grub-mkconfig -o /boot/grub/grub.cfg
    fi

    return $SUCCESS
}


# ask for normal user account to setup
ask_user_account()
{
    if confirm "Base System Setup" "[?] Setup a normal user account [y/n]: "
    then
        wprintf "[?] User name: "
        read NORMAL_USER
    fi

    return $SUCCESS
}


# setup user account, password and environment
setup_user()
{
    user="${1}"

    title "Base System Setup"

    wprintf "[+] Setting up ${user} account"
    printf "\n\n"

    # normal user
    if [ ! -z ${NORMAL_USER} ]
    then
        chroot ${CHROOT} groupadd ${user}
        chroot ${CHROOT} useradd -g ${user} -d "/home/${user}" -s "/bin/bash" \
            -G "wheel,users" -m ${user}
        chroot ${CHROOT} chown -R ${user}:${user} "/home/${user}"
        wprintf "[+] Added user: ${user}"
        printf "\n\n"
    fi

    # environment
    if [ -z ${NORMAL_USER} ]
    then
        if [ -d "data/root" ]
        then
            cp -r data/root/. "${CHROOT}/root/."
        else
            cp -r /usr/share/blackarckarch-installer/data/root/. \
                "${CHROOT}/root/."
        fi
    else
        cp -r data/user/. "${CHROOT}/home/${user}/."
    fi

    # password
    wprintf "[?] Set password for ${user}: "
    printf "\n\n"
    if [ "${user}" = "root" ]
    then
        chroot ${CHROOT} passwd
    else
        chroot ${CHROOT} passwd "${user}"
    fi

    return $SUCCESS
}


# install extra (missing) packages
setup_extra_packages()
{
    arch="abs arch-install-scripts archlinux-keyring pkgfile"

    bluetooth="bluez bluez-firmware bluez-hid2hci bluez-utils"

    browser="firefox midori elinks"

    editor="vim"

    filesystem="btrfs-progs cryptsetup device-mapper dmraid dosfstools
    gptfdisk nilfs-utils ntfs-3g partclone parted partimage"

    fonts="ttf-liberation ttf-dejavu ttf-freefont xorg-font-utils
    xorg-fonts-alias xorg-fonts-misc xorg-mkfontscale xorg-mkfontdir
    ttf-indic-otf"

    kernel="linux-api-headers linux-headers"

    misc="acpi alsa-utils b43-fwcutter bash-completion bc btrfs-progs cmake
    ctags expac feh flashplugin git gpm grml-zsh-config haveged hdparm htop
    inotify-tools ipython irssi linux-atm lsof mercurial mesa mlocate moreutils
    mpv mtools mupdf p7zip rsync rtorrent scrot smartmontools speedtouch strace
    sudo tzdata unace unrar unzip usb_modeswitch zip zsh"

    network="wicd-gtk wicd bridge-utils darkhttpd atftp bind-tools dnsmasq
    dhclient dnsutils gnu-netcat ipw2100-fw ipw2200-fw lftp nfs-utils ntp
    openconnect openssh openvpn ppp pptpclient rfkill rp-pppoe vpnc
    wireless_tools wpa_actiond wvdial xl2tpd zd1211-firmware"

    xorg="xf86-video-ark xf86-video-ati xf86-video-chips
    xf86-video-dummy xf86-video-fbdev xf86-video-glint
    xf86-video-i128 xf86-video-i740 xf86-video-intel xf86-video-mach64
    xf86-video-neomagic xf86-video-nouveau
    xf86-video-nv xf86-video-openchrome xf86-video-r128 xf86-video-rendition
    xf86-video-s3 xf86-video-s3virge xf86-video-savage xf86-video-siliconmotion
    xf86-video-sis xf86-video-sisusb xf86-video-tdfx xf86-video-trident
    xf86-video-tseng xf86-video-vesa xf86-video-vmware xf86-video-voodoo
    xorg-server xorg-xinit xorg-server-utils xterm"

    all="${arch} ${bluetooth} ${browser} ${editor} ${filesystem} ${fonts}"
    all="${all} ${kernel} ${misc} ${network} ${xorg}"

    title "Base System Setup"

    wprintf "[+] Installing extra packages"
    printf "\n"

    printf "
    > ArchLinux     : `echo ${arch} | wc -w` packages
    > Browser       : `echo ${browser} | wc -w` packages
    > Bluetooth     : `echo ${bluetooth} | wc -w` packages
    > Editor        : `echo ${editor} | wc -w` packages
    > Filesystem    : `echo ${filesystem} | wc -w` packages
    > Fonts         : `echo ${fonts} | wc -w` packages
    > Misc          : `echo ${misc} | wc -w` packages
    > Network       : `echo ${network} | wc -w` packages
    > Xorg          : `echo ${xorg} | wc -w` packages
    \n"

    sleep 2

    chroot ${CHROOT} pacman -S --needed --force --noconfirm `echo ${all}`

    return $SUCCESS
}


# perform system base setup/configurations
setup_base_system()
{
    cp "/etc/resolv.conf" "${CHROOT}/etc/resolv.conf"

    setup_fstab
    sleep_clear 1

    setup_proc_sys_dev
    sleep_clear 1

    setup_locale
    sleep_clear 1

    setup_initramfs
    sleep_clear 1

    setup_hostname
    sleep_clear 1

    setup_user "root"
    sleep_clear 1

    ask_user_account
    sleep_clear 1

    if [ ! -z "${NORMAL_USER}" ]
    then
        setup_user "${NORMAL_USER}"
        sleep_clear 1
    fi

    setup_extra_packages
    sleep_clear 1

    setup_bootloader
    sleep_clear 1

    return $SUCCESS
}


# update /etc files
update_etc()
{
    title "BlackArch Linux Setup"

    wprintf "[+] Updating /etc files"
    printf "\n\n"

    # /etc/pacman.conf
    cp "/etc/pacman.conf" "${CHROOT}/etc/pacman.conf"

    # /etc/*
    if [ -d "data/etc/" ]
    then
        cp "data/etc/"* "${CHROOT}/etc/."
    else
        cp "/usr/share/blackarch-installer/data/etc/"* "${CHROOT}/etc/."
    fi

    return $SUCCESS
}


# ask for blackarch linux mirror
ask_mirror()
{
    title "BlackArch Linux Setup"

    local IFS='|'
    count=1
    mirror_url="https://raw.githubusercontent.com/BlackArch/blackarch/master/mirror/mirror.lst"
    mirror_file="/tmp/mirror.lst"

    wprintf "[+] Fetching mirror list"
    printf "\n\n"
    curl -s -o "${mirror_file}" "${mirror_url}"

    while read -r country url mirror_name
    do
        wprintf "   %s. %s - %s" "${count}" "${country}" "${mirror_name}"
        printf "\n"
        wprintf "       * %s" "${url}"
        printf "\n"
        count=`expr $count + 1`
    done < "${mirror_file}"

    printf "\n"
    wprintf "[?] Select a mirror number. Enter for default: "
    read a
    printf "\n"

    # bugfix: detected chars added sometimes - clear chars
    _a=`printf "%s" $a | sed 's/[a-z]//Ig'`

    if [ -z "${_a}" ]
    then
        wprintf "[+] Choosing default mirror: %s " "${BA_REPO_URL}"
    else
        BA_REPO_URL=`sed -n "${_a}p" "${mirror_file}" | cut -d "|" -f 2`
        wprintf "[+] Mirror from '%s' selected" \
            `sed -n "${_a}p" "${mirror_file}" | cut -d "|" -f 3`
        printf "\n\n"
    fi

    rm -f "${mirror_file}"

    return $SUCCESS
}


# run strap.sh
run_strap_sh()
{
    strap_sh="/tmp/strap.sh"
    orig_sha1="86eb4efb68918dbfdd1e22862a48fda20a8145ff"

    title "BlackArch Linux Setup"

    wprintf "[+] Downloading and executing strap.sh"
    printf "\n\n"

    curl -s -o "${strap_sh}" "https://www.blackarch.org/strap.sh"
    sha1=`sha1sum ${strap_sh} | awk '{print $1}'`

    if [ "${sha1}" = ${orig_sha1} ]
    then
        mv ${strap_sh} "${CHROOT}${strap_sh}"
        chmod a+x "${CHROOT}${strap_sh}"
        chroot ${CHROOT} sh ${strap_sh}
    else
        cri "Wrong SHA1 sum for strap.sh: ${sha1} (orig: ${orig_sha1}). Aborting!"
    fi

    # add blackarch linux mirror if we are in chroot
    if ! grep -q "blackarch" "${CHROOT}/etc/pacman.conf"
    then
        printf '[blackarch]\nServer = %s\n' "${BA_REPO_URL}" \
            >> "${CHROOT}/etc/pacman.conf"
    else
        sed -i "/\[blackarch\]/{ n;s?Server.*?Server = ${BA_REPO_URL}?; }" \
            "${CHROOT}/etc/pacman.conf"
    fi

    return $SUCCESS
}


# ask user for X (display + window manager) setup
ask_x_setup()
{
    if confirm "BlackArch Linux Setup" "[?] Setup X display + window managers [y/n]: "
    then
        X_SETUP=$TRUE
        printf "\n"
        printf "${BLINK}NOOB! NOOB! NOOB! NOOB! NOOB! NOOB! NOOB!${NC}\n\n"
    fi

    return $SUCCESS
}


# setup display manager
setup_display_manager()
{
    title "BlackArch Linux Setup"

    wprintf "[+] Setting up LXDM display manager"
    printf "\n"

    printf "
    > Lxdm
    \n"

    sleep 2

    # install lxdm packages
    chroot ${CHROOT} pacman -S lxdm blackarch-config-lxdm blackarch-config-gtk \
        --needed --force --noconfirm

    # config files
    chroot ${CHROOT} cp -a /etc/lxdm-blackarch/. /etc/lxdm/.
    chroot ${CHROOT} cp -a /usr/share/lxdm-blackarch/. /usr/share/lxdm/.
    chroot ${CHROOT} mv /usr/share/xsessions-blackarch/ /usr/share/xsessions/
    chroot ${CHROOT} cp -a /usr/share/gtk-blackarch/. /usr/share/gtk-2.0/.

    # enable it in systemd
    chroot ${CHROOT} systemctl enable lxdm

    # remove wrong xsession entries entries
    chroot ${CHROOT} rm -rf "/usr/share/xsessions/openbox-kde.desktop"
    chroot ${CHROOT} rm -rf "/usr/share/xsessions/i3-with-shmlog.desktop"

    return $SUCCESS
}


# setup window managers
setup_window_managers()
{
    title "BlackArch Linux Setup"

    wprintf "[+] Setting up window managers"
    printf "\n"

    printf "
    > Awesome
    > Dwm
    > Fluxbox
    > I3-wm
    > Openbox
    > Spectrwm
    \n"

    sleep 2

    chroot ${CHROOT} pacman -S fluxbox openbox awesome i3-wm wmii dwm spectrwm \
        blackarch-config-fluxbox blackarch-config-openbox \
        blackarch-config-awesome blackarch-config-wmii \
        blackarch-config-spectrwm --needed --force --noconfirm

    # awesome
    chroot ${CHROOT} cp /etc/xdg/awesome/rc.lua.blackarch \
        /etc/xdg/awesome/rc.lua

    # fluxbox
    chroot ${CHROOT} cp -a /usr/share/fluxbox-blackarch/. /usr/share/fluxbox/.

    # openbox
    chroot ${CHROOT} cp -a /etc/xdg/openbox-blackarch/. /etc/xdg/openbox/.
    chroot ${CHROOT} mv /usr/share/themes/blackarch/openbox-3-blackarch/ \
        /usr/share/themes/blackarch/openbox-3

    # spectrwm
    chroot ${CHROOT} cp -a /usr/share/spectrwm-blackarch/spectrwm.conf \
        /etc/spectrwm.conf

    # wmii
    chroot ${CHROOT} cp -a /usr/share/wmii-blackarch/. /etc/wmii/.

    return $SUCCESS
}


# ask user for VirtualBox modules+utils setup
ask_vbox_setup()
{
    if confirm "BlackArch Linux Setup" "[?] Setup VirtualBox modules [y/n]: "
    then
        VBOX_SETUP=$TRUE
    fi

    return $SUCCESS
}


# setup virtualbox utils
setup_vbox_utils()
{
    title "BlackArch Linux Setup"

    wprintf "[+] Setting up VirtualBox utils"
    printf "\n\n"

    chroot ${CHROOT} pacman -S virtualbox-guest-utils \
        --force --needed --noconfirm

    chroot ${CHROOT} systemctl enable vboxservice
    chroot ${CHROOT} systemctl enable vboxadd
    chroot ${CHROOT} systemctl enable vboxadd-service
    chroot ${CHROOT} systemctl enable vboxadd-x11

    printf "vboxguest\nvboxsf\nvboxvideo\n" \
        > "${CHROOT}/etc/modules-load.d/vbox.conf"

    return $SUCCESS
}


# ask user for BlackArch tools setup
ask_ba_tools_setup()
{
    if confirm "BlackArch Linux Setup" "[?] Setup BlackArch Linux tools [y/n]: "
    then
        BA_TOOLS_SETUP=$TRUE
    fi

    return $SUCCESS
}


# setup blackarch tools from repository (binary) or via blackman (source)
setup_blackarch_tools()
{
    foo=5

    title "BlackArch Linux Setup"

    wprintf "[+] Installing BlackArch Linux packages (grab a coffee)"
    printf "\n\n"

    if [ ${INSTALL_MODE} = ${INSTALL_REPO} ]
    then
        chroot ${CHROOT} pacman -S --needed --force --noconfirm blackarch
    else
        warn "Installing all tools from source via blackman can take hours..."
        printf "\n"
        wprintf "[+] <Control-c> to abort ... "
        while [ $foo -gt 0 ]
        do
            wprintf "$foo "
            sleep 1
            foo=`expr $foo - 1`
        done
        printf "\n"
        chroot ${CHROOT} pacman -S --needed --force --noconfirm blackman
        blackman -a
    fi

    return $SUCCESS
}


# setup blackarch related stuff
setup_blackarch()
{
    update_etc
    sleep_clear 1

    ask_mirror
    sleep_clear 1

    run_strap_sh
    sleep_clear 1

    ask_x_setup
    sleep_clear 2

    if [ $X_SETUP -eq $TRUE ]
    then
        setup_display_manager
        sleep_clear 1
        setup_window_managers
        sleep_clear 1
    fi

    ask_vbox_setup
    sleep_clear 1

    if [ $VBOX_SETUP -eq $TRUE ]
    then
        setup_vbox_utils
        sleep_clear 1
    fi

    ask_ba_tools_setup
    sleep_clear 1

    if [ $BA_TOOLS_SETUP -eq $TRUE ]
    then
        setup_blackarch_tools
        sleep_clear 1
    fi

    return $SUCCESS
}


# for fun and lulz
easter_backdoor()
{
    foo=0

    title "Game Over"

    wprintf "[+] BlackArch Linux installation successfull!"
    printf "\n\n"

    wprintf "Yo n00b, b4ckd00r1ng y0ur sy5t3m n0w "
    while [ $foo -ne 5 ]
    do
        wprintf "."
        sleep 1
        foo=`expr $foo + 1`
    done
    printf " >> ${BLINK}${WHITE}HACK THE PLANET${NC} <<"
    printf "\n"

    return $SUCCESS
}


# perform sync
sync_disk()
{
    title "Game Over"

    wprintf "[+] Syncing disk"
    printf "\n\n"

    sync

    return $SUCCESS
}

