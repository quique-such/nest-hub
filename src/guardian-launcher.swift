// Lanza guardian.sh como proceso hijo para que macOS atribuya los permisos
// (Red local, Calendario) a este programa y no a zsh/python.
// Al recibir SIGTERM/SIGINT (launchctl stop/kickstart) cierra también al hijo,
// para no dejar guardianes huérfanos sin permisos.
import Foundation

let p = Process()
p.executableURL = URL(fileURLWithPath: "/bin/zsh")
// guardian.sh está en la misma carpeta que este programa
let dir = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath().deletingLastPathComponent()
p.arguments = [dir.appendingPathComponent("guardian.sh").path]
try p.run()

var sources: [DispatchSourceSignal] = []
for sig in [SIGTERM, SIGINT, SIGHUP] {
  signal(sig, SIG_IGN)
  let s = DispatchSource.makeSignalSource(signal: sig, queue: .main)
  s.setEventHandler { p.terminate(); p.waitUntilExit(); exit(0) }
  s.resume()
  sources.append(s)
}
p.terminationHandler = { exit($0.terminationStatus) }
dispatchMain()
