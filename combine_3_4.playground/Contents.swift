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

example(of: "breakpoint") {
//    let publisher = PassthroughSubject<String?, Never>()
//    publisher
//        .breakpoint(
//            receiveOutput: { value in return value == "DEBUGGER" }
//        )
//        .sink { print("\(String(describing: $0))" , terminator: " ") }
//        .store(in: &subscriptions)
//
//    publisher.send("DEBUGGER")
}

example(of: "breakpointOnError") {
//    struct CustomError: Error {}
//    let publisher = PassthroughSubject<String?, Error>()
//    publisher
//        .tryMap { _ in
//            throw CustomError()
//        }
//        .breakpointOnError()
//        .sink(
//            receiveCompletion: { completion in print("Completion: \(String(describing: completion))") },
//            receiveValue: { aValue in print("Result: \(String(describing: aValue))") }
//        )
//        .store(in: &subscriptions)
//
//    publisher.send("TEST DATA")
}

example(of: "print") {
    let integers = (1 ... 2)
    integers.publisher
        .print("Logged a message", to: nil)
        .sink { _ in }
        .store(in: &subscriptions)
}
