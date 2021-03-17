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
example(of: "collect") {
    ["A", "B", "C", "D", "E"].publisher
        .collect(2)
        .sink { print($0) }
        .store(in: &subscriptions)
}

example(of: "collect on subject") {
    let currentSubject = CurrentValueSubject<String, Error>("first")
    currentSubject
        .collect()
        .sink(receiveCompletion: {
                  print("Received completion", $0)
              },
              receiveValue: { print("Received", $0) })
        .store(in: &subscriptions)
    currentSubject.send("second")
    currentSubject.send(completion: .finished) // if this line is removed then collect is never trigerred
}

example(of: "collect on subject with Error") {
    enum MyError: Error {
        case test
    }
    let currentSubject = CurrentValueSubject<String, Error>("first")
    currentSubject
        .collect()
        .sink(receiveCompletion: {
                  print("Received completion", $0)
              },
              receiveValue: { print("Received", $0) })
        .store(in: &subscriptions)
    currentSubject.send("second")
    currentSubject.send(completion: .failure(MyError.test))
}

example(of: "collect By Time Strategy") {
    Timer.publish(every: 1, on: .main, in: .default)
        .autoconnect()
        .collect(.byTime(RunLoop.main, .seconds(5)))
        .sink { print("\($0)", terminator: "\n\n") }
        .store(in: &subscriptions)
}

example(of: "reduce") {
    (0 ... 10).publisher
        .reduce(0) { accum, next in accum + next }
        .sink { print("\($0)") }
        .store(in: &subscriptions)
}

example(of: "ignoreOutPut") {
    struct MyError: Error {}
    (0 ... 10)
        .publisher
        .tryMap { value -> Int in
            if value > 5 {
                throw MyError()
            }
            return value
        }
//        .ignoreOutput()
        .sink(receiveCompletion: { print("Received completion", $0) },
              receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "map") {
    _ = (1 ... 6)
        .publisher
        .map { $0 * 2 }
        .sink { print($0) }
}

example(of: "map with format") {
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    [123, 4, 56]
        .publisher
        .map {
            formatter.string(for: NSNumber(integerLiteral: $0)) ?? ""
        }
        .sink(receiveValue: { print($0) })
        .store(in: &subscriptions)
}

example(of: "map<T>") {
    struct MyObject {
        let x: Int
        let y: Int
    }
    let subject = PassthroughSubject<MyObject, Never>()
    subject
        .map(\MyObject.x, \.y)
        .sink { x, y in
            print(x, "-", y)
        }
        .store(in: &subscriptions)
    subject.send(MyObject(x: 10, y: 20))
}

example(of: "tryMap") {
    enum MyError: Error {
        case noData
    }
    func convert(_ value: String) throws -> Data {
        guard let data = value.data(using: .utf8) else {
            throw MyError.noData
        }
        return data
    }
    struct MyObject: Decodable {
        let name: String
    }
    ["{\"name\": \"Fred\"}", "4", "56"]
        .publisher
        .tryMap { try JSONDecoder().decode(MyObject.self, from: try convert($0)) }
        .sink(receiveCompletion: {
                  print("Received completion", $0)
              },
              receiveValue: { print("Received", $0) })
        .store(in: &subscriptions)
}

example(of: "replaceNil") {
    ["A", nil, "C"].publisher
        .replaceNil(with: "-")
        .sink { print($0) }
        .store(in: &subscriptions)
}

example(of: "mapError") {
    enum MyError: Error {
        case stringHasNoData
        case decode(Error)
    }
    func convert(_ value: String) throws -> Data {
        guard let data = value.data(using: .utf8) else {
            throw MyError.stringHasNoData
        }
        return data
    }
    struct MyObject: Decodable {
        let name: String
    }
    ["{\"name\": \"Fred\"}", "4", "56"]
        .publisher
        .tryMap { try JSONDecoder().decode(MyObject.self, from: try convert($0)) }
        .mapError { MyError.decode($0) }
        .sink(receiveCompletion: {
                  print("Received completion", $0)
              },
              receiveValue: { print("Received", $0) })
        .store(in: &subscriptions)
}

example(of: "scan") {
    (1 ... 10)
        .publisher
        .scan(50) { $0 + $1 }
        .collect()
        .sink { print($0) }
        .store(in: &subscriptions)
}

example(of: "filter") {
    (1...10)
        .publisher
        .filter { $0 % 2 == 0 }
        .collect()
        .sink { print($0) }
        .store(in: &subscriptions)
}

example(of: "replaceEmpty") {
    Empty<Int, Never>()
        .replaceEmpty(with: 100)
        .sink { print($0) }
    receiveValue: { print($0) }
        .store(in: &subscriptions)
}


example(of: "Flatmap") {
    ["A", "B", "C", "D", "E"].publisher
        .collect(2)
        .flatMap { sequence in
            Just(sequence.joined(separator: "-"))
                .eraseToAnyPublisher()
        }
        .sink { print($0) }
        .store(in: &subscriptions)
}

example(of: "Flatmap with func") {
    func join(_ sequence: [String]) -> AnyPublisher<String, Never> {
        Just(sequence.joined(separator: "-"))
            .eraseToAnyPublisher()
    }
    ["A", "B", "C", "D", "E"].publisher
        .collect(2)
        .flatMap(join)
        .sink { print($0) }
        .store(in: &subscriptions)
}
