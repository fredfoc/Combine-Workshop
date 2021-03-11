import Foundation
import Combine

func example(of description: String,
                    action: () -> Void) {
  print("\n——— Example of:", description, "———")
  action()
}

example(of: "simple events") {
    let events = [1, 2, 3, 4]
    _ = events
        .publisher
        .map {$0 * 10}
        .sink { print($0)}
}


example(of: "receiving a value") {
    let myNotification = Notification.Name("MyNotification")
    let publisher = NotificationCenter.default.publisher(for: myNotification, object: nil)
    // 1
    let subscription = publisher.sink { (completion) in
        switch completion {
        case .finished:
            print("finished")
        }
    } receiveValue: { _ in
        print("notif received")
    }
    NotificationCenter.default.post(name: myNotification, object: nil) // 2
    subscription.cancel()// 3
}


example(of: "receiving an error") {
    enum MyError: Error {
        case test
    }
    // 1
    let fail = Fail<Any, MyError>(error: MyError.test)
    // 2
    _ = fail
    .sink(
      receiveCompletion: {
        print("Received completion", $0) // 4
      },
      receiveValue: {
        print("Received value", $0) // 3
    })
}

example(of: "receiving a completion") {
    // 1
    let just = Just("Hello world!")
    // 2
    _ = just
    .sink(
      receiveCompletion: {
        print("Received completion", $0) // 4
      },
      receiveValue: {
        print("Received value", $0) // 3
    })
}

example(of: "receiving only a completion") {
    // 1
    let empty = Empty<Any, Error>(completeImmediately: true)
    // 2
    _ = empty
    .sink(
      receiveCompletion: {
        print("Received completion", $0) // 4
      },
      receiveValue: {
        print("Received value", $0) // 3
    })
}

example(of: "assign") {
    // 1
    class SomeObject {
    var value: String = "" {
      didSet {
        print(value)
      }
    }
    }

    // 2
    let object = SomeObject()

    // 3
    let publisher = ["Hello", "world!"].publisher

    // 4
    _ = publisher
    .assign(to: \.value, on: object)
}

example(of: "cancel") {
    struct SomeStruct {
        let myNotification = Notification.Name("MyNotification")
        init() {
            let subscription = NotificationCenter.default
                .publisher(for: myNotification, object: nil)
                .sink { (completion) in
                switch completion {
                case .finished:
                    print("finished")
                }
            } receiveValue: { _ in
                print("notif received")
            }
        }
        func post() {
            NotificationCenter.default.post(name: myNotification, object: nil)
        }
    }
    let someStruct = SomeStruct()
    someStruct.post()
}

example(of: "cancel et retain") {
    struct SomeStruct {
        let myNotification = Notification.Name("MyNotification")
        let subscription: AnyCancellable?
        init() {
            subscription = NotificationCenter.default
                .publisher(for: myNotification, object: nil)
                .sink { (completion) in
                switch completion {
                case .finished:
                    print("finished")
                }
            } receiveValue: { _ in
                print("notif received")
            }
        }
        func post() {
            NotificationCenter.default.post(name: myNotification, object: nil)
        }
    }
    let someStruct = SomeStruct()
    someStruct.post()
}

example(of: "Custom Subscriber") {
  // 1
  let publisher = (1...6).publisher
  
  // 2
  final class IntSubscriber: Subscriber {
    // 3
    typealias Input = Int
    typealias Failure = Never

    // 4
    func receive(subscription: Subscription) {
      subscription.request(.max(3))
    }
    
    // 5
    func receive(_ input: Int) -> Subscribers.Demand {
      print("Received value", input)
      return .none
    }
    
    // 6
    func receive(completion: Subscribers.Completion<Never>) {
      print("Received completion", completion)
    }
  }
    
    let subscriber = IntSubscriber()

    publisher.subscribe(subscriber)
}





