import ArgumentParser
import Foundation
import mariachiLib

public enum MariachiError: Error {
  case badURL
}

struct Mariachi: ParsableCommand {
  @Argument(help: "Your GitHub Token") var token: String
  @Argument(help: "The MSFT Teams Channel's webhook URL. See the README for instructions on how to get this.") var teamsHookURL: String
  @Argument(help: "Your repository to watch, eg 'myorganization/myrepo'") var repo: String
  @Argument(help: "The head branch prefixes to exclude in the watch task, formatted as a single comma separated string (eg: 'release,merge'. Do not include the slash (eg: 'release/'") var excludingHeadPrefixes: String = ""
  @Argument(help: "The labels to exclude in the watch task, formatted as a single comma separated string (eg: 'Do not review','skip review'") var excludingLabels: String = "skip-mariachi"
  @Argument(help: "The minimum number of approvals needed. An approval and a request for changes both count as a review.") var minApprovals: Int = 2

  mutating func run() throws {
    let GitHub = GitHubClient(token: token)
    let excluding = excludingLabels.split(separator: ",").map { String($0) }
    let excludingHeads = excludingHeadPrefixes.split(separator: ",").map { String($0) }

    guard let teamsURL = URL(string: teamsHookURL) else {
      print("🎺 Mariachi could not make a URL out of \(teamsHookURL)")
      Self.exit(withError: MariachiError.badURL)
    }

    let semaphore = DispatchSemaphore(value: 0)
    let debugMessage = """
    ========================================
    🎺  Mariachi will look for PRs in: \(repo)
        Excluding head branch prefixes: \(excludingHeads)
        Excluding labels: \(excluding)
        Minimum reviews (Approved or Changes Requested): \(minApprovals)
    ========================================
    """
    print(debugMessage)

    GitHub.pullRequestsNeedingReviews(in: repo, excludingLabels: excluding, excludingHeadPrefixes: excludingHeads, minApprovals: minApprovals) { [self] result in
      switch result {
        case .success(let pulls):
          if pulls.isEmpty {
            print("🎺 Mariachi did not find any PRs meeting that criteria")
            Self.exit()
          }

          // post message in a teams channel
          let teamsClient = TeamsClient(webhookURL: teamsURL)
          let messageCard = teamsClient.message(from: pulls, in: self.repo)
          teamsClient.post(message: messageCard) { result in
            switch result {
            case .success:
              print("🎺 Mariachi delivered a reminder to review \(pulls.count) PRs")
              Self.exit()
            case .failure(let e):
              print("🎺 Mariachi had an error \(e)")
              Self.exit(withError: e)
            }
            semaphore.signal()
          }
        case .failure(let error):
          semaphore.signal()
          print("🎺 Mariachi had an error \(error)")
          Self.exit(withError: error)
      }
    }
    semaphore.wait()
  }
}

Mariachi.main()
