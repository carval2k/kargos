- What is kargos.sh?
Is a simple bash script used to feed kargos widget on KDE plasma with hardware sensors and some other useful indicators

- How to use it?
Place "kargos.sh" and "kargos.labels" on a directory of your preference (such as /opt/utils) and ensure it is executable.
You should correct "kargos.labels" based on your hardware (use "./kargos.sh --debug" to list what it founds)

- Requirements:
Nothing special, just pure bash commands, such as awk, grep, lsblk, etc..
Optionally "nvidia-smi" and "smartctl"
2 sudo rights:
ALL ALL=(root) NOPASSWD: /usr/sbin/ufw status
ALL ALL=(root) NOPASSWD: /usr/sbin/smartctl -a /dev/*

- Install/Add widget to your KDE Plasma from (https://store.kde.org/p/1173112/)
- Add it to your taskbar, go to configure, General it with:
   Command line.......: /opt/utils/kargos.sh --taskbar
   Interval in seconds: 3 (sugestion)
   Rotation delay.....: 5 (sugestion)

kargos.sh can also be used on shell:
$ ./kargos.sh 
Webcam: OFF
Memory: 24,8G
CPU: 35°
MBd: 27°
nvm: 33°
sda: 31°
sdb: 38°
sdc: 41°
sdd: 38°
Firewall: run
