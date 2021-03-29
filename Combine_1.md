# Combine (Worshop 1)

Workshop de présentation de Combine.

## En bref
Combine est un framework délivré par Apple pour faire du reactive programming

## Reactive Functional Programming

### Imperative programming vs functional programming

#### imperative programming
- décrit **comment** on résoud un problème pas à pas (**how**)
- changement/mutation d'état
- assignations directes
- accès concurrent (non thread safe)
- compliqué à unit tester
- souvent relié à l'utilisation de `class` (mutable, référence)
- meilleure performance

```swift
import Foundation

/*
 dans le tableau suivant je veux remplacer toutes les occurences de "***" par "Pierre", retirer tous les termes qui contiennent "js", puis former une phrase avec des espaces entre les mots, un point à la fin et une majuscule
 */

let mots = ["je", "constate", "que", "***", "est", "une", "buse", "en", "js", "programmation"]

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
}
```

```swift
//imperative
var phrase = ""
for mot in mots {
    if mot.contains("js") {
        continue
    }
    var newMot = mot
    if mot == "***" {
        newMot = "Pierre"
    }
    phrase += newMot + " "
}
phrase = String(phrase.dropLast())
phrase = phrase.capitalizingFirstLetter()
phrase = phrase + "."
print(phrase)
```

#### functional programming
- décrit **ce** qu'on va faire (approche procédurale) (**what**)
- pas (*ou peu*) de changement d'état
- fonctions pures
- plus facile à unit tester
- souvent relié à  l'utilisation de `struct`(immutable, copy)
- moins bonne performance (le hardware actuel n'est pas optimisé pour le functional)
- thread safe

```swift
//functional
let phraseFunc = mots
    .filter{ !$0.contains("js")}
    .map{ $0 == "***" ? "Pierre" : $0}
    .joined(separator: " ")
    .capitalizingFirstLetter()
    .appending(".")
print(phraseFunc)
```

#### functional reactive programming
mélange entre le reactive programming, programmation basée sur la réaction à des évènements et le functional programming.
Le functional programming dans ce cadre permet d'utiliser des fonctions pures et l'immutabilité pour éviter les problème d'accès concurrents liés aux changements d'état et au multi threading.

## Les 3 clés de Combine
- Publisher : un protocol derrière lequel on trouve des objets qui vont emettre des évènements.
    ```swift
    Publisher<Output, Error>
    ```
    Publisher dispose de 2 types associés :
    - Output, pour le type que va émettre un publisher
    - Error, pour le type d'erreur que va émettre un publisher (Never s'il n'émet jamais d'erreur)
    
- Operator : des méthodes qui permettent d'effectuer des opérations sur des publishers.
    ```swift
    var events = [1, 2, 3, 4]
    events.publisher.map {$0 * 10}
    ```
    Ici, `map` est un opérateur sur le publisher `events.publisher`. Le résulta de `map` est lui-même un publisher.
    
- Subscriber : un protocol qui décrit la façon de souscrire à un Publisher.
    ```swift
    var events = [1, 2, 3, 4]
    _ = events
        .publisher
        .map {$0 * 10}
        .sink { print($0)} // print(10, 20, 30, 40)
    ```
    Ici, `.sink { print($0)}` est un subscriber.
    *Remarque importante : un publisher n'émet rien si aucun subscriber ne lui rattaché.*

Une **Subscription** est un protocol mais aussi le cycle complet `Publisher -> Operator -> Subscriber`.

## Vie d'un publisher

Un Publisher peut émettre 3 types d'évènements :
- une valeur (liée au type d'Output du publisher)
- une erreur (liée au type d'erreur du publisher)
- un évènement de completion (finished) lorsque le publisher se termine

Une erreur ou un évènement de completion détermine la fin d'un publisher. Il n'émettra plus jamais d'évènement. Les subscribers qui lui sont reliés sont alors relachés par la mémoire.

Exemples :

**Un exemple de réception de valeur et de completion sans erreur.**

```swift
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
```
- 1 : création d'un publisher (ici un `Just` qui émet un seul évènement et jamais d'erreur `Publisher<String, Never>`)
- 2 : souscription au publisher
- 3 : réception de la valeur (émission d'un évènement de valeur)
- 4 : réception d'un évènement de terminaison (ici `.finished`)

**Un exemple d'émission d'une erreur.**

```swift
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
```
- 1 : création d'un publisher (ici un `Fail` qui émet une erreur `Publisher<Any, MyError>`)
- 2 : souscription au publisher
- 3 : ce block ne sera jamais exécuté
- 4 : réception d'un évènement de terminaison (ici `.failure(__lldb_expr_35.MyError.test)`)

**Un exemple de réception de valeur sans réception de completion.**

```swift
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
subscription.cancel() // 3
```
- 1 : souscription au publisher
- 2 : le post d'une notification est réceptionné par le block `receiveValue`.
- 3 : NotificationCenter ne s'arrète jamais, la souscription restera donc "vivante" et ne sera jamais annulée. Ici on l'annule manuellement. *Attention: le `cancel` n'active pas le block `completion` de la souscription*.

**Une souscription en utilisant `assign(to:on:)`.**

```swift
class SomeObject {
    var value: String = "" {
      didSet {
        print(value)
      }
    }
}
let object = SomeObject()
let publisher = ["Hello", "world!"].publisher
_ = publisher.assign(to: \.value, on: object)
```

## Cancellable (et Subscriber)

Comme dit précédemment, un Publisher ne commence à émettre que lorsqu'un Subscriber lui est rattaché.
Un subscriber s'arrète lorsque :
- le Publisher émet un évènement de competion (`.finished` ou `.failure`)
- le subscriber est annulé : 
    ```swift
    subscriber.cancel()
    ```
- le subscriber est relaché par la mémoire (dans ce cas, `cancel()` est appelé automatiquement)

Le résultat d'une souscription (exemple: le résulta de `sink`) est un AnyCancellable. Cancellable est un protocol implémenté par AnyCancellable. Comme toute variable, AnyCancellable est conservé le temps du flow d'éxecution, ce qui signifie que s'il n'est pas retenu, il est releasé à la fin de l'éxecution est dans ce cadre, cancel() est appelé automatiquement.

Exemples :

```swift
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
```
Dans l'exemple ci-dessus, on pourrait penser que `subscription` va recevoir la notification de post. Cependant, `subscription` disparait à la fin de l'init du struct et donc cancel est appelé et la souscription annulée. Pour que la notification soit reçue, il faut retenir la souscription comme suit :

```swift
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
```
Dans cet exemple, `subscription` disparaitra en même temps que `someStruct`.

## Publisher

```Swift
public protocol Publisher {

    /// The kind of values published by this publisher.
    associatedtype Output

    /// The kind of errors this publisher might publish.
    ///
    /// Use `Never` if this `Publisher` does not publish errors.
    associatedtype Failure : Error

    /// Attaches the specified subscriber to this publisher.
    ///
    /// Implementations of ``Publisher`` must implement this method.
    ///
    /// The provided implementation of ``Publisher/subscribe(_:)-4u8kn``calls this method.
    ///
    /// - Parameter subscriber: The subscriber to attach to this ``Publisher``, after which it can receive values.
    func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input
}
extension Publisher {

    /// Attaches the specified subscriber to this publisher.
    ///
    /// Always call this function instead of ``Publisher/receive(subscriber:)``.
    /// Adopters of ``Publisher`` must implement ``Publisher/receive(subscriber:)``. The implementation of ``Publisher/subscribe(_:)-4u8kn`` provided by ``Publisher`` calls through to ``Publisher/receive(subscriber:)``.
    ///
    /// - Parameter subscriber: The subscriber to attach to this publisher. After attaching, the subscriber can start to receive values.
    public func subscribe<S>(_ subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input
}
```
## Subscriber
```swift
public protocol Subscriber : CustomCombineIdentifierConvertible {

    /// The kind of values this subscriber receives.
    associatedtype Input

    /// The kind of errors this subscriber might receive.
    ///
    /// Use `Never` if this `Subscriber` cannot receive errors.
    associatedtype Failure : Error

    /// Tells the subscriber that it has successfully subscribed to the publisher and may request items.
    ///
    /// Use the received ``Subscription`` to request items from the publisher.
    /// - Parameter subscription: A subscription that represents the connection between publisher and subscriber.
    func receive(subscription: Subscription)

    /// Tells the subscriber that the publisher has produced an element.
    ///
    /// - Parameter input: The published element.
    /// - Returns: A `Subscribers.Demand` instance indicating how many more elements the subscriber expects to receive.
    func receive(_ input: Self.Input) -> Subscribers.Demand

    /// Tells the subscriber that the publisher has completed publishing, either normally or with an error.
    ///
    /// - Parameter completion: A ``Subscribers/Completion`` case indicating whether publishing completed normally or with an error.
    func receive(completion: Subscribers.Completion<Self.Failure>)
}
```
## Subscription
```swift
public protocol Subscription : Cancellable, CustomCombineIdentifierConvertible {

    /// Tells a publisher that it may send more values to the subscriber.
    func request(_ demand: Subscribers.Demand)
}
```

## Création d'un Subscriber Custom

```swift
let publisher = (1...6).publisher // 1
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
publisher.subscribe(subscriber) // 7
```
- 1 : création d'un publisher (Publisher<Int, Never>)
- 2 : création du custom subscriber (qui implémente Subscriber)
- 3 : définition des types associés (Int en Output, Never en Failure). Ces types doivent être identiques aux types du Publisher (voir la méthode subscribe du protocol Subscriber)
- 4 : mise en place de la souscription avec un maximium de 3 réceptions (ce nombre sera ajusté ensuite le cas échéant - ce processus permet d'éviter les phénomènes de back pressure)
- 5 : lors de la réception d'une valeur on print la valeur et on indique qu'on ne demande pas d'ajustement de la souscription (`.none` équivalent à `.max(0)`)
- 6 : réception d'un évènement de completion (`.finished` ou `.failure`)
- 7 : souscription du Subscriber sur le Publisher

Résultat obtenu :

```
——— Example of: Custom Subscriber ———
Received value 1
Received value 2
Received value 3
```

*Remarque : On ne passe pas par la complétion parce que le Subscriber a un max de 3 réceptions et le publisher est complété après 6 émissions.*

Pour modifier ce comportement, il suffit de transfomer le `.none` en `.unlimited`. On reçoit alors le résultat suivant :

```
——— Example of: Custom Subscriber ———
Received value 1
Received value 2
Received value 3
Received value 4
Received value 5
Received value 6
Received completion finished
```

On aurait aussi pu utiliser `.max(1)`. Voir les déclarations ci-dessous pour plus de détail (à noter : `max(-1)` produit une fatalError...)

```swift
/// A request for as many values as the publisher can produce.
public static let unlimited: Subscribers.Demand

/// A request for no elements from the publisher.
///
/// This is equivalent to `Demand.max(0)`.
public static let none: Subscribers.Demand

/// Creates a demand for the given maximum number of elements.
///
/// The publisher is free to send fewer than the requested maximum number of elements.
///
/// - Parameter value: The maximum number of elements. Providing a negative value for this parameter results in a fatal error.
@inlinable public static func max(_ value: Int) -> Subscribers.Demand
```

Fin du premier workshop.

## Petits exercices :

- à partir du tableau suivant (1...7), émettre des évènements de dates allant du 5 au 12 juillet 2021, formattés au format full (Tuesday, November 16, 1937 AD)
- supposons qu'un publisher émette les évènements suivants : "Bonjour", 10, MyObject(), MyError.badEncoding. Que pouvez-vous en dire ?
- donnez un exemple d'abonnement à une notification de type "Login Success"
- transformez un completion block escaping en publisher :
```swift
func test(_ value: String, _ completion: @escaping (String) -> Void) {
    completion(value + "test")
}
```

## License
MIT
**Free Software, Hell Yeah!**
