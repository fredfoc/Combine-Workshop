import Combine
import CoreFoundation
import Foundation

func example(of description: String,
             action: () -> Void)
{
    print("\n——— Example of:", description, "———")
    action()
}

example(of: "Empty") {
    _ = Empty<Any, Never>(completeImmediately: true)
        .sink(
            receiveCompletion: {
                print("Received completion", $0)

            },
            receiveValue: { _ in }
        )
}

example(of: "Fail") {
    enum MyError: Error {
        case test
    }
    _ = Fail<Any, MyError>(error: MyError.test)
        .sink(
            receiveCompletion: {
                print("Received completion", $0)
            },
            receiveValue: { _ in }
        )
}

example(of: "Just") {
    _ = Just("Hello world!")
        .sink(
            receiveCompletion: {
                print("Received completion", $0)
            },
            receiveValue: {
                print("Received value", $0)
            }
        )
}

var store = Set<AnyCancellable>()
example(of: "Future") {
    print(CFAbsoluteTimeGetCurrent())
    Future<Int, Never> { promise in
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
            promise(.success(1))
        }
    }.sink(
        receiveCompletion: {
            print("Received completion of Future", $0)
        },
        receiveValue: {
            print("Received value of Future", $0)
            print(CFAbsoluteTimeGetCurrent())
        }
    ).store(in: &store)
}

example(of: "More on Future") {
    let future = Future<Int, Never> { promise in
        print("start future at:", CFAbsoluteTimeGetCurrent())
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
            promise(.success(1))
        }
    }
    future.sink(
        receiveCompletion: {
            print("Received completion from first Subscriber", $0)
        },
        receiveValue: {
            print("Received value from first Subscriber ", $0, " at:", CFAbsoluteTimeGetCurrent())
        }
    ).store(in: &store)

    DispatchQueue.global().asyncAfter(deadline: .now() + 4) {
        print("create second subscriber at", CFAbsoluteTimeGetCurrent())
        future.sink(
            receiveCompletion: {
                print("Received completion from second Subscriber", $0)
            },
            receiveValue: {
                print("Received value from second Subscriber ", $0, " at:", CFAbsoluteTimeGetCurrent())
            }
        ).store(in: &store)
    }
}

example(of: "PassthroughSubject") {
    let passThroughSubject = PassthroughSubject<String, Never>()
    passThroughSubject
        .sink(receiveCompletion: {
                  print("Received completion of firstSubscription", $0)
              },
              receiveValue: { print("firstSubscription received", $0) })
        .store(in: &store)
    passThroughSubject.send("test")
    passThroughSubject
        .sink(receiveCompletion: {
                  print("Received completion of secondSubscription", $0)
              },
              receiveValue: { print("secondSubscription received", $0) })
        .store(in: &store)
    passThroughSubject.send("another test")
    passThroughSubject.send(completion: .finished)
    passThroughSubject.send("Anyone heard me ?")
}

example(of: "CurrentValueSubject") {
    enum MyError: Error {
        case noMoreWord
    }
    let currentSubject = CurrentValueSubject<String, MyError>("first")
    currentSubject
        .sink(receiveCompletion: {
                  print("Received completion of firstSubscription", $0)
              },
              receiveValue: { print("firstSubscription received", $0) })
        .store(in: &store)
    currentSubject.send("second")
    currentSubject
        .sink(receiveCompletion: {
                  print("Received completion of secondSubscription", $0)
              },
              receiveValue: { print("secondSubscription received", $0) })
        .store(in: &store)
    currentSubject.send("third")
    currentSubject.send(completion: .failure(MyError.noMoreWord))
    currentSubject.send("Anyone heard me ?")
    currentSubject
        .sink(receiveCompletion: {
                  print("Received completion of thirdSubscription", $0)
              },
              receiveValue: { print("thirdSubscription received", $0) })
        .store(in: &store)
}

example(of: "Type erasure") {
    struct MyObject {
        private let currentSubject = CurrentValueSubject<String, Error>("first")
        var publisher: AnyPublisher<String, Error> {
            currentSubject.eraseToAnyPublisher()
        }
    }
    let myObject = MyObject()
    myObject
        .publisher
        .sink { print("Received completion", $0) }
    receiveValue: { print("Received", $0) }
    // myObject.publisher.send("something") -> Value of type 'AnyPublisher<String, Error>' has no member 'send'
}
