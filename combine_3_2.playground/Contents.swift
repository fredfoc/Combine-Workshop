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

example(of: "combineLatest") {
    let pub1 = PassthroughSubject<Int, Never>()
    let pub2 = PassthroughSubject<Int, Never>()
    pub1
        .combineLatest(pub2) { first, second in
            first * second
        }
        .sink { print("Result: \($0).") }
        .store(in: &subscriptions)

    pub1.send(1)
    pub1.send(2)
    pub2.send(2)
    pub1.send(9)
    pub1.send(3)
    pub2.send(12)
    pub1.send(13)
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
