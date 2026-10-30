// Exporta los eventos de hoy y mañana de Calendario (iCloud incluido) a JSON.
import EventKit
import Foundation

let store = EKEventStore()
let sem = DispatchSemaphore(value: 0)
var granted = false
store.requestFullAccessToEvents { ok, _ in granted = ok; sem.signal() }
sem.wait()
guard granted else {
  FileHandle.standardError.write("Sin permiso para leer Calendario\n".data(using: .utf8)!)
  exit(1)
}

func hex(_ c: CGColor?) -> String {
  guard let c = c?.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil),
        let p = c.components, p.count >= 3 else { return "#8ea2ff" }
  return String(format: "#%02x%02x%02x", Int(p[0] * 255), Int(p[1] * 255), Int(p[2] * 255))
}

let cal = Calendar.current
let start = cal.startOfDay(for: Date())
let end = cal.date(byAdding: .day, value: 2, to: start)!
let calendars = store.calendars(for: .event)
let events = store.events(matching: store.predicateForEvents(withStart: start, end: end, calendars: calendars))
  .sorted { $0.startDate < $1.startDate }

let iso = ISO8601DateFormatter()
let out: [[String: Any]] = events.map { e in [
  "title": e.title ?? "",
  "start": iso.string(from: e.startDate),
  "end": iso.string(from: e.endDate),
  "allDay": e.isAllDay,
  "location": e.location ?? "",
  "calendar": e.calendar.title,
  "color": hex(e.calendar.cgColor)
] }
let data = try! JSONSerialization.data(withJSONObject: ["updated": iso.string(from: Date()), "events": out], options: [.prettyPrinted])
FileHandle.standardOutput.write(data)
