import XCTest
import class Foundation.Bundle

final class MariachiEndToEndTests: XCTestCase {
  func testHelp() throws {
    guard #available(macOS 10.13, *) else {
        return
    }

    let fooBinary = productsDirectory.appendingPathComponent("mariachi")
    let process = Process()
    process.executableURL = fooBinary

    let pipe = Pipe()
    process.standardOutput = pipe
    process.arguments = ["-h"]

    try process.run()
    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!

    AssertEqualStringsIgnoringTrailingWhitespace(output, """
    USAGE: mariachi <token> <teams-hook-url> <repo> [<excluding-head-prefixes>] [<excluding-labels>] [<min-approvals>]
    """)
  }

  /// Returns path to the built products directory.
  var productsDirectory: URL {
    #if os(macOS)
      for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
        return bundle.bundleURL.deletingLastPathComponent()
      }
      fatalError("couldn't find the products directory")
    #else
      return Bundle.main.bundleURL
    #endif
  }

  static var allTests = [
    ("testHelp", testHelp)
  ]
}
