//
//  NetworkManager.swift
//  PrefetcherDemo
//
//  Created by Sunmi on 2021/08/08.
//

import Foundation


enum CustomError: String, Error {
    
    case invalidData = "The data received from the server was invalid. Please try again."
    case unableToComplete = "Unable to complete your request. Please check your internet connection"
    
}



class NetworkManager {
    
    static let shared = NetworkManager()
    
    private let baseURL = "https://free-nba.p.rapidapi.com/players?"

//  API Link: https://rapidapi.com/theapiguy/api/free-nba/

    func getPlayers( page: Int, success: (([Player]?, Meta?) -> Void)? = nil,
                     failure: ((CustomError) -> Void)? = nil) {
        
        let endpoint = baseURL + "page=\(page)&per_page=50"
        
        guard let url = URL(string: endpoint) else {
            failure?(.invalidData)
            return
        }
        
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 2.0)
        request.httpMethod = "GET"
//        request.allHTTPHeaderFields = headers

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let _ = error {
                failure?(.invalidData)
            }

            guard let response = response as? HTTPURLResponse,
                  response.statusCode == 200 else {
                failure?(.unableToComplete)
                return
            }

            guard let data = data else {
                failure?(.invalidData)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                   
                    if let jsonData = json["data"] as? [[String: Any]] {
                    
                        DecoderManager.decodeModelsToCamelCase(Player.self, jsonData) { players in
                            if let meta = json["meta"] as? [String: Any] {
                                DecoderManager.decodeModelToCamelCase(Meta.self, meta) { meta in
                                    success?(players, meta)
                                }
                            }
                         }
                       
                    }
                        
               
                }
            } catch {
                failure?(.invalidData)
            }
            

        }
        
        task.resume()
    }
}

enum DecoderManager {

    static func decodeModel<T: Decodable>(_ type: T.Type,
                                          _ obj: [String:Any], _ success: ((T?) -> Void)?) {
        do {
            let decodedData = try JSONDecoder().decodeModel(type, withJSONObject: obj, options: .prettyPrinted)
            success?(decodedData)
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    static func decodeModelToCamelCase<T: Decodable>(_ type: T.Type,
                                          _ obj: [String:Any], _ success: ((T?) -> Void)?) {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        do {
            let data = try! JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted)
            let decodedData = try decoder.decode(T.self, from: data)
            success?(decodedData)
        } catch {
            debugPrint(#function, #line, "error=\(error.localizedDescription)")
        }
    }

    static func decodeModelsToCamelCase<T: Decodable>(_ type: T.Type,
                                                      _ obj: [[String: Any]], _ success: (([T]?) -> Void)?) {

            
        var array:[T] = []
        for (_, value) in obj.enumerated() {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            DecoderManager.decodeModelToCamelCase(type, value) { decodedData in
                guard let decodedData = decodedData else { return }
                array.append(decodedData)
            }
            
        }
        success?(array)

    }
}

extension JSONDecoder {
    func decodeModel<T: Decodable>(_ type: T.Type, withJSONObject object: Any,
                                   options opt: JSONSerialization.WritingOptions = []) throws -> T {
        let data = try! JSONSerialization.data(withJSONObject: object, options: opt)
        return try decode(T.self, from: data)
    }
}
