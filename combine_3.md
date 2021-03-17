# Combine (Workshop 3)

## Opérateurs

Un opérateur est une méthode appliquée sur un publisher et qui retourne un nouveau publisher.

Exemple :
```swift
_ = (1 ... 6)
    .publisher
    .map { $0 * 2 }
    .sink { print($0) }
```

> ——— Example of: map ———  
> 2  
> 4  
> 6   
> 8  
> 10  
> 12  

Marble diagrams : https://rxmarbles.com/

![diagram de map](map_marble.png)

Marble diagrams est un site qui permet de comprendre les opérateurs en recative programming.

### Opérateurs de transformations

#### Collect

Collect permet de tranformer un flux d'évènements en Array.
```swift
var subscriptions = Set<AnyCancellable>()
["A", "B", "C", "D", "E"].publisher
    .collect()
    .sink { print($0) }
    .store(in: &subscriptions)
```

> ——— Example of: collect ———  
> ["A", "B", "C", "D", "E"]  

Attention, si on ne précise pas de chiffre dans `collect` alors il reprend tout le flux. On peut préciser le regroupement de la manière suivante : `collect(2)`.
```swift
var subscriptions = Set<AnyCancellable>()
["A", "B", "C", "D", "E"].publisher
    .collect(2)
    .sink { print($0) }
    .store(in: &subscriptions)
```

> ——— Example of: collect ———  
> ["A", "B"]  
> ["C", "D"]  
> ["E"]  

Si le publisher ne complete pas alors collect ne renvoie jamais rien !

Exemple :
```swift
var subscriptions = Set<AnyCancellable>()
let currentSubject = CurrentValueSubject<String, Never>("first")
currentSubject
    .collect()
    .sink(receiveCompletion: {
              print("Received completion", $0)
          },
          receiveValue: { print("Received", $0) })
    .store(in: &subscriptions)
currentSubject.send("second")
currentSubject.send(completion: .finished)
```

> ——— Example of: collect on subject ———  
> Received ["first", "second"]  
> Received completion finished  

Si on enlève la ligne `currentSubject.send(completion: .finished)` alors le subscriber ne reçoit jamais rien.
Si le publiser envoie une erreur alors le `collect` ne renverra aucune valeur (seulement l'erreur).

#### Map

Map permet de transformer une valeur.
```swift
_ = (1 ... 6)
    .publisher
    .map { $0 * 2 }
    .sink { print($0) }
```
Ici on multiplie chaque valeur par 2.

> ——— Example of: map ———  
> 2  
> 4  
> 6   
> 8  
> 10  
> 12  

Dans cet autre exemple, on "mappe" un nombre vers une string. On notera que `[123, 4, 56].publisher` renvoie un `Publishers.Sequence<[Int], Never>` et qu'à la sortie du map on obtient un `Publishers.Sequence<[String], Never>`. Le `map` a changé le type d'output du publisher pas son type d'erreur.

```swift
var subscriptions = Set<AnyCancellable>()
let formatter = NumberFormatter()
formatter.numberStyle = .spellOut
[123, 4, 56]
    .publisher
    .map {
        formatter.string(for: NSNumber(integerLiteral: $0)) ?? ""
    }
    .sink(receiveValue: { print($0) })
    .store(in: &subscriptions)
```

Il existe aussi une méthode `map<T>`, qui permet de mapper des keypaths directement. C'est parfois utile quand on ne veut utiliser qu'une seule variable d'un objet (on peut aller jusqu'à un tuple de 3 : `map<T, U, V>`)

Exemple :
```swift
struct MyObject {
    let x: Int
    let y: Int
}
let subject = PassthroughSubject<MyObject, Never>()
subject
    .map(\.x, \.y)
    .sink { x, y in
        print(x, "-", y)
    }
    .store(in: &subscriptions)
subject.send(MyObject(x: 10, y:20))
```
Remarque : notez la nouvelle façon de pointer un keypath avec la notation `\.maVar`. Le Keypath permet de pointer une propriété d'un objet et pas sa valeur. En théorie, ici on aurait du écrire `\MyObject.x`, mais Swift sait inférer le type d'objet depuis le type du publisher.

`tryMap` est un opérateur qui, comme son nom l'indique, va "tenter" de mapper une valeur et s'il échoue va renvoyer une erreur sur le publisher.

Exemple :
```swift
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
```

Le résultat est intéressant :

> ——— Example of: tryMap ———  
> Received MyObject(name: "Fred")  
> Received completion failure(Swift.DecodingError.typeMismatch(Swift.Dictionary<Swift.String, Any>, Swift.DecodingError.Context(codingPath: [], debugDescription: "Expected to decode Dictionary<String, Any> but found a number instead.", underlyingError: nil)))

Le second decodage échoue, `tryMap` émet une erreur, le publisher s'arrète.

On trouve des `try` + `Method` pour de nombreux opérateurs en Combine (Exemple : `reduce`, `filter`, `scan`, `min`, etc).

#### Flatmap

Voilà un opérateur intéressant, mais toujours évident à comprendre.  
Partons d'un exemple :  
Imaginons que vous attendiez le résultat d'un publisher pour ensuite créer un autre publisher et que vous souhaitiez vous abonner à ce dernier publisher.  
`Flatmap`est là pour ça. Il va "écraser" les deux publishers en un seul.

```swift
var subscriptions = Set<AnyCancellable>()
["A", "B", "C", "D", "E"].publisher
    .collect(2)
    .flatMap { sequence in
        Just(sequence.joined(separator: "-"))
            .eraseToAnyPublisher()
    }
    .sink { print($0) }
    .store(in: &subscriptions)
```

> ——— Example of: Flatmap ———  
> A-B  
> C-D  
> E

Evidemment, cet exemple est très simple et il aurait pu être réalisé avec un map. Nous verrons l'intérêt de `flatmap` en utilisant les DataTaskPublisher qui permettent d'effectuer des appels vers des api.

L'exemple ci-dessus aurait aussi pu être réalisé comme suit :

```swift
var subscriptions = Set<AnyCancellable>()
func join(_ sequence: [String]) -> AnyPublisher<String, Never> {
    Just(sequence.joined(separator: "-"))
        .eraseToAnyPublisher()
}
["A", "B", "C", "D", "E"].publisher
    .collect(2)
    .flatMap(join)
    .sink { print($0) }
    .store(in: &subscriptions)
```
Ce qui le rend encore plus élégant (à mon avis, mais c'est subjectif...)

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

## License
MIT
**Free Software, Hell Yeah!**