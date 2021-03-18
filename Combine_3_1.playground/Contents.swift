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

example(of: "min") {
    [-1, 0, 10, 5]
        .publisher
        .min()
        .sink { print("\($0)") }
        .store(in: &subscriptions)
}

example(of: "allSatisfy") {
    [-1, 0, 10, 5]
        .publisher
        .allSatisfy { $0 < 11 }
        .sink { print("\($0)") }
        .store(in: &subscriptions)
}

example(of: "contains") {
    [-1, 0, 10, 5]
        .publisher
        .contains(5)
        .sink { print("\($0)") }
        .store(in: &subscriptions)
}

example(of: "dropFirst") {
    (1 ... 10)
        .publisher
        .dropFirst(12)
        .sink(receiveCompletion: { print($0) },
              receiveValue: { print($0, terminator: " ") })
        .store(in: &subscriptions)
}

example(of: "dropWhile") {
    (1 ... 10)
        .publisher
        .drop(while: { $0 < 5 })
        .sink(receiveCompletion: { print($0) },
              receiveValue: { print($0, terminator: " ") })
        .store(in: &subscriptions)
}

example(of: "dropUntil") {
    let upstream = PassthroughSubject<Int, Never>()
    let second = PassthroughSubject<String, Never>()
    upstream
        .drop(untilOutputFrom: second)
        .sink { print("\($0)", terminator: " ") }
        .store(in: &subscriptions)

    upstream.send(1)
    upstream.send(2)
    second.send("A")
    upstream.send(3)
    upstream.send(4)
}

example(of: "prefix") {
    (1 ... 10)
        .publisher
        .prefix(while: { $0 < 5 })
        .sink(receiveCompletion: { print($0) },
              receiveValue: { print($0, terminator: " ") })
        .store(in: &subscriptions)
}

example(of: "prepend") {
    (1 ... 10)
        .publisher
        .prepend(-1, -2)
        .sink(receiveCompletion: { print($0) },
              receiveValue: { print($0, terminator: " ") })
        .store(in: &subscriptions)
}

example(of: "first") {
    (1 ... 10)
        .publisher
        .first()
        .sink(receiveCompletion: { print($0) },
              receiveValue: { print($0, terminator: " ") })
        .store(in: &subscriptions)
}

example(of: "first(where:)") {
    (1 ... 10)
        .publisher
        .first(where: { $0 > 15 })
        .sink(receiveCompletion: { print($0) },
              receiveValue: { print($0, terminator: " ") })
        .store(in: &subscriptions)
}

example(of: "last") {
    (1 ... 10)
        .publisher
        .last()
        .sink(receiveCompletion: { print($0) },
              receiveValue: { print($0, terminator: " ") })
        .store(in: &subscriptions)
}

example(of: "ouput(at:)") {
    (1 ... 10)
        .publisher
        .output(at: 5)
        .sink(receiveCompletion: { print($0) },
              receiveValue: { print($0, terminator: " ") })
        .store(in: &subscriptions)
}
