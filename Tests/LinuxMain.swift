import XCTest

import mariachiTests

var tests = [XCTestCaseEntry]()
tests += mariachiTests.allTests()
XCTMain(tests)
