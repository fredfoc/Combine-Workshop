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

example(of: "assertNoFailure") {
    enum SubjectError: Error {
        case genericSubjectError
    }

    let subject = CurrentValueSubject<String, Error>("initial value")
    subject
        .assertNoFailure()
        .sink(receiveCompletion: { print("completion: \($0)") },
              receiveValue: { print("value: \($0).") })
        .store(in: &subscriptions)

    subject.send("second value")
//    subject.send(completion: .failure(SubjectError.genericSubjectError))
}

example(of: "catch") {
    struct SimpleError: Error {}
    let numbers = [5, 4, 3, 2, 1, 0, 9, 8, 7, 6]
    numbers.publisher
        .tryLast(where: {
            guard $0 != 0 else { throw SimpleError() }
            return true
        })
//        .catch({ _ in
//            Just(-1)
//        })
        .sink(receiveCompletion: { print($0) }, receiveValue: {
            print("received", $0)
        })
        .store(in: &subscriptions)
}

example(of: "retry") {
    struct SimpleError: Error {}
    let numbersPub = PassthroughSubject<Int, SimpleError>()
    numbersPub
        .print("publisher")
        .retry(2)
        .sink(receiveCompletion: { print($0) },
              receiveValue: { print("numbersPub : \($0)") })
        .store(in: &subscriptions)
    numbersPub.send(completion: .failure(SimpleError()))
}

example(of: "measureInterval") {
//    Timer.publish(every: 1, on: .main, in: .default)
//        .autoconnect()
//        .measureInterval(using: RunLoop.main)
//        .sink { print("\($0)", terminator: "\n") }
//        .store(in: &subscriptions)
}

example(of: "debounce") {
//    let bounces: [(Int, TimeInterval)] = [
//        (0, 0),
//        (1, 0.25), // 0.25s interval since last index
//        (2, 1), // 0.75s interval since last index
//        (3, 1.25), // 0.25s interval since last index
//        (4, 1.5), // 0.25s interval since last index
//        (5, 2), // 0.5s interval since last index
//    ]
//
//    let subject = PassthroughSubject<Int, Never>()
//    subject
//        .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
//        .sink { index in
//            print("Received index \(index)", CFAbsoluteTimeGetCurrent())
//        }
//        .store(in: &subscriptions)
//
//    for bounce in bounces {
//        DispatchQueue.main.asyncAfter(deadline: .now() + bounce.1) {
//            print("send index", bounce.0, CFAbsoluteTimeGetCurrent())
//            subject.send(bounce.0)
//        }
//    }
}

example(of: "delay") {
//    let subject = PassthroughSubject<Int, Never>()
//    subject
//        .delay(for: .seconds(3), scheduler: RunLoop.main)
//        .sink(receiveCompletion: { print($0, CFAbsoluteTimeGetCurrent()) },
//              receiveValue: { print($0, CFAbsoluteTimeGetCurrent()) })
//        .store(in: &subscriptions)
//
//    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//        print("send value", CFAbsoluteTimeGetCurrent())
//        subject.send(0)
//    }
//    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//        print("send completion", CFAbsoluteTimeGetCurrent())
//        subject.send(completion: .finished)
//    }
}

example(of: "throttle") {
//    Timer.publish(every: 3.0, on: .main, in: .default)
//        .autoconnect()
//        .throttle(for: 10.0, scheduler: RunLoop.main, latest: true)
//        .sink(
//            receiveCompletion: { print("Completion: \($0).") },
//            receiveValue: { print("Received Timestamp \($0).") }
//        ).store(in: &subscriptions)
}

example(of: "timeout") {
    let subject = PassthroughSubject<Int, Never>()
    subject
        .timeout(.seconds(3), scheduler: RunLoop.main)
        .sink(receiveCompletion: { print($0, CFAbsoluteTimeGetCurrent()) },
              receiveValue: { print($0, CFAbsoluteTimeGetCurrent()) })
        .store(in: &subscriptions)

    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
        print("send value", CFAbsoluteTimeGetCurrent())
        subject.send(0)
    }
}
