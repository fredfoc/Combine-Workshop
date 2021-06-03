import Combine
import CoreFoundation
import Foundation

func example(of description: String,
             action: () -> Void)
{
    print("\n——— Example of:", description, "———")
    action()
}

var subscriptions = Set<AnyCancellable>()

example(of: "URLSession") {
//    URLSession.shared
//        .dataTaskPublisher(for: URL(string: "https://www.google.be")!)
//        .sink(receiveCompletion: { completion in
//            if case let .failure(err) = completion {
//                print("Retrieving data failed with error \(err)")
//            }
//        }, receiveValue: { data, response in
//            print("Retrieved data of size \(data.count), response = \(response)")
//        })
//        .store(in: &subscriptions)
}

example(of: "multicast") {
    let publisher = URLSession.shared
        .dataTaskPublisher(for: URL(string: "https://www.google.be")!)
        .multicast { PassthroughSubject<(data: Data, response: URLResponse), URLError>() }

    publisher
        .sink(receiveCompletion: { completion in
            if case let .failure(err) = completion {
                print("Sink1 Retrieving data failed with error \(err)")
            }
        }, receiveValue: { data, response in
            print("Retrieved data of size \(data.count), response = \(response)")
        })
        .store(in: &subscriptions)

    publisher
        .sink(receiveCompletion: { completion in
            if case let .failure(err) = completion {
                print("Sink2 Retrieving data failed with error \(err)")
            }
        }, receiveValue: { data, response in
            print("Retrieved data of size \(data.count), response = \(response)")
        })
        .store(in: &subscriptions)

    publisher.connect()
}


class AClass {
    
}

let u: AClass? = nil
let m = u as? AnyObject
print(m)

let v: String? = nil
let n = v as? AnyObject
print(n)
