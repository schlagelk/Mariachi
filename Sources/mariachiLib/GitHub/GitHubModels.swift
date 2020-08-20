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

  private enum CodingKeys: String, CodingKey {
    case number, head, labels, draft, title, user, reviews
    case url = "html_url"
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
}

public struct Label: Decodable {
  let name: String
}

public struct Head: Decodable {
  let ref: String
}

public struct User: Decodable {
  let login: String

  var name: String {
      login
  }
}

public struct Review: Decodable {
  let state: String

  var reviewState: String {
      state
  }

  var isReviewed: Bool {
      reviewState == "APPROVED" || reviewState == "CHANGES_REQUESTED"
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
          let approvedReviews = pull.reviews?.filter { $0.isReviewed }.count ?? 0
          if approvedReviews < minApprovals {
              needingApprovalsTemp.append(pull)
          }
      }
      return needingApprovalsTemp
  }
}
