//
//  TextMessage.swift
//  LemelLabsTest
//
//  Created by Vladislav Yakubets on 2.04.21.
//

import Foundation

struct SampleProtocol: Codable {
    var command: String
    var type: String
    var id: UUID
    var content: Data
    
    init(command: String, type: String, id: UUID, content: Data) {
        self.command = command
        self.type = type
        self.id = id
        self.content = content
    }
    
    func encode() -> Data {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        return data
    }
}

extension Data {
    func decodeJSONToNetworkModel() -> SampleProtocol {
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(SampleProtocol.self, from: self)
        } catch {
            print(error)
            fatalError("Failed decode")
        }
    }
}
