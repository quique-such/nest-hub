# Nest Hub Screen

Una pantalla para el Google Nest Hub que se envía desde un Mac: hora, tiempo, calendario de iCloud, aviso de lluvia, próxima alarma y un fondo que sigue el color del cielo a lo largo del día.

- **Cielo que sigue al sol:** el fondo pasa por amanecer, día, atardecer y noche con las horas reales de salida y puesta de sol de tu ciudad.
- **Modo noche:** reloj ámbar tenue para no molestar al dormir.
- **Modo despertar:** 30 minutos antes de una alarma, un amanecer artificial y "Buenos días".
- **Calendario del iPhone:** se lee de la app Calendario del Mac (cualquier cuenta sincronizada, iCloud incluida), sin publicar ningún enlace.
- **Aviso de lluvia** en las próximas 12 horas y previsión por horas ([Open-Meteo](https://open-meteo.com), sin clave).
- **No molesta:** si el Nest Hub está con Spotify, YouTube o una alarma, no se toca. La pantalla vuelve sola cuando lleva unos minutos en reposo.

## Requisitos

- macOS con las herramientas de línea de comandos de Xcode (`xcode-select --install`).
- [catt](https://github.com/skorokithakis/catt): `brew install pipx && pipx install catt`.
- El Mac y el Nest Hub en la misma red. El Mac tiene que estar encendido: la página se sirve desde él.

## Instalación

```sh
git clone https://github.com/quique-such/nest-hub.git
cd nest-hub
cp config.example.json config.json   # y edítalo
./instalar.sh
```

La primera vez, macOS pedirá permiso para leer Calendario y para buscar dispositivos en la red local. Hay que aceptar los dos.

Para quitarlo: `./instalar.sh --quitar`.

## Configuración (`config.json`)

| Campo | Para qué |
|---|---|
| `nombre` | El saludo del modo despertar. |
| `ciudad` | Coordenadas y zona horaria para el tiempo y las horas de sol. |
| `nest_hub` | Nombre del Nest Hub tal como sale en Google Home. Se busca por nombre, así que da igual si cambia de IP. |
| `modo_noche` | Horas de inicio y fin del modo noche. |
| `alarmas` | Las alarmas del Nest Hub. Google no deja leerlas desde fuera, así que se apuntan aquí. `dias`: 0 = domingo … 6 = sábado. |
| `reposo_minutos` | Minutos en reposo antes de volver a poner la pantalla. |

## Cómo funciona

- `index.html`: la pantalla. Corre en el propio Nest Hub y pide el tiempo directamente a Open-Meteo.
- `src/calendario.swift`: exporta los eventos de hoy y mañana de Calendario a `eventos.json`.
- `guardian.sh`: cada 5 minutos actualiza el calendario. Cada minuto mira qué muestra el Nest Hub y, si lleva `reposo_minutos` en reposo, le vuelve a enviar la pantalla con `catt cast_site`.
- `src/guardian-launcher.swift`: arranca `guardian.sh` para que macOS atribuya los permisos de Red local y Calendario a un programa con nombre propio. Si lo recompilas, macOS vuelve a pedir el permiso.
- `instalar.sh`: compila los programas y crea dos servicios de launchd, el servidor web (puerto 8765) y el guardián.

## Limitaciones

- El Nest Hub no deja tocar las páginas que se le envían: la pantalla es solo para mirar.
- Si el Mac se duerme, la página sigue en pantalla con la hora y el tiempo, pero el calendario no se actualiza y la pantalla no vuelve si sales de ella.
