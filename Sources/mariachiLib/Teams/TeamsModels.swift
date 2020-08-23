//
//  TeamsModels.swift
//  
//
//  Created by Kenny Schlagel on 7/29/20.
//

import Foundation

public struct Fact: Codable {
  var name: String
  var value: String
}

public struct Section: Codable {
  var activityTitle: String
  var activitySubtitle: String
  var activityImage: String
  var facts: [Fact]
  var markdown: Bool
}

public struct MessageCard: Codable {
  var type: String = "MessageCard"
  var context: String = "http://schema.org/extensions"
  var themeColor: String
  var summary: String
  var sections: [Section]

  private enum CodingKeys: String, CodingKey {
    case type = "@type"
    case context = "@context"
    case themeColor, summary, sections
  }
}
