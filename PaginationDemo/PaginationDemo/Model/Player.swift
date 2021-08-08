//
//  Player.swift
//  PrefetcherDemo
//
//  Created by Sunmi on 2021/08/08.
//

import Foundation


struct Player: Codable {
    
    var firstName: String
    var lastName: String
    var team: Team

    enum CodingKeys: String, CodingKey {
        case firstName, lastName
        case team = "team"
    }
    
}

struct Team: Codable {
    
    var city: String
    var name: String

    enum CodingKeys: String, CodingKey {
        case city, name
    }
}


struct Meta: Codable {
    
   var totalPages: Int
   var currentPage: Int
   var nextPage: Int?
   var perPage: Int
   var totalCount: Int
}
