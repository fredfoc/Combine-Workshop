# Combine (Workshop 3)

## Debugging

Suite de la présentation des opérateurs.

Remarque : tous les example suivants fonctionnent avec

```swift
var subscriptions = Set<AnyCancellable>()
```
### Opérateurs de debug

#### breakpoint(receiveSubscription:receiveOutput:receiveCompletion:)

`breakpoint(receiveSubscription:receiveOutput:receiveCompletion:)` est un publisher qui lève un SIGTRAP dans le debugger (et uniquement dans le debugger) si les conditions dans les completions sont rencontrées.

```swift
let publisher = PassthroughSubject<String?, Never>()
publisher
    .breakpoint(
        receiveOutput: { value in return value == "DEBUGGER" }
    )
    .sink { print("\(String(describing: $0))" , terminator: " ") }
    .store(in: &subscriptions)

publisher.send("DEBUGGER")
```

Le debugger émet une erreur parce que le publisher est rentré dans la condition.

`error: Execution was interrupted, reason: signal SIGTRAP.
The process has been left at the point where it was interrupted, use "thread return -x" to return to the state before expression evaluation.`

#### breakpointOnError()

`breakpointOnError()` est un publisher qui lève un SIGTRAP dans le debugger (et uniquement dans le debugger) en cas d'erreur du stream.

```swift
struct CustomError: Error {}
let publisher = PassthroughSubject<String?, Error>()
publisher
    .tryMap { _ in
        throw CustomError()
    }
    .breakpointOnError()
    .sink(
        receiveCompletion: { completion in print("Completion: \(String(describing: completion))") },
        receiveValue: { aValue in print("Result: \(String(describing: aValue))") }
    )
    .store(in: &subscriptions)

publisher.send("TEST DATA")
```

Lors de l'envoi de l'erreur on récupère un breakpoint dans le debugger avec un `error: Execution was interrupted, reason: signal SIGTRAP.
The process has been left at the point where it was interrupted, use "thread return -x" to return to the state before expression evaluation..

#### print(_:to:)

`print(_:to:)` permet de printer chaque évènement relié au publisher associé.

```swift
let integers = (1...2)
integers.publisher
   .print("Logged a message", to: nil)
   .sink { _ in }
   .store(in: &subscriptions)
```

> ——— Example of: print ———  
> Logged a message: receive subscription: (1...2)  
> Logged a message: request unlimited  
> Logged a message: receive value: (1)  
> Logged a message: receive value: (2)  
> Logged a message: receive finished


## License
MIT
**Free Software, Hell Yeah!**