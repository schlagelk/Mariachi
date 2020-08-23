//
//  GitHubClient.swift
//  
//
//  Created by Kenny Schlagel on 7/27/20.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class GitHubClient {
  private let token: String

  public init(token: String) {
      self.token = token
  }

  private func pullRequests(repo: String) -> URLRequest? {
    let str = "https://api.github.com/repos/\(repo)/pulls?state=open"
    guard let url = URL(string: str) else { return nil }
    var request: URLRequest = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
    return request
  }

  private func reviews(repo: String, number: Int) -> URLRequest? {
    let str = "https://api.github.com/repos/\(repo)/pulls/\(number)/reviews"
    guard let url = URL(string: str) else { return nil }
    var request: URLRequest = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
    return request
  }

  public func pullRequestsNeedingReviews(in repo: String, excludingLabels: [String], excludingHeadPrefixes: [String], minApprovals: Int = 2, completion: @escaping ((Result<[PullRequest], Error>) -> Void)) {

    let request = pullRequests(repo: repo)! // TODO: throw

    let session = URLSession.shared.dataTask(with: request) { data, _, err in
      guard err == nil else {
          completion(.failure(err!))
          return
      }
      // create a single decoder for all
      let decoder = JSONDecoder()

      guard let d = data, let pulls = try? decoder.decode([PullRequest].self, from: d) else {
        completion(.success([]))
        return
      }

      var filtered = pulls.notDrafs
      if !excludingLabels.isEmpty {
        filtered = filtered.without(labels: excludingLabels)
      }
      if !excludingHeadPrefixes.isEmpty {
        filtered = filtered.without(prefixes: excludingHeadPrefixes)
      }

      guard !filtered.isEmpty else {
        completion(.success([]))
        return
      }

      // multiple PRs require multiple async calls
      let dispatchGroup = DispatchGroup()
      for pull in filtered {
        dispatchGroup.enter()
        let reviewRequest = self.reviews(repo: repo, number: pull.number)!

        let session2 = URLSession.shared.dataTask(with: reviewRequest) { reviewData, _, _ in
          if let reviewData = reviewData,
            let reviews = try? decoder.decode([Review].self, from: reviewData) {
            pull.reviews = reviews
          }
          dispatchGroup.leave()
        }
        session2.resume()
      }

      dispatchGroup.notify(queue: .main) {
        completion(.success(filtered.needing(minApprovals: minApprovals)))
      }
    }
    session.resume()
    RunLoop.current.run()
  }
}
