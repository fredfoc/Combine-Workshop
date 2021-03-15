# Combine (Worshop 2)

## Exemples de Publishers

### Empty

Empty est un publisher qui ne renvoie rien d'autre qu'une completion.
```swift
_ = Empty<Any, Never>(completeImmediately: true)
    .sink(
        receiveCompletion: {
            print("Received completion", $0)

        },
        receiveValue: { _ in }
    )
```

> ——— Example of: Empty ———

Received completion finished

### Fail

Empty est un publisher qui ne renvoie rien d'autre qu'une erreur.
```swift
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
```

> ——— Example of: Fail ———  
> Received completion failure(__lldb_expr_99.(unknown context at $109b2651c).(unknown context at $109b26524).(unknown context at $109b2652c).MyError.test)


### Just

Just est un publisher qui renvoie une valeur unique et une completion. Il ne fail jamais (la signature de son type d'erreur est Never).
```swift
_ = Just("Hello world!")
    .sink(
        receiveCompletion: {
            print("Received completion", $0)
        },
        receiveValue: {
            print("Received value", $0)
        }
    )
```

> ——— Example of: Just ———  
> Received value Hello world!  
> Received completion finished  


### Future

Future est un publisher qui renvoie une valeur unique (comme Just) et une completion mais de manière asynchrone. Contrairement à Just, il peut failer.
```swift
var store = Set<AnyCancellable>()
print(CFAbsoluteTimeGetCurrent())
Future<Int, Never> { promise in
    DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
        promise(.success(1))
    }
}.sink(
    receiveCompletion: {
        print("Received completion", $0)
    },
    receiveValue: {
        print("Received value", $0)
        print(CFAbsoluteTimeGetCurrent())
    }
).store(in: &store)
```

> ——— Example of: Future ———  
> 637490710.891203  
> Received value 1  
> 637490714.190695  
> Received completion finished  


### Un peu plus sur Future
Un Future n'exécute sa promise qu'une seule fois lors de la première souscription. Pour les souscriptions suivantes, il prendra le résultat déjà obtenu.
Exemple :
```swift
var store = Set<AnyCancellable>()
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

future.sink(
    receiveCompletion: {
        print("Received completion from second Subscriber", $0)
    },
    receiveValue: {
        print("Received value from second Subscriber ", $0, " at:", CFAbsoluteTimeGetCurrent())
    }
).store(in: &store)
```
Le résultat obtenu est :

> ——— Example of: More on Future ———  
> *start future at: 637492228.419675*  
> Received value from second Subscriber  1  at: 637492231.751911  
> Received completion from second Subscriber finished  
> Received value from first Subscriber  1  at: 637492231.752345  
> Received completion from first Subscriber finished  

On constate que **start future at: 637492228.419675** n'est éxécuté qu'une seule fois.

Pour être même plus précis, regardons l'exemple ci dessous :
```swift
var store = Set<AnyCancellable>()
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
```
Le résultat obtenu est le suivant :

> ——— Example of: More on Future ———  
> start future at: 637492362.041733  
> Received value from first Subscriber  1  at: 637492365.335676  
> Received completion from first Subscriber finished  
> create second subscriber at *637492366.467773*  
> Received value from second Subscriber  1  at: *637492366.467899*  
> Received completion from second Subscriber finished  

Le second subscriber est créé après la completion du `dispatch` du `Future`. On constate alors que la valeur est envoyée immédiatement au second subscriber (alors que le premier subscriber a reçu une valeur après 3 secondes). C'est normal, le `Future`a déjà généré ses évènements et il les rejoue immédiatement pour toutes nouvelles souscriptions.

### Subject

Subject est un protocol
```swift
public protocol Subject : AnyObject, Publisher {

    /// Sends a value to the subscriber.
    ///
    /// - Parameter value: The value to send.
    func send(_ value: Self.Output)

    /// Sends a completion signal to the subscriber.
    ///
    /// - Parameter completion: A `Completion` instance which indicates whether publishing has finished normally or failed with an error.
    func send(completion: Subscribers.Completion<Self.Failure>)

    /// Sends a subscription to the subscriber.
    ///
    /// This call provides the ``Subject`` an opportunity to establish demand for any new upstream subscriptions.
    ///
    /// - Parameter subscription: The subscription instance through which the subscriber can request elements.
    func send(subscription: Subscription)
}
```
Il permet d'exposer une méthode send sur un Publisher.

### PassthroughSubject

PassthroughSubject est une implémentation concrète du protocol Subject. Un PassthroughSubject n'a pas de valeur par défaut et ne retient pas sa dernière valeur, ce qui signifie qu'un subscriber n'otiendra aucune valeur à la souscription (même si PassthroughSubject a déjà envoyé des valeurs avant), mais seulement lorsque le PassthroughSubject émettra de nouvelles valeurs ou une erreur ou une complétion.

Exemple:

```swift
var store = Set<AnyCancellable>()
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
```

> ——— Example of: PassthroughSubject ———  
> firstSubscription received test  
> firstSubscription received another test  
> secondSubscription received another test  
> Received completion of firstSubscription finished  
> Received completion of secondSubscription finished  

La première souscription reçoit bien la valeur "test" parce que cette valeur est envoyée après la souscription. Par contre la seconde souscription ne reçoit que "another test". On constate en outre que, suite à l'envoi d'un évènement de completion (`.finished`), les souscriptions ne reçoivent plus "Anyone heard me ?". Ce dernier message n'est même jamais émis.

### CurrentValueSubject

CurrentValueSubject est une implémentation concrète du protocol Subject. Contrairement à PassthroughSubject, CurrentValueSubject a toujours une valeur par défaut et renvoie cette valeur à chaque nouvelle souscription.

Exemple:

```swift
var store = Set<AnyCancellable>()
enum MyError: Error {
    case noMoreWord
}
let currentSubject = CurrentValueSubject<String, MyError>("first")
// a first subscription
currentSubject
    .sink(receiveCompletion: {
              print("Received completion of firstSubscription", $0)
          },
          receiveValue: { print("firstSubscription received", $0) })
    .store(in: &store)
currentSubject.send("second")
// a second subscription
currentSubject
    .sink(receiveCompletion: {
              print("Received completion of secondSubscription", $0)
          },
          receiveValue: { print("secondSubscription received", $0) })
    .store(in: &store)
currentSubject.send("third")
currentSubject.send(completion: .failure(MyError.noMoreWord))
currentSubject.send("Anyone heard me ?")
// a third subscription
currentSubject
    .sink(receiveCompletion: {
              print("Received completion of thirdSubscription", $0)
          },
          receiveValue: { print("thirdSubscription received", $0) })
    .store(in: &store)
```

> ——— Example of: CurrentValueSubject ———  
> firstSubscription received first  
> firstSubscription received second  
> secondSubscription received second  
> secondSubscription received third  
> firstSubscription received third  
> Received completion of secondSubscription failure(__lldb_expr_121.(unknown context at $112a6101c).(unknown context at $112a61058).(unknown context at $112a61060).MyError.noMoreWord)  
> Received completion of firstSubscription failure(__lldb_expr_121.(unknown context at $112a6101c).(unknown context at $112a61058).(unknown context at $112a61060).MyError.noMoreWord)  
> Received completion of thirdSubscription failure(__lldb_expr_123.(unknown context at $10b4a001c).(unknown context at $10b4a0058).(unknown context at $10b4a0060).MyError.noMoreWord)  

La première souscription reçoit bien la valeur "first" parce que cette valeur est envoyée par défaut par `currentSubject` . La seconde souscription reçoit "second" qui est la dernière valeur émise par `currentSubject`. On constate en outre que, suite à l'envoi d'un évènement de completion (`.failure`), les souscriptions ne reçoivent plus "Anyone heard me ?". Ce dernier message n'est même jamais émis. La troisième souscription reçoit directement une erreur (le dernier évènement publié par le `currentSubject`)

### Effacement de type (type erasure)

Il arrive parfois (régulièrement en fait) que vous ayez besoin d'"effacer le type" d'un publisher afin que ceux qui vont y souscrirent ne puissent pas poster dessus par exemple. Ce principe s'appelle le "type erasure". Il est porté par le struct suivant :
```swift
/// A publisher that performs type erasure by wrapping another publisher.
///
/// ``AnyPublisher`` is a concrete implementation of ``Publisher`` that has no significant properties of its own, and passes through elements and completion values from its upstream publisher.
///
/// Use ``AnyPublisher`` to wrap a publisher whose type has details you don’t want to expose across API boundaries, such as different modules. Wrapping a ``Subject`` with ``AnyPublisher`` also prevents callers from accessing its ``Subject/send(_:)`` method. When you use type erasure this way, you can change the underlying publisher implementation over time without affecting existing clients.
///
/// You can use Combine’s ``Publisher/eraseToAnyPublisher()`` operator to wrap a publisher with ``AnyPublisher``.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@frozen public struct AnyPublisher<Output, Failure> : CustomStringConvertible, CustomPlaygroundDisplayConvertible where Failure : Error {

    /// A textual representation of this instance.
    ///
    /// Calling this property directly is discouraged. Instead, convert an
    /// instance of any type to a string by using the `String(describing:)`
    /// initializer. This initializer works with any type, and uses the custom
    /// `description` property for types that conform to
    /// `CustomStringConvertible`:
    ///
    ///     struct Point: CustomStringConvertible {
    ///         let x: Int, y: Int
    ///
    ///         var description: String {
    ///             return "(\(x), \(y))"
    ///         }
    ///     }
    ///
    ///     let p = Point(x: 21, y: 30)
    ///     let s = String(describing: p)
    ///     print(s)
    ///     // Prints "(21, 30)"
    ///
    /// The conversion of `p` to a string in the assignment to `s` uses the
    /// `Point` type's `description` property.
    public var description: String { get }

    /// A custom playground description for this instance.
    public var playgroundDescription: Any { get }

    /// Creates a type-erasing publisher to wrap the provided publisher.
    ///
    /// - Parameter publisher: A publisher to wrap with a type-eraser.
    @inlinable public init<P>(_ publisher: P) where Output == P.Output, Failure == P.Failure, P : Publisher
}
```

Exemple :
```swift
struct MyObject {
        private let currentSubject = CurrentValueSubject<String, Error>("first")
        var publisher: AnyPublisher<String, Error> {
            currentSubject.eraseToAnyPublisher()
        }
    }
    let myObject = MyObject()
    myObject
        .publisher
        .sink { print("Received completion", $0)}
        receiveValue: { print("Received", $0)}
    // myObject.publisher.send("something") -> Value of type 'AnyPublisher<String, Error>' has no member 'send'
```
`myObject.publisher.send("something")` ne marchera pas (erreur de compilation : `Value of type 'AnyPublisher<String, Error>' has no member 'send'`).

Exercices :
- créer un distributeur de bonbons (un objet qui renvoie un bonbon lorsqu'on lui demande) avec un suivi parental (les parents sont avertis quand le distributeur a donné plus de x bonbons)
- créer un module qui permet d'avertir des gestionnaires en cas de dépassement bancaire
- créer un module qui permet d'appeler une api de manière asynchrone et de retourner le résultat de l'api (et de se compléter) ou une erreur
- utiliser le module précédent et permettre d'y injecter une api mockée qui renvoie une erreur ou juste résultat immédiatement.

