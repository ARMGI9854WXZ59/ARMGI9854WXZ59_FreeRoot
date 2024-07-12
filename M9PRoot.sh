#!/bin/sh

ROOTFS_DIR=$(pwd)
export PATH=$PATH:~/.local/usr/bin
max_retries=50
timeout=1
ARCH=$(uname -m)

# Check CPU architecture
if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64
else
  printf "\033[38;2;96;96;255mUnsupported CPU architecture: %s\033[0m\n" "$ARCH"
  exit 1
fi

# Display installer message if not already installed
if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  printf "\033[38;2;96;96;255m#######################################################################################\033[0m\n"
  printf "\033[38;2;96;96;255m#\033[0m\n"
  printf "\033[38;2;96;96;255m#                                      ARMGI9854WXZ59 INSTALLER\033[0m\n"
  printf "\033[38;2;96;96;255m#\033[0m\n"
  printf "\033[38;2;96;96;255m#                           Copyright (C) 2024, ARMGI9854WXZ59\033[0m\n"
  printf "\033[38;2;96;96;255m#\033[0m\n"
  printf "\033[38;2;96;96;255m#######################################################################################\033[0m\n"

  read -p "Do you want to install BlackArch Linux? (YES/no): " install_blackarch
fi

# Case for user input
case $install_blackarch in
  [yY][eE][sS])
    wget --tries="$max_retries" --timeout="$timeout" --no-hsts -O /tmp/rootfs.tar.xz \
      "URL_TO_YOUR_BLACKARCH_ROOTFS.XZ"
    tar -xJf /tmp/rootfs.tar.xz -C "$ROOTFS_DIR"
    ;;
  *)
    printf "\033[38;2;96;96;255mSkipping BlackArch Linux installation.\033[0m\n"
    ;;
esac

# Install proot if not already installed
if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  mkdir -p "$ROOTFS_DIR/usr/local/bin"
  wget --tries="$max_retries" --timeout="$timeout" --no-hsts -O "$ROOTFS_DIR/usr/local/bin/proot" "https://proot.gitlab.io/proot/bin/proot-x86_64"
  
  while [ ! -s "$ROOTFS_DIR/usr/local/bin/proot" ]; do
    rm -rf "$ROOTFS_DIR/usr/local/bin/proot"
    wget --tries="$max_retries" --timeout="$timeout" --no-hsts -O "$ROOTFS_DIR/usr/local/bin/proot" "https://proot.gitlab.io/proot/bin/proot-x86_64"
    
    if [ -s "$ROOTFS_DIR/usr/local/bin/proot" ]; then
      chmod 755 "$ROOTFS_DIR/usr/local/bin/proot"
      break
    fi
    sleep 1
  done

  chmod 755 "$ROOTFS_DIR/usr/local/bin/proot"
fi

# Set up DNS and cleanup if not already done
if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > "${ROOTFS_DIR}/etc/resolv.conf"
  rm -rf /tmp/rootfs.tar.xz
  touch "$ROOTFS_DIR/.installed"
fi

# Detect available shells
detect_shell() {
  if [ -e "$ROOTFS_DIR/bin/zsh" ]; then
    echo "zsh"
  elif [ -e "$ROOTFS_DIR/bin/bash" ]; then
    echo "bash"
  else
    echo "No supported shell found!"
    exit 1
  fi
}

# Ask user which shell to use
SHELL_CHOICE=$(detect_shell)
echo "Detected shell: $SHELL_CHOICE"
read -p "Which shell would you like to use? (bash/zsh): " user_shell

# Install zsh if chosen and not installed
if [ "$user_shell" = "zsh" ]; then
  if ! [ -e "$ROOTFS_DIR/bin/zsh" ]; then
    proot --rootfs="$ROOTFS_DIR" -0 -w "/root" /bin/bash -c "pacman -Syu --debug --noconfirm zsh"
  fi
fi

# Install additional packages
proot --rootfs="$ROOTFS_DIR" -0 -w "/root" /bin/bash -c "pacman -Syu --debug --noconfirm emacs nano vi vim neovim tmux dvtm screen zellij tmate asciinema"

# Define color codes
CYAN='\033[38;2;96;96;255m'
WHITE='\033[38;2;255;255;255m'
RESET_COLOR='\033[0m'

# Display completion message
display_gg() {
  printf "%s___________________________________________________%s\n" "$WHITE" "$RESET_COLOR"
  printf "\n"
  printf "           %s-----> Mission Completed ! <----%s\n" "$CYAN" "$RESET_COLOR"
}

clear
display_gg

# Run proot with specified rootfs and mount points, using the selected shell
if [ "$user_shell" = "zsh" ]; then
  SHELL_CMD="/bin/zsh"
else
  SHELL_CMD="/bin/bash"
fi

"$ROOTFS_DIR/usr/local/bin/proot" --rootfs="$ROOTFS_DIR" -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit "$SHELL_CMD"

# Cleanup /tmp/sbin if it exists
if [ -d "/tmp/sbin" ]; then
  rm -rf /tmp/sbin
fi
