import UIKit
import Combine

struct Users: Decodable {
    let data: [User]
}

struct User: Decodable {
    let firstName: String
    let lastName: String
    let email: String
    let id: String
}

struct DataTaskPublisherJSONDecoder: TopLevelDecoder {
    func decode<T>(_ type: T.Type, from: (data: Data, response: URLResponse)) throws -> T where T : Decodable {
        try JSONDecoder().decode(T.self, from: from.data)
    }
}

/*
 {"data":[{"id":"0F8JIqi4zwvb77FGz6Wt","lastName":"Fiedler","firstName":"Heinz-Georg","email":"heinz-georg.fiedler@example.com","title":"mr","picture":"https://randomuser.me/api/portraits/men/81.jpg"}]
 }
 */
var request = URLRequest(url: URL(string: "https://dummyapi.io/data/api/user")!)
request.addValue("Add your app id here", forHTTPHeaderField: "app-id")
request.httpMethod = "GET"
let users = URLSession.shared
    .dataTaskPublisher(for: request)
    .decode(type: Users.self, decoder: DataTaskPublisherJSONDecoder())
    .sink { print($0)}
        receiveValue: { print($0)}

