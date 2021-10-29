//
//  GitHubModels.swift
//  
//
//  Created by Kenny Schlagel on 7/27/20.
//

import Swift

public class PullRequest: Decodable {
  let head: Head
  let labels: [Label]
  let draft: Bool
  let number: Int
  let url: String
  var title: String?
  let user: User
  var reviews: [Review]?
  var requestedReviewers: [User]?

  private enum CodingKeys: String, CodingKey {
    case number, head, labels, draft, title, user, reviews
    case url = "html_url"
    case requestedReviewers = "requested_reviewers"
  }

  var isDraft: Bool {
      draft
  }

  var branchPrefix: String {
      let first = head.ref.split(separator: "/").first ?? ""
      return String(first)
  }

  func hasLabel(from labelNames: [String]) -> Bool {
      for l in labels {
          if labelNames.contains(l.name) {
              return true
          }
      }
      return false
  }

  var awaitingReviewers: [User] {
    guard let requestedReviewers = requestedReviewers else { return [] }
    var awaiting = [User]()
    let reviewers = reviews?.compactMap { $0.user }
    for requested in requestedReviewers {
      if reviewers?.contains(requested) == false {
        awaiting.append(requested)
      }
    }
    return awaiting
  }
}

public struct Label: Decodable {
  let name: String
}

public struct Head: Decodable {
  let ref: String
}

public struct User: Decodable, Equatable {
  let login: String

  var name: String {
      login
  }
}

public class Review: Decodable {
  let state: String
  let user: User

  var reviewState: String {
      state
  }

  var isApproved: Bool {
      reviewState == "APPROVED"
  }
}

public extension Array where Element: PullRequest {
  var notDrafs: [PullRequest] {
      filter { !$0.isDraft }
  }

  func without(labels: [String]) -> [PullRequest] {
      filter { !$0.hasLabel(from: labels) }
  }

  func without(prefixes: [String]) -> [PullRequest] {
      filter { !prefixes.contains($0.branchPrefix) }
  }

  func needing(minApprovals: Int) -> [PullRequest] {
      var needingApprovalsTemp = [PullRequest]()
      for pull in self {
        let validReviews = pull.reviews?.filter { $0.isApproved }.uniquingReviewers.count ?? 0
          if validReviews < minApprovals {
              needingApprovalsTemp.append(pull)
          }
      }
      return needingApprovalsTemp
  }
}
public extension Array where Element: Review {
  var uniquingReviewers: [Review] {
    var seen = [String: Review]()
    return self.filter { seen.updateValue($0, forKey: $0.user.login) == nil }
  }
}
