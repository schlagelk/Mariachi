//
//  TestHelpers.swift
//  
//
//  Created by Kenny Schlagel on 8/18/20.
//
import XCTest
import Foundation

private extension Substring {
  func trimmed() -> Substring {
    guard let i = lastIndex(where: { $0 != " " }) else {
      return ""
    }
    return self[...i]
  }
}

func AssertEqualStringsIgnoringTrailingWhitespace(_ string1: String, _ string2: String, file: StaticString = #file, line: UInt = #line) {
  let lines1 = string1.split(separator: "\n", omittingEmptySubsequences: false)
  let lines2 = string2.split(separator: "\n", omittingEmptySubsequences: false)
  for (line1, line2) in zip(lines1, lines2) {
    XCTAssertEqual(line1.trimmed(), line2.trimmed(), file: (file), line: line)
  }
}
