#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2022-present Joshua L (https://github.com/Langerz82)

# Source predefined functions and variables
. /etc/profile

# Configure ADVMAME players based on ES settings
CONFIG_DIR="/storage/.advance"
CONFIG="${CONFIG_DIR}/advmame.rc"
ES_FEATURES="/storage/.config/emulationstation/es_features.cfg"

#source /storage/common.sh "advmame"
source /usr/bin/joy_common.sh "advmame"

ROMNAME=$1


BTN_CFG="0 1 2 3 4 5 6 7"

BTN_H0=$(advj | grep -B 1 -E "^joy 0 .*" | grep sticks: | sed "s|sticks:\ ||")

declare -A ADVMAME_VALUES=(
  ["b0"]="button1"
  ["b1"]="button2"
  ["b2"]="button3"
  ["b3"]="button4"
  ["b4"]="button5"
  ["b5"]="button6"
  ["b6"]="button7"
  ["b7"]="button8"
  ["b8"]="button9"
  ["b9"]="button10"
  ["b10"]="button11"
  ["b11"]="button12"
  ["b12"]="button13"
  ["b13"]="button14"
  ["b14"]="button15"
  ["b15"]="button16"
  ["b16"]="button17"
  ["b17"]="button18"
  ["h0.1"]="stick$BTN_H0,y,up"
  ["h0.4"]="stick$BTN_H0,y,down"
  ["h0.8"]="stick$BTN_H0,x,left"
  ["h0.2"]="stick$BTN_H0,x,right"  
  ["a0,1"]="stick,y,up"
  ["a0,2"]="stick,y,down"
  ["a1,1"]="stick,x,left"
  ["a1,2"]="stick,x,right"
  ["a2,1"]="1,0,0"
  ["a2,2"]="1,0,1"
  ["a5,1"]="2,1,0"
  ["a5,2"]="2,1,1"  
)

declare GC_ORDER=(
  "a"
  "b"
  "x"
  "y"
  "rightshoulder"
  "leftshoulder"
  "righttrigger"
  "lefttrigger"
)

declare -A GC_NAMES=()

get_button_cfg() {
	local BTN_INDEX=$(get_ee_setting "joy_btn_cfg" "mame" "${ROMNAME}")
  [[ -z $BTN_INDEX ]] && BTN_INDEX=$(get_ee_setting "mame.joy_btn_cfg")

  if [[ ! -z $BTN_INDEX ]] && [[ $BTN_INDEX -gt 0 ]]; then
		local BTN_SETTING="AdvanceMame.joy_btn_order$BTN_INDEX"
    local BTN_CFG_TMP="$(get_ee_setting $BTN_SETTING)"
		[[ ! -z $BTN_CFG_TMP ]] && BTN_CFG="${BTN_CFG_TMP}"
	fi
	echo "$BTN_CFG"
}


clean_pad() {
	sed -i "/device_joystick.*/d" ${CONFIG}
	sed -i "/input_map\[p${1}_.*/d" ${CONFIG}
	sed -i "/input_map\[coin${1}.*/d" ${CONFIG}
	sed -i "/input_map\[start${1}.*/d" ${CONFIG}

  if [[ "${1}" == "1" ]]; then
    sed -i '/input_map\[ui_[[:alpha:]]*\].*/d' ${CONFIG}
  fi
	echo "device_joystick raw" >> ${CONFIG}
}


# Sets pad depending on parameters $GAMEPAD = name $1 = player
set_pad(){
  local P_INDEX=$(( $1 - 1 ))
  local DEVICE_GUID=$3
  local JOY_NAME="$4"

  local GC_CONFIG=$(cat "$GCDB" | grep "$DEVICE_GUID" | grep "platform:Linux" | head -1)
  echo "GC_CONFIG=$GC_CONFIG"
  [[ -z $GC_CONFIG ]] && return

  [[ -z "$JOY_NAME" ]] && JOY_NAME=$(echo $GC_CONFIG | cut -d',' -f2)
  [[ -z "$JOY_NAME" ]] && return

  local GAMEPAD=$(echo "$JOY_NAME" | sed "s|,||g" | sed "s|_||g" | cut -d'"' -f 2 \
    | sed "s|(||" | sed "s|)||" | sed -e 's/[^A-Za-z0-9._-]/ /g' | sed 's/[[:blank:]]*$//' \
    | sed 's/-//' | sed -e 's/[^A-Za-z0-9._-]/_/g' |tr '[:upper:]' '[:lower:]' | tr -d '.')

  if [[ "${P_INDEX}" -gt "0" ]]; then
    BTN_H0=$(advj | grep -B 1 -E "^joy ${P_INDEX} .*" | grep sticks: | sed "s|sticks:\ ||")
    if [[ ! -z "$BTN_H0" ]]; then
      ADVMAME_VALUES["h0.1"]="stick$BTN_H0,y,up"
      ADVMAME_VALUES["h0.4"]="stick$BTN_H0,y,down"
      ADVMAME_VALUES["h0.8"]="stick$BTN_H0,x,left"
      ADVMAME_VALUES["h0.2"]="stick$BTN_H0,x,right"
    fi
  fi

  local NAME_NUM="${GC_NAMES[$GAMEPAD]}"
  if [[ -z "NAME_NUM" ]]; then
    GC_NAMES[$GAMEPAD]=1
  else
    GC_NAMES[$GAMEPAD]=$(( NAME_NUM+1 ))
  fi
	[[ "${GC_NAMES[$GAMEPAD]}" -gt "1" ]] && GAMEPAD="${GAMEPAD}_${GC_NAMES[$GAMEPAD]}"

  local GC_MAP=$(echo $GC_CONFIG | cut -d',' -f3-)

  declare DIRS=()
  declare -A DIR_INDEX=(
    [dpup]="0"
    [dpdown]="1"
    [dpleft]="2"
    [dpright]="3"
    [leftx]="0,1"
    [lefty]="2,3"
  )
  local ADD_HAT=$(get_ee_setting advmame_add_hat)
  local i=1
  set -f
  local GC_ARRAY=(${GC_MAP//,/ })
  declare -A GC_ASSOC=()
  for index in "${!GC_ARRAY[@]}"
  do
      local REC=${GC_ARRAY[$index]}
      local GC_INDEX=$(echo $REC | cut -d ":" -f 1)
      [[ $GC_INDEX == "" || $GC_INDEX == "platform" ]] && continue

      local TVAL=$(echo $REC | cut -d ":" -f 2)
      GC_ASSOC["$GC_INDEX"]=$TVAL

      [[ " ${GC_ORDER[*]} " == *" ${GC_INDEX} "* ]] && continue
      local BUTTON_VAL=${TVAL:1}
      local BTN_TYPE=${TVAL:0:1}
      local VAL="${ADVMAME_VALUES[${TVAL}]}"
      local I="${DIR_INDEX[$GC_INDEX]}"
      local DIR="${DIRS[$I]}"

      # Create Axis Maps
      case $GC_INDEX in
        dpup|dpdown|dpleft|dpright)
          [[ ! -z "$DIR" ]] && DIR+=" or "
          [[ "$BTN_TYPE" == "b" ]] && DIR+="joystick_button[${GAMEPAD},${VAL}]"
          [[ "$BTN_TYPE" == "h" ]] && DIR+="joystick_digital[${GAMEPAD},${VAL}]"
          DIRS["$I"]="$DIR"
          ;;
        leftx|lefty)
          for i in {1..2}; do
            I=$(echo "${DIR_INDEX[$GC_INDEX]}" | cut -d, -f "$i")
            DIR="${DIRS[$I]}"
            [[ ! -z "$DIR" ]] && DIR+=" or "
            VAL="${ADVMAME_VALUES[${TVAL},${i}]}"
            DIR+="joystick_digital[${GAMEPAD},${VAL}]"
            DIRS["$I"]=$DIR
          done
          ;;
        start)
          echo "input_map[start${1}] joystick_button[${GAMEPAD},${VAL}]" >> ${CONFIG}
          ;;
        back)
          echo "input_map[coin${1}] joystick_button[${GAMEPAD},${VAL}]" >> ${CONFIG}
          ;;
      esac
  done

  declare -i i=1
  for bi in ${BTN_CFG}; do
    local button="${GC_ORDER[$bi]}"
    [[ -z "$button" ]] && continue
    button="${GC_ASSOC[$button]}"
    
    local BTN_TYPE="${button:0:1}"
    if [[ "$BTN_TYPE" == "a" ]]; then
      local STR="input_map[p${1}_button${i}]"
      for j in {1..2}; do
        local VAL="${ADVMAME_VALUES[${button},${j}]}"
        STR+=" joystick_digital[${GAMEPAD},${VAL}]"
      done
      echo "${STR}" >> ${CONFIG}
    elif [[ "$BTN_TYPE" == "b" ]]; then
      local VAL="${ADVMAME_VALUES[$button]}"
      echo "input_map[p${1}_button${i}] joystick_button[${GAMEPAD},${VAL}]" >> ${CONFIG}
    fi
    (( i++ ))
  done

  echo "input_map[p${1}_up] ${DIRS[0]}" >> ${CONFIG}
  echo "input_map[p${1}_down] ${DIRS[1]}" >> ${CONFIG}
  echo "input_map[p${1}_left] ${DIRS[2]}" >> ${CONFIG}
  echo "input_map[p${1}_right] ${DIRS[3]}" >> ${CONFIG}

  # Menu should only be set to player 1
  if [[ "${1}" == "1" ]]; then
  #echo "Setting menu buttons for player 1" #debug
    echo "input_map[ui_up] ${DIRS[0]}" >> ${CONFIG}
    echo "input_map[ui_down] ${DIRS[1]}" >> ${CONFIG}
    echo "input_map[ui_left] ${DIRS[2]}" >> ${CONFIG}
    echo "input_map[ui_right] ${DIRS[3]}" >> ${CONFIG}

    local button="${GC_ASSOC[a]}"
    local VAL="${ADVMAME_VALUES[$button]}"
    if [ ! -z "$VAL" ]; then
      echo "input_map[ui_select] keyboard[0,enter] or keyboard[1,enter] or joystick_button[${GAMEPAD},${VAL}]" >> ${CONFIG}
    fi
    button="${GC_ASSOC[leftstick]}"
    VAL="${ADVMAME_VALUES[$button]}"
    if [ ! -z "$VAL" ]; then
      echo "input_map[ui_cancel] keyboard[0,backspace] or keyboard[1,backspace] or joystick_button[${GAMEPAD},${VAL}]" >> ${CONFIG}
    fi
    button="${GC_ASSOC[rightstick]}"
    VAL="${ADVMAME_VALUES[$button]}"
    if [ ! -z "$VAL" ]; then
      echo "input_map[ui_configure] keyboard[1,tab] or keyboard[0,tab] or joystick_button[${GAMEPAD},${VAL}]" >> ${CONFIG}
    fi
  fi
}

ADVMAME_REGEX="<emulator.*name\=\"AdvanceMame\" +features\=.*[ ,\"]joybtnremap[ ,\"].*/>"
ADVMAME_REMAP=$(cat "${ES_FEATURES}" | grep -E "$ADVMAME_REGEX")
[[ ! -z "$ADVMAME_REMAP" ]] && BTN_CFG=$(get_button_cfg)
echo "BTN_CFG=$BTN_CFG"

jc_get_players
