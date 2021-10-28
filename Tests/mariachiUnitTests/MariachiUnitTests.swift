import XCTest
import class Foundation.Bundle
@testable import mariachiLib

final class MariachiUnitTests: XCTestCase {
  func testPullRequestData() throws {
    let prData: [String: Any] =
      [
        "head": ["ref": "foo/bar"],
        "labels": [["name": "do-not-review"], ["name": "skip-ci"]],
        "draft": true,
        "number": 123,
        "html_url": "github.com/safadf/123",
        "title": "Make Foo Conform to Bar",
        "user": ["login": "schlagelk"],
        "reviews": []
      ]
    let data = try JSONSerialization.data(withJSONObject: prData, options: [])
    let pr = try JSONDecoder().decode(PullRequest.self, from: data)

    XCTAssertTrue(pr.isDraft)
    XCTAssertEqual(pr.branchPrefix, "foo")
    XCTAssertTrue(pr.hasLabel(from: ["skip-ci", "bleh"]))
    XCTAssertFalse(pr.hasLabel(from: ["no-skip-ci", "bleh"]))
  }

  func testReviewData() throws {
    let reviewsData: [[String: Any]] =
      [
        ["user": ["login": "jbond"], "state": "APPROVED"],
        ["user": ["login": "ljames"], "state": "CHANGES_REQUESTED"],
        ["user": ["login": "dwade"], "state": "bad"]
      ]
    let reviewData = try JSONSerialization.data(withJSONObject: reviewsData, options: [])
    let reviews = try JSONDecoder().decode([Review].self, from: reviewData)

    XCTAssertTrue(reviews[0].isReviewed)
    XCTAssertTrue(reviews[1].isReviewed)
    XCTAssertFalse(reviews[2].isReviewed)
  }

  func testUniquingUsers() throws {
    let reviewsData: [[String: Any]] =
      [
        ["user": ["login": "jbond"], "state": "APPROVED"],
        ["user": ["login": "jbond"], "state": "CHANGES_REQUESTED"]
      ]
    let reviewData = try JSONSerialization.data(withJSONObject: reviewsData, options: [])
    let reviews = try JSONDecoder().decode([Review].self, from: reviewData)

    XCTAssertEqual(reviews.uniquingReviewers.count, 1)
  }

  func testPullRequestArrayData() throws {
    // first PR
    let prData: [String: Any] =
       [
         "head": ["ref": "foo/bar"],
         "labels": [["name": "do-not-review"], ["name": "skip-ci"]],
         "draft": false,
         "number": 123,
         "html_url": "github.com/safadf/123",
         "title": "Make Foo Conform to Bar",
         "user": ["login": "schlagelk"],
         "reviews": []
       ]
    let data = try JSONSerialization.data(withJSONObject: prData, options: [])
    let pr = try JSONDecoder().decode(PullRequest.self, from: data)
    let reviewsData: [[String: Any]] =
      [
         ["user": ["login": "jbond"], "state": "APPROVED"],
         ["user": ["login": "ljames"], "state": "CHANGES_REQUESTED"],
         ["user": ["login": "dwade"], "state": "bad"]
       ]
    let reviewData = try JSONSerialization.data(withJSONObject: reviewsData, options: [])
    let reviews = try JSONDecoder().decode([Review].self, from: reviewData)
    pr.reviews = reviews

    // second PR
    let prData1: [String: Any] =
       [
         "head": ["ref": "foo/bar1"],
         "labels": [],
         "draft": false,
         "number": 124,
         "html_url": "github.com/safadf/124",
         "title": "Make Bar Conform to Foo",
         "user": ["login": "schlagelk"],
         "reviews": []
       ]
    let data1 = try JSONSerialization.data(withJSONObject: prData1, options: [])
    let pr1 = try JSONDecoder().decode(PullRequest.self, from: data1)
    let reviewsData1: [[String: Any]] =
      [
         ["user": ["login": "jbond"], "state": "APPROVED"],
         ["user": ["login": "ljames"], "state": "APPROVED"]
      ]
    let reviewData1 = try JSONSerialization.data(withJSONObject: reviewsData1, options: [])
    let reviews1 = try JSONDecoder().decode([Review].self, from: reviewData1)
    pr1.reviews = reviews1

    // third PR
    let prData2: [String: Any] =
       [
         "head": ["ref": "foo/bar2"],
         "labels": [["name": "do-not-review"], ["name": "skip-mariachi"]],
         "draft": true,
         "number": 125,
         "html_url": "github.com/safadf/125",
         "title": "Fix thing",
         "user": ["login": "bondj"],
         "reviews": []
       ]
    let data2 = try JSONSerialization.data(withJSONObject: prData2, options: [])
    let pr2 = try JSONDecoder().decode(PullRequest.self, from: data2)
    pr2.reviews = []

    // fourth PR
    let prData3: [String: Any] =
       [
         "head": ["ref": "release/bar"],
         "labels": [["name": "do-not-review"], ["name": "automerge"]],
         "draft": false,
         "number": 126,
         "html_url": "github.com/safadf/126",
         "title": "Crash App",
         "user": ["login": "jobo"],
         "reviews": []
       ]
    let data3 = try JSONSerialization.data(withJSONObject: prData3, options: [])
    let pr3 = try JSONDecoder().decode(PullRequest.self, from: data3)
    let reviewsData3: [[String: Any]] =
      [
        ["user": ["login": "jbond"], "state": "COMMENTED"]
      ]
    let reviewData3 = try JSONSerialization.data(withJSONObject: reviewsData3, options: [])
    let reviews3 = try JSONDecoder().decode([Review].self, from: reviewData3)
    pr3.reviews = reviews3

    let allThePRs = [pr, pr1, pr2, pr3]
    XCTAssertEqual(allThePRs.notDrafs.count, 3)
    XCTAssertEqual(allThePRs.without(labels: ["skip-mariachi"]).count, 3)
    XCTAssertEqual(allThePRs.without(prefixes: ["release"]).count, 3)
    XCTAssertEqual(allThePRs.needing(minApprovals: 2).count, 3)
  }

  func testTeamsMessage() throws {
    let client = TeamsClient(webhookURL: URL(string: "127.0.0.1")!)
    let prData: [String: Any] =
      [
        "head": ["ref": "foo/bar"],
        "labels": [["name": "do-not-review"], ["name": "skip-ci"]],
        "draft": true,
        "number": 123,
        "html_url": "github.com/safadf/123",
        "title": "Make Foo Conform to Bar",
        "user": ["login": "schlagelk"],
        "reviews": []
      ]
    let data = try JSONSerialization.data(withJSONObject: prData, options: [])
    let pr = try JSONDecoder().decode(PullRequest.self, from: data)

    // second PR
    let prData1: [String: Any] =
       [
         "head": ["ref": "foo/bar1"],
         "labels": [],
         "draft": false,
         "number": 124,
         "html_url": "github.com/safadf/124",
         "title": "Make Bar Conform to Foo",
         "user": ["login": "schlagelk"],
         "reviews": []
       ]
    let data1 = try JSONSerialization.data(withJSONObject: prData1, options: [])
    let pr1 = try JSONDecoder().decode(PullRequest.self, from: data1)

    let message = client.message(from: [pr, pr1], in: "foo/bar")
    XCTAssertEqual(message.sections.count, 1)
    XCTAssertEqual(message.sections.first!.facts.count, 2)
    let lastFact = message.sections.first!.facts.last!
    XCTAssertTrue(lastFact.value.contains(TeamsClient.footer))
  }

  func testRequestedReviewers() throws {
    let prData: [String: Any] =
       [
         "head": ["ref": "foo/bar"],
         "labels": [],
         "draft": false,
         "number": 123,
         "html_url": "github.com/safadf/124",
         "title": "Make Bar Conform to Foo",
         "user": ["login": "schlagelk"],
         "reviews": [],
         "requested_reviewers": [["login": "jbond"]]
       ]
    let data = try JSONSerialization.data(withJSONObject: prData, options: [])
    let pr = try JSONDecoder().decode(PullRequest.self, from: data)
    XCTAssertEqual(pr.awaitingReviewers.count, 1)

    // assert actual reviewer doesn't get added to `awaitingReviewers`
    let prData1: [String: Any] =
       [
         "head": ["ref": "foo/bar"],
         "labels": [],
         "draft": false,
         "number": 123,
         "html_url": "github.com/safadf/124",
         "title": "Make Bar Conform to Foo",
         "user": ["login": "schlagelk"],
         "reviews": [],
         "requested_reviewers": [["login": "jbond"]]
       ]
    let data1 = try JSONSerialization.data(withJSONObject: prData1, options: [])
    let pr1 = try JSONDecoder().decode(PullRequest.self, from: data1)
    let reviewsData: [[String: Any]] =
      [
        ["state": "APPROVED", "user": ["login": "jbond"]],
        ["state": "CHANGES_REQUESTED", "user": ["login": "dwade"]],
        ["state": "bad", "user": ["login": "ljames"]]
       ]
    let reviewData = try JSONSerialization.data(withJSONObject: reviewsData, options: [])
    let reviews = try JSONDecoder().decode([Review].self, from: reviewData)
    pr1.reviews = reviews
    XCTAssertEqual(pr1.awaitingReviewers.count, 0)

    let message = TeamsClient(webhookURL: URL(string: "127.0.0.1")!).message(from: [pr, pr1], in: "foo/bar")
    XCTAssertEqual(message.sections.count, 1)
    XCTAssertEqual(message.sections.first!.facts.count, 2)

    let firstFact = message.sections.first!.facts.first!
    XCTAssertEqual(firstFact.value, "@schlagelk [github.com/safadf/124](github.com/safadf/124)<br>&nbsp;&nbsp;&nbsp; - waiting on @jbond")
  }

  static var allTests = [
    ("testPullRequestData", testPullRequestData),
    ("testReviewData", testReviewData),
    ("testPullRequestArrayData", testPullRequestArrayData),
    ("testTeamsMessage", testTeamsMessage),
    ("testRequestedReviewers", testRequestedReviewers),
    ("testUniquingUsers", testUniquingUsers)
  ]
}
