"""Servidor web de la pantalla.

Igual que `python3 -m http.server`, pero pide al Nest Hub que no guarde
copias de los archivos: así cada carga trae la última versión de la página,
la configuración y el calendario.
"""
import http.server
import os
import sys


class SinCache(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


if __name__ == "__main__":
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8765
    http.server.ThreadingHTTPServer(("0.0.0.0", port), SinCache).serve_forever()
