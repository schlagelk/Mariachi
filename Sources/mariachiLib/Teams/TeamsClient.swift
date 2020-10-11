//
//  TeamsClient.swift
//
//
//  Created by Kenny Schlagel on 7/27/20.
//

public enum MariachiError: Error {
  case badTeamsData
}

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class TeamsClient {
  private let hookURL: URL

  public init(webhookURL url: URL) {
      self.hookURL = url
  }

  func messageRequest(data: Data) -> URLRequest? {
    var request: URLRequest = URLRequest(url: self.hookURL)
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = data
      return request
  }

  public func post(message: MessageCard, completion: @escaping (Result<String, Error>) -> Void) {

    guard let jsonData = try? JSONEncoder().encode(message), let request = messageRequest(data: jsonData) else {
        completion(.failure(MariachiError.badTeamsData))
        return
    }

    let session = URLSession.shared.dataTask(with: request) { _, _, err in
        guard err == nil else {
          completion(.failure(err!))
            return
        }
      completion(.success("OK"))
    }
    session.resume()
  }

  public func message(from pulls: [PullRequest], in repo: String) -> MessageCard {
    // TODO: - make themeColor and message configurable
    let themeColor = "6E33FF"
    let iconURL = "https://raw.githubusercontent.com/schlagelk/Mariachi/main/mariachi.png"
    let message = "\(pulls.count) PR(s) need reviews"

    var facts = [Fact]()
    for pull in pulls {
      let fact = Fact(name: pull.title ?? "", value: makeFactValue(from: pull))
      facts.append(fact)
    }
    let section = Section(activityTitle: message, activitySubtitle: repo, activityImage: iconURL, facts: facts, markdown: true)

    let messageCard = MessageCard(themeColor: themeColor, summary: message, sections: [section])
    return messageCard
  }

  private func makeFactValue(from pull: PullRequest) -> String {
    var value = "@\(pull.user.name) [\(pull.url)](\(pull.url))"
    for awaiting in pull.awaitingReviewers {
      value.append("<br>&nbsp;&nbsp;&nbsp; - waiting on @\(awaiting.login)")
    }
    return value
  }
}
