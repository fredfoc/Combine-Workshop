# Combine

En bref, Combine est un framework délivré par Apple pour faire du reactive programming

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
        .sink { print($0)} // print(1, 2, 3, 4)
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
- 1 : création d'un publisher (ici un `Fail` qui émet une erreur `Publisher<String, Never>`)
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

**Une souscription en utilisant assign(to:on:).**

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

## Subscriber

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
```

| Plugin | README |
| ------ | ------ |
| Dropbox | [plugins/dropbox/README.md][PlDb] |
| GitHub | [plugins/github/README.md][PlGh] |
| Google Drive | [plugins/googledrive/README.md][PlGd] |
| OneDrive | [plugins/onedrive/README.md][PlOd] |
| Medium | [plugins/medium/README.md][PlMe] |
| Google Analytics | [plugins/googleanalytics/README.md][PlGa] |


## License
MIT
**Free Software, Hell Yeah!**
