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

example(of: "Deferred") {
    _ = Deferred<Just>(createPublisher: {
        Just("Hello")
    })
        .sink(
            receiveCompletion: {
                print("Received completion", $0)
            },
            receiveValue: {
                print("Received value", $0)
            }
        )
}

example(of: "Record") {
    _ = Record<String, Never> { example in
        example.receive("One")
        example.receive("Two")
        example.receive("Three")
        example.receive(completion: .finished)
    }
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

example(of: "ConnectablePublisher") {
//    let publisher = Just("test")
//        .makeConnectable()
//
//    print("subscription", CFAbsoluteTimeGetCurrent())
//    publisher.sink(
//        receiveCompletion: {
//            print("Received completion", $0, CFAbsoluteTimeGetCurrent())
//        },
//        receiveValue: {
//            print("Received value from first subscriber", $0)
//        }
//    ).store(in: &store)
//
//    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//        _ = publisher.connect()
//    }
}

example(of: "Multicast") {
    var sourceValue = 0
    var sinkValues = [Int]()
    func sourceGenerator() -> Int {
        sourceValue += 1
        return sourceValue
    }
    enum TestFailureCondition: Error {
        case anErrorExample
    }
    func asyncAPICall(sabotage: Bool, completion completionBlock: @escaping ((Int, Error?) -> Void)) {
        DispatchQueue.global(qos: .background).async {
            let delay = Int.random(in: 1 ... 3)
            print(" * making async call (delay of \(delay) seconds)")
            sleep(UInt32(delay))
            if sabotage {
                completionBlock(0, TestFailureCondition.anErrorExample)
            }
            completionBlock(sourceGenerator(), nil)
        }
    }
    let pipelineFork = PassthroughSubject<Int, Error>()
    let publisher = Deferred {
        Future<Int, Error> { promise in
            asyncAPICall(sabotage: false) { grantedAccess, err in
                if let err = err {
                    promise(.failure(err))
                } else {
                    promise(.success(grantedAccess))
                }
            }
        }
    }
    .multicast(subject: pipelineFork)
    publisher
        .sink(receiveCompletion: { completion in
            print("1 received the completion: ", String(describing: completion), sinkValues)
        }, receiveValue: { value in
            print("1 received value: ", value)
            sinkValues.append(value)
        })
        .store(in: &store)

    publisher.sink(receiveCompletion: { completion in
        print("2 received the completion: ", String(describing: completion), sinkValues)
    }, receiveValue: { value in
        print("2 received value: ", value)
        sinkValues.append(value)
    })
        .store(in: &store)
    publisher
        .connect()
        .store(in: &store)
    publisher.sink(receiveCompletion: { completion in
        print("3 received the completion: ", String(describing: completion), sinkValues)
    }, receiveValue: { value in
        print("3 received value: ", value)
        sinkValues.append(value)
    })
        .store(in: &store)
}

example(of: "Share") {
    var sourceValue = 0
    var sinkValues = [Int]()
    func sourceGenerator() -> Int {
        sourceValue += 1
        return sourceValue
    }
    enum TestFailureCondition: Error {
        case anErrorExample
    }
    func asyncAPICall(sabotage: Bool, completion completionBlock: @escaping ((Int, Error?) -> Void)) {
        DispatchQueue.global(qos: .background).async {
            let delay = Int.random(in: 1 ... 3)
            print(" * making async call (delay of \(delay) seconds)")
            sleep(UInt32(delay))
            if sabotage {
                completionBlock(0, TestFailureCondition.anErrorExample)
            }
            completionBlock(sourceGenerator(), nil)
        }
    }
    let publisher = Deferred {
        Future<Int, Error> { promise in
            asyncAPICall(sabotage: false) { grantedAccess, err in
                if let err = err {
                    promise(.failure(err))
                } else {
                    promise(.success(grantedAccess))
                }
            }
        }
    }
    .share()
    publisher
        .sink(receiveCompletion: { completion in
            print("1 received the completion: ", String(describing: completion), sinkValues)
        }, receiveValue: { value in
            print("1 received value: ", value)
            sinkValues.append(value)
        })
        .store(in: &store)

    publisher.sink(receiveCompletion: { completion in
        print("2 received the completion: ", String(describing: completion), sinkValues)
    }, receiveValue: { value in
        print("2 received value: ", value)
        sinkValues.append(value)
    })
        .store(in: &store)
    publisher.sink(receiveCompletion: { completion in
        print("3 received the completion: ", String(describing: completion), sinkValues)
    }, receiveValue: { value in
        print("3 received value: ", value)
        sinkValues.append(value)
    })
        .store(in: &store)
}

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
