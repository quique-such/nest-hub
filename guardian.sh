#!/bin/zsh
# Mantiene la pantalla en el Nest Hub.
# - Cada 5 min exporta el calendario a eventos.json.
# - Cada minuto mira qué muestra el Nest Hub y, solo si lleva REPOSO_MIN
#   minutos en reposo (Backdrop / nada), le vuelve a enviar la página.
#   Si suena Spotify, YouTube o una alarma, no lo toca.
# - El Nest Hub se busca por su nombre (config.json → nest_hub); la IP se
#   guarda y se vuelve a buscar sola si deja de responder.

DIR="${0:A:h}"
CONFIG="$DIR/config.json"
CATT="$HOME/.local/bin/catt"
NOMBRE=$(plutil -extract nest_hub raw "$CONFIG")
REPOSO_MIN=$(plutil -extract reposo_minutos raw "$CONFIG" 2>/dev/null || print 3)
NEST=""
reposo=$REPOSO_MIN   # al arrancar, se envía en el primer ciclo

log() { print -r -- "$(date '+%F %T') $*" }

# Busca la IP del Nest Hub por su nombre en la red local
buscar_nest() {
  local ip=$("$CATT" scan 2>/dev/null | awk -F' - ' -v n="$NOMBRE" '$2 == n { print $1; exit }')
  if [[ -n "$ip" ]]; then
    [[ "$ip" != "$NEST" ]] && log "\"$NOMBRE\" encontrado en $ip"
    NEST="$ip"
  else
    log "no encuentro \"$NOMBRE\" en la red"
  fi
}

buscar_nest

i=0
while true; do
  if (( i % 5 == 0 )); then
    if "$DIR/calendario" > "$DIR/eventos.tmp" 2>>"$DIR/guardian.err"; then
      mv "$DIR/eventos.tmp" "$DIR/eventos.json"
    else
      log "no se pudo leer Calendario"
    fi
  fi

  [[ -z "$NEST" ]] && buscar_nest
  info=""
  [[ -n "$NEST" ]] && info=$("$CATT" -d "$NEST" info 2>&1)
  app=$(print -r -- "$info" | awk -F': ' '/^display_name:/{print $2}')
  if [[ -z "$app" ]]; then
    # Sin respuesta: puede que el router le haya dado otra IP
    log "sin respuesta de ${NEST:-$NOMBRE}: $(print -r -- "$info" | tail -1)"
    buscar_nest
    [[ -n "$NEST" ]] && info=$("$CATT" -d "$NEST" info 2>&1)
    app=$(print -r -- "$info" | awk -F': ' '/^display_name:/{print $2}')
  fi

  if [[ -z "$app" ]]; then
    reposo=0   # apagado o fuera de la red: no se cuenta como reposo
  elif [[ "$app" == "Backdrop" || "$app" == "None" ]]; then
    (( reposo++ ))
  else
    reposo=0
  fi

  if (( reposo >= REPOSO_MIN )); then
    reposo=0
    URL="http://$(ipconfig getifaddr en0):8765/"
    log "Nest Hub en reposo ($app), envío la pantalla a $URL"
    # El primer envío a veces caduca mientras DashCast arranca y se queda en
    # "waiting for address": se reintenta con la app ya abierta y, si aun así
    # falla, se cierra para que el siguiente ciclo empiece limpio.
    if ! "$CATT" -d "$NEST" cast_site "$URL" >/dev/null 2>&1; then
      log "falló el envío, reintento"
      sleep 5
      if ! "$CATT" -d "$NEST" cast_site "$URL" >/dev/null 2>&1; then
        log "falló el reintento, cierro DashCast"
        "$CATT" -d "$NEST" stop >/dev/null 2>&1
      fi
    fi
  fi

  (( i++ ))
  sleep 60
done
