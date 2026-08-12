---
description: Open a Trocado deep link on the running Android emulator or iOS simulator.
agent: build
---

# Deep Link

Open a deep link in the running emulator or simulator.

The base URL is `trocado://app`. Use the requested path from `$ARGUMENTS`; if it is empty, use `/home`.

Run the following detection script exactly, replacing `$ARGUMENTS` with the command argument:

```bash
LINK_PATH="$ARGUMENTS"
if [ -z "$LINK_PATH" ]; then
  LINK_PATH="/home"
fi

if adb devices | grep -q "device$"; then
  adb shell am start -W \
    -a android.intent.action.VIEW \
    -d "trocado://app${LINK_PATH}" \
    br.com.bed.trocado
elif xcrun simctl list devices | grep -q "Booted"; then
  xcrun simctl openurl booted "trocado://app${LINK_PATH}"
else
  printf '%s\n' "Nenhum dispositivo/simulador encontrado."
fi
```
