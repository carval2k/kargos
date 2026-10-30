#!/bin/bash
PRG=$(basename "${0}" .sh)
VERSION="20260410"
AUTHOR="cgvalente@gmail.com"

# quit if already running...
[[ "${1}" = "--taskbar" && $(pgrep -c -f "${0} --taskbar" 2>/dev/null) -gt 2 ]] && exit

# some needed variables...
aLABELS=$(cat $(dirname ${0})/${PRG}.labels 2>/dev/null) # use fLABELS content to fix sensor label name (usually on HP shits)
SENSORS=""
NVsmi=$(command -v nvidia-smi)
SMctl=$(command -v smartctl)
SPACE="&nbsp;"
C="°"

# check for existence of a webcam running
dummy="$(fuser /dev/video? 2>/dev/null)"
if [ -z "${dummy}" ]; then
   lWC=""
   vWC=""
   WCAM="Webcam: OFF"
else
   lWC="${SPACE}Webcam${SPACE}"
   vWC="${SPACE}IN${SPACE}USE${SPACE}"
   WCAM="Webcam: pids ${dummy}"
fi

# get available RAM
while IFS=' ' read -r _k dummy _u; do [[ "${_k}" = "MemAvailable:" ]] && break; done < /proc/meminfo
lRAM="Memory"
vRAM=$(awk -v kb="${dummy}" 'BEGIN { printf "%.1f", kb/1048576 }')
vRAM="${vRAM//./','}G"
RAM="${lRAM}: ${vRAM}"
printf -v vRAM "%6s" "${vRAM}"
vRAM=$(echo "${vRAM}" | sed "s/ /\\${SPACE}/g")

# collect all sensors data
get_sensors()
{
for gsS in /sys/class/hwmon/hwmon*/temp*_input
do
  if [ -r "${gsS}" ]; then
     read -r gsT < ${gsS}
     gsB="${gsS%/*}"
     gsF="${gsS%_*}"
     gsF="${gsF##*/}"
     read -r gsN < ${gsB}/name
     gsL=${gsS%_input}_label
     if [ -r ${gsL} ]; then
        read -r gsL < ${gsL}
     else
        gsL=$(ls ${gsB}/device/block 2>/dev/null)
     fi
     [[ -n "${gsL}" ]] && gsN="${gsN} ${gsL}"
     [[ "${gsN}" = "acpitz" ]] && gsN="${gsN}_${gsF}"
     [[ "${gsN:0:14}" = "coretemp Core " ]] && gsN=""
     if [ -n "${gsN}" -a "${gsT:-0}" != "0" ]; then
        dummy="${gsN}:${gsT}"
        echo "${dummy// /_}"
     fi
  fi
done
if [ -n "${NVsmi}" ]; then
   gsT=$(${NVsmi} --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null)
   echo "nvidia:$((${gsT} * 1000))"
fi
}

if [ "${1}" = "--debug" ]; then
   get_sensors
   exit 0
fi

# if $1 exists on aLABELS replace them...
conv_label()
{
[[ -n "${aLABELS}" ]] && cL=$(echo "${aLABELS}" | grep "^${1}=" | cut -d'=' -f2)
[[ -z "${cL}" ]] && cL=${1}
echo "${cL}"
}

# convert miledegree to celcius
md_to_C()
{
printf "%.0f" "$((${1}/1000))"
}

aSENSORS=$(get_sensors | sort -V)
for D in $(echo "${aSENSORS}")
do
  L=$(conv_label "${D%:*}")
  T=${D#*:}
  [[ -n "${L}" && -n "${T}" ]] && SENSORS="${SENSORS}\n${L#*_}:$(md_to_C ${T})${C}"
done

# check for external disk temperatures
if [ -n "${SMctl}" ]; then
   while IFS=' ' read -r ED _rest
   do
     D=$(echo "${ED}" | tr -d '[:digit:]')
     T=$(sudo -n ${SMctl} -a "/dev/${D}" 2>/dev/null | grep 'Temperature_Celsius' | tr -s ' ' | rev | cut -d' ' -f3 | rev)
     T="${T:-0}"
     [[ "${T}" =~ ^[0-9]+$ && "${T}" -gt 0 ]] && SENSORS="${SENSORS}\n${D}:${T}${C}"
   done < <(lsblk --noheadings --raw 2>/dev/null | grep media | tr -s ' ')
fi

# check for firewall (UFW) state
dummy=$([[ $(sudo -n /usr/sbin/ufw status 2>/dev/null | grep -c ": active") -eq 1 ]] && echo run || echo OFF)
if [ "${dummy}" = "run" ]; then
   lUFW="UFW"
   vUFW="${dummy}"
   UFW="Firewall: ${dummy}"
else
   lUFW=""
   vUFW=""
   UFW=""
fi

# clean empty lines from SENSORS...
SENSORS=$(echo -e "${SENSORS}" | grep -v '^$' | sort -V)

# show result (arrange it if for taskbar)
if [ "${1}" = "--taskbar" ]; then
   LBL="${lWC}${SPACE}${lRAM}"
   VAL="${vWC}${SPACE}${vRAM}"
   while IFS= read -r D
   do
     if [ -n "${D}" ]; then
        L="${D%%:*}"
        d="${D#*:}"
        d="${d%${C}}"
        V=$(LC_NUMERIC=C printf "%.0f" "${d}" 2>/dev/null || echo "?")
        LBL="${LBL}${SPACE}${L}"
        VAL="${VAL}${SPACE}${V}${C}"
     fi
   done < <(printf '%b\n' "${SENSORS}")
   LBL="${LBL}${SPACE}${lUFW}"
   VAL="${VAL}${SPACE}${vUFW}"
   echo "<br><font size='1'>${LBL}<br><font size='1'>${VAL} | font='Ubuntu Mono' size='12'"
else
   echo "${WCAM}"
   echo "${RAM}"
   printf '%b\n' "${SENSORS}" | sed -r 's/:/: /g' | sed -r 's/\./,/g'
   [[ -n "${UFW}" ]] && echo "${UFW}"
fi
