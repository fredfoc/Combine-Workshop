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

example(of: "merge") {
    let pubA = PassthroughSubject<Int, Never>()
    let pubB = PassthroughSubject<Int, Never>()
    let pubC = PassthroughSubject<Int, Never>()

    pubA
        .merge(with: pubB, pubC)
        .sink { print("\($0)", terminator: " ") }
        .store(in: &subscriptions)

    pubA.send(1)
    pubB.send(40)
    pubC.send(90)
    pubA.send(2)
    pubB.send(50)
    pubC.send(100)
}

example(of: "zip") {
    let numbersPub = PassthroughSubject<Int, Never>()
    let lettersPub = PassthroughSubject<String, Never>()

    numbersPub.sink { print("numbersPub : \($0)") }
        .store(in: &subscriptions)
    lettersPub.sink { print("lettersPub : \($0)") }
        .store(in: &subscriptions)

    numbersPub
        .zip(lettersPub)
        .sink { print("zip: \($0)") }
        .store(in: &subscriptions)

    numbersPub.send(1)
    print("----")
    numbersPub.send(2)
    print("----")
    lettersPub.send("A")
    print("----")
    numbersPub.send(3)
    print("----")
    lettersPub.send("B")
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

example(of: "combineLatest") {
    let publisher1 = PassthroughSubject<Int, Never>()
    let publisher2 = PassthroughSubject<Int, Never>()
    let publisher3 = PassthroughSubject<Int, Never>()

    let publishers = PassthroughSubject<PassthroughSubject<Int, Never>, Never>()

    publishers
        .switchToLatest()
        .sink(receiveCompletion: { _ in print("Completed!") },
              receiveValue: { print($0) })
        .store(in: &subscriptions)

    publishers.send(publisher1)
    publisher1.send(1)
    publisher1.send(2)

    publishers.send(publisher2)
    print("---- : publisher1.send(3)")
    publisher1.send(3)
    print("----")
    publisher2.send(4)
    publisher2.send(5)

    publishers.send(publisher3)
    print("---- : publisher2.send(6)")
    publisher2.send(6)
    print("----")
    publisher3.send(7)
    publisher3.send(8)
    publisher3.send(9)

    print("---- : publisher3.send(completion: .finished)")
    publisher3.send(completion: .finished)
    print("----")
    publishers.send(completion: .finished)
}
