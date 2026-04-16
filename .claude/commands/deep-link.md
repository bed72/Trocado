# Deep Link

Abre um deep link no emulador/simulador em execução.

URL base: `trocado://app`
Argumento: path desejado (ex: `/home`, `/budget`, `/expense`)

Se nenhum argumento for passado, usa `/home` por padrão.

---

Execute o comando abaixo de acordo com a plataforma:

## Android (adb)

```bash
adb shell am start -W \
  -a android.intent.action.VIEW \
  -d "trocado://app${ARGUMENTS:-/home}" \
  br.com.bed.trocado
```

## iOS (Simulator)

```bash
xcrun simctl openurl booted "trocado://app${ARGUMENTS:-/home}"
```

---

Detecta automaticamente a plataforma disponível e executa o comando correto:

```bash
if adb devices | grep -q "device$"; then
  adb shell am start -W \
    -a android.intent.action.VIEW \
    -d "trocado://app${ARGUMENTS:-/home}" \
    br.com.bed.trocado
elif xcrun simctl list devices | grep -q "Booted"; then
  xcrun simctl openurl booted "trocado://app${ARGUMENTS:-/home}"
else
  echo "Nenhum dispositivo/simulador encontrado."
fi
```
