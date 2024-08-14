#!/bin/bash

tdp=$(dirname `realpath "${BASH_SOURCE}"`);
tfb="${BASH_SOURCE##*/}";
tfn="${tfb%%.*}";
tfb_hlog=".tasw.log";
tfp_hlog="${HOME}/${tfb_hlog}";
ssh_operation="ssh -i ~/.ssh/rsync";

source "${tdp}/printcess/printcess.sh";

if [[ -z $TERMUX_VERSION && "$(whoami)" != 'root' ]]; then
  sudo_perm='sudo';
fi

function qyon() {
  printcess -ne "$1 <90[y/N]<2>><0 " && read choice;

  if [[ "$choice" =~ ^[Yy]([Ee][Ss])?$ ]]; then
    return 0;
  else
    return 1;
  fi
}

function fn_action() {
  sum=0;
  if ! tput civis; then echo -ne '\e[?25l'; fi;
  printcess -e '<C ▶ Scanning the WLAN ▂ ▅ █';
  while read line; do
    printcess -e "<C - $line";
  done < <(nmap -sn "$(ip a | awk '/192.168/ {print $2}')" | awk '/192.168/ {print $NF}');

  if ! tput cnorm; then echo -ne '\e[?25h'; fi;
  printcess -ne '<C Enter the IP address (v4) > ' &&
    read IPv4_address &&
      printcess -ne '<C Enter the username of the device > ' &&
	read username &&

  if ! tput civis; then echo -ne '\e[?25l'; fi &&

    [[ ! -z "$IPv4_address" ]] && while read line; do
    sum=$(($sum + 1));
    src="${line//:*/}/"; dest="${line//*:/}";

    if [ $(($sum % 2)) == 1 ]; then
      printcess -ne "<C <96 ┌ <3${src}<0>\n<C <96┌┼ <90(PULL)\n<C <96│└ <3${dest}<0>\n<C <96└ <0Synchronizing with the <1${username} device<0: ";
      rsync -au --partial -e "${ssh_operation}" "${username}@${IPv4_address}:${src}" "${dest}" &> /dev/null &&
	printcess -e '<92OK<0' ||
	  printcess -e '<91NO<0';
    else
      printcess -ne "<C <93 ┌ <3${src}<0>\n<C <93┌┼ <90(PUSH)\n<C <93│└ <3${dest}<0>\n<C <93└ <0Synchronizing with the <1${username} device<0: ";
      rsync -au --partial -e "${ssh_operation}" "${src}" "${username}@${IPv4_address}:${dest}" &> /dev/null &&
	printcess -e '<92OK<0' ||
	  printcess -e '<91NO<0';
    fi
  done < "${tdp}/${username}.paths" &&

  if ! tput cnorm; then echo -ne '\e[?25h'; fi &&

    date +'Last <92synchronization<0 %d/%m/%Y %H:%M:%S' 1> "${tfp_hlog}" &&
    rsync -au --partial -e "${ssh_operation}" "${tfp_hlog}" "${username}@${IPv4_address}:/home/${username}/${tfb_hlog}";
}

if [[ -e ${tfp_hlog} && ! -z ${tfp_hlog} ]]; then
  printcess -e "<C $(cat ${tfp_hlog})";
else
  printcess -e "<C Create a record in the following path:\n<C ‘— <96${tfp_hlog}<0" &&
    printcess -ne '<C ' &&
      printcess -e 'It does not yet <92synchronize<0 with any device.' | tee "${tfp_hlog}";
fi

if [ ! -z $TERMUX_VERSION ]; then
  qyon "<C Do you want to <96synchronize<0 with a <1device<0?" &&
    fn_action;
fi
