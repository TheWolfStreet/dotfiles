pkgs:
pkgs.writeShellScript "touchpad" ''
  hyprctl keyword device:a true > /dev/null 2>&1

  dev_name="$(hyprctl devices | grep touchpad | sed '/2-synaptics-touchpad/d; s/.*	//')"
  dev_state_field="device[''${dev_name}]:enabled"
  dev_state="hyprctl keyword device:''${dev_name}:enabled"

  if [ -z "$XDG_RUNTIME_DIR" ]; then
    export XDG_RUNTIME_DIR=/run/user/$(id -u)
  fi

  STATUS_FILE="$XDG_RUNTIME_DIR/touchpad.status"

  if [ -f "$STATUS_FILE" ]; then
    dev_state="$(cat "$STATUS_FILE")"
  fi

  if [ "$dev_state" != "false" ]; then
    dev_state="false"
    hyprctl --batch -r -- keyword "$dev_state_field" $dev_state || export dev_state="true"
  else
    dev_state="true"
    hyprctl --batch -r -- keyword "$dev_state_field" $dev_state || export dev_state="false"
  fi

  echo "$dev_state" > "$STATUS_FILE"
''
