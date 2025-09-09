import Foundation

enum CoreDataLogger {
    static func error(_ message: String, _ error: Error, file: StaticString = #file, line: UInt = #line) {
        print("❌ [CoreData] \(message): \(error) @\(file):\(line)")
    }
    static func info(_ message: String) {
        print("ℹ️ [CoreData] \(message)")
    }
}

