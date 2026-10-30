#!/bin/zsh
# Instala (o reinstala) los dos servicios: el servidor web de la pantalla y
# el guardián. Uso: ./instalar.sh      Para quitarlos: ./instalar.sh --quitar
set -e
DIR="${0:A:h}"
LA="$HOME/Library/LaunchAgents"
UID_GUI="gui/$(id -u)"
SERVICIOS=(servidor guardian)

for s in $SERVICIOS; do
  launchctl bootout "$UID_GUI/com.nesthub.$s" 2>/dev/null || true
done

if [[ "$1" == "--quitar" ]]; then
  rm -f "$LA"/com.nesthub.*.plist
  print "Servicios quitados."
  exit 0
fi

[[ -f "$DIR/config.json" ]] || { print "Falta config.json: copia config.example.json y edítalo."; exit 1; }
command -v "$HOME/.local/bin/catt" >/dev/null || { print "Falta catt: brew install pipx && pipx install catt"; exit 1; }

# Compila los programas solo si no existen. Recompilar el lanzador hace que
# macOS vuelva a pedir el permiso de Red local.
cd "$DIR/src"
[[ -x "$DIR/calendario" ]] || swiftc -O calendario.swift -o "$DIR/calendario" \
  -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist -Xlinker Info.plist
if [[ ! -x "$DIR/guardian-launcher" ]]; then
  swiftc -O guardian-launcher.swift -o "$DIR/guardian-launcher" \
    -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist -Xlinker Guardian-Info.plist
  codesign -s - -f -i com.nesthub.guardian "$DIR/guardian-launcher"
fi

mkdir -p "$LA"
cat > "$LA/com.nesthub.servidor.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.nesthub.servidor</string>
  <key>ProgramArguments</key><array><string>$(command -v python3)</string><string>-m</string><string>http.server</string><string>8765</string><string>--bind</string><string>0.0.0.0</string></array>
  <key>WorkingDirectory</key><string>$DIR</string>
  <key>RunAtLoad</key><true/><key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>/dev/null</string>
  <key>StandardErrorPath</key><string>/dev/null</string>
</dict></plist>
EOF
cat > "$LA/com.nesthub.guardian.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.nesthub.guardian</string>
  <key>ProgramArguments</key><array><string>$DIR/guardian-launcher</string></array>
  <key>RunAtLoad</key><true/><key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>$DIR/guardian.log</string>
  <key>StandardErrorPath</key><string>$DIR/guardian.log</string>
</dict></plist>
EOF

for s in $SERVICIOS; do
  launchctl bootstrap "$UID_GUI" "$LA/com.nesthub.$s.plist"
done
print "Servicios instalados. La primera vez, macOS pedirá permiso de Calendario y de Red local."
