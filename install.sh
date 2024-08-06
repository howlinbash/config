#!/bin/bash

padding() {
  printf '%*s\n' "$1" | tr ' ' '-'
}

line() {
  NC='\033[0m' # No Color
  EDGE=$(padding 47)
  GREEN='\033[1;32m'
  echo -e "${GREEN}+${EDGE}+${NC}"
}

heading() {
  MAX_LENGTH=33
  MESSAGE=$1

  PX=$(($MAX_LENGTH - ${#MESSAGE}))
  IS_ODD=$(($PX % 2 == 1))
  LX=$(($PX / 2))
  RX=$(( IS_ODD ? $PX / 2 + 1 : $PX / 2))

  EDGE=$(padding 47)
  LEFT=$(padding $LX)
  RIGHT=$(padding $RX)

  CYAN='\033[1;36m'
  NC='\033[0m' # No Color
  WARNING="${CYAN}/${NC}!${CYAN}\\"

  echo ""
  line
  echo -e " ${WARNING} ${NC}${LEFT}|  ${CYAN}${MESSAGE^^}${NC}  |${RIGHT}${GREEN} ${WARNING}"
  line
  echo -e "${NC}"
}

get_password() {
  echo "Enter your root password:"
  read -s PASSWD
  echo "Confirm it"
  read -s PASSWD2

  if [ "$PASSWD" != "$PASSWD2" ]; then
    echo "Passwords don't match. Please try again."
    get_password
  fi
}

get_passphrase() {
  echo "Enter your root passphrase:"
  read -s PHRASE
  echo "Confirm it"
  read -s PHRASE2

  if [ "$PHRASE" != "$PHRASE2" ]; then
    echo "Passphrase don't match. Please try again."
    get_passphrase
  fi
}

continue_prompt() {
  echo ""
  echo "Do you want to continue?"
  read
  echo ""
}


heading 'Greetings Nerd'
get_password
get_passphrase


heading 'Home Directories'
mkdir -p src builds corkboard gits sandbox tmp Pictures/screenshots

line
echo "src:           $(basename src)"
echo "builds:        $(basename builds)"
echo "corkboard:     $(basename corkboard)"
echo "gits:          $(basename gits)"
echo "sandbox:       $(basename sandbox)"
echo "tmp:           $(basename tmp)"
echo "screenshots:   $(basename Pictures/screenshots)"
continue_prompt


heading 'Dotfiles'
git clone https://github.com/howlinbash/dotfiles
shopt -s dotglob
mv -f dotfiles/.config/gtk-3.0/* ~/.config/gtk-3.0/
rm -rf dotfiles/.config/gtk-3.0
mv dotfiles/.config/* ~/.config/
rm -rf dotfiles/.config
mv dotfiles/.local/* ~/.local/
rm -rf dotfiles/.local
mv dotfiles/* ~/
rm -rf dotfiles

echo ""
line
echo ".bash_aliases: $(basename .bash_aliases)"
echo ".bash_profile: $(basename .bash_profile)"
echo ".bashrc:       $(basename .bashrc)"
echo ".gitconfig:    $(basename .gitconfig)"
echo ".gitignore:    $(basename .gitignore)"
echo ""
echo ".bashrc.d:"
ls .bashrc.d
echo ""
echo ".config:"
ls .config
echo ""
echo ".local:"
ls .local
echo ""
echo ".notes:"
ls .notes
echo ""
echo ".ssh:"
ls .ssh

# symlinks
ln -s ~/.config/__assets__/wallpaper ~/Pictures/wallpaper
echo ""
echo "wallpaper:"
ls ~/Pictures/wallpaper

# Remove url gh from gitconfig (will be added back later)
tac .gitconfig | sed '1,2d' | tac > temp && mv temp .gitconfig
echo ""
echo ".gitconfig:"
cat .gitconfig
line
continue_prompt


heading 'Yay'
# Make Yay pacman wrapper
cd ~/builds
curl -O https://aur.archlinux.org/cgit/aur.git/snapshot/yay.tar.gz
tar -xvf yay.tar.gz
cd yay
makepkg -sri
cd
continue_prompt


heading 'Packages'
echo "$PASSWD" | sudo -S pacman -Syu --noconfirm 
echo "$PASSWD" | sudo -S yay -S --noconfirm $(cat .notes/pkglist.txt)
continue_prompt


heading 'Inputrc'
echo "$PASSWD" | sudo -S tee -a /etc/inputrc > /dev/null <<EOF

# My input settings controls
set editing-mode vi
set keymap vi-command
set show-all-if-ambiguous on
set completion-ignore-case on
EOF

cat /etc/inputrc | tail
continue_prompt


heading 'Keyboard Settings'
echo "$PASSWD" | sudo -S localectl set-x11-keymap us,fi pc105 "" grp:alt_shift_toggle,caps:swapescape > /dev/null
echo "$PASSWD" | sudo -S sed -i 's/^KEYMAP.*/KEYMAP=us/' /etc/vconsole.conf > /dev/null
echo "$PASSWD" | sudo -S sed -i 's/^XKBLAYOUT.*/XKBLAYOUT="us"/' /etc/default/keyboard  > /dev/null
echo "$PASSWD" | sudo -S sed -i 's/^XKBOPTIONS.*/XKBOPTIONS="caps:swapescape"/' /etc/default/keyboard  > /dev/null
cat /etc/vconsole.conf
echo ""
cat /etc/default/keyboard
continue_prompt


mkdir -p ~/.config/ranger/plugins
git clone https://github.com/alexanderjeurissen/ranger_devicons ~/.config/ranger/plugins/ranger_devicons
continue_prompt


heading 'Firefox'
cd ~/.mozilla/firefox/*.default-release
rm -rf chrome 
ln -s ~/.config/__assets__/firefox/chrome chrome
echo "chrome:"
ls chrome
cd
continue_prompt


heading 'Firefox Add-ons'
mkdir extensions
cd extensions
curl -L https://addons.mozilla.org/firefox/downloads/file/4086892/ublock_origin-1.48.0.xpi > ublock.xpi
curl -L https://addons.mozilla.org/firefox/downloads/file/4064595/privacy_badger17-2023.1.31.xpi > badger.xpi
curl -L https://addons.mozilla.org/firefox/downloads/file/4040280/react_devtools-4.27.1.xpi > react.xpi
curl -L https://addons.mozilla.org/firefox/downloads/file/4047244/reddit_enhancement_suite-5.22.15.xpi > reddit.xpi
curl -L https://addons.mozilla.org/firefox/downloads/file/4079806/reduxdevtools-3.0.19.xpi > redux.xpi
firefox ublock.xpi
firefox badger.xpi
firefox react.xpi
firefox reddit.xpi
firefox redux.xpi
cd
rm -rf extensions
continue_prompt


heading 'SSH'
echo "$PASSWD" | sudo -S systemctl start sshd.service
echo "$PASSWD" | sudo -S systemctl enable sshd.service
echo "$PASSWD" | sudo -S systemctl status sshd.service
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_git -C rogers -P $PHRASE
continue_prompt


heading 'Single Sudo'
echo "$PASSWD" | sudo -S touch /etc/sudoers.d/00_prompt_once
ls /etc/sudoers.d
echo "$PASSWD" | sudo -S tee -a /etc/sudoers.d/00_prompt_once > /dev/null <<EOF

## Only ask for the password once for all TTYs per reboot.
## See https://askubuntu.com/a/1278937/367284 and
##     https://github.com/hopeseekr/BashScripts/
Defaults !tty_tickets
Defaults timestamp_timeout = -1
EOF
cat /etc/sudoers.d/00_prompt_once
continue_prompt

xclip -sel c ~/.ssh/id_rsa_git.pub

heading 'NEXT'
echo ""
echo " - Add key to github"
echo " - Open nvim 2 times"
echo " - Run next.sh"
echo ""
echo ""
