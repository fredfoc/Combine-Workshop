# Combine (Workshop 4)

## Networking

Utiliser Combine pour le networking

Remarque : tous les example suivants fonctionnent avec

```swift
var subscriptions = Set<AnyCancellable>()
```
### extension sur URLSession

URLSession est une API qui permet de gérer le réseau en iOS.

#### dataTaskPublisher(for:)

`dataTaskPublisher(for:)` est un publisher permet de récupérer la réponse d'un webservice sous la forme d'un `URLSession.DataTaskPublisher`.

```swift
let subscription = URLSession.shared
  .dataTaskPublisher(for: url)
  .sink(receiveCompletion: { completion in
    if case .failure(let err) = completion {
      print("Retrieving data failed with error \(err)")
    }
  }, receiveValue: { data, response in
    print("Retrieved data of size \(data.count), response = \(response)")
  })
```

On récupère dans le `receiveValue` un tuple sous la forme `(data: Data, response: URLResponse)`.

Il existe aussi une méthode `dataTaskPublisher(for:)` avec une URLRequest pour pouvoir customiser les header par exemple.

Une fois les data récupéréres, le principe est alors de les décoder vers un struct resepctant le protocol `Codable` en utilisant l'opérateur `decode` avec un `TopLevelDecoder`.

```swift
URLSession.shared
    .dataTaskPublisher(for: request)
    .decode(type: ...
```

#### multicast

Il est en fait assez compliqué d'attendre le résultat d'un webservice et de le propager à plusieurs subscribers de manière identique. On pourrait utiliser `share` mais il faudrait que le webservice se termine après les souscriptions.

Dans ce cas, on utilise alors `multicast`.

```swift
let publisher = URLSession.shared
    .dataTaskPublisher(for: URL(string: "https://www.google.be")!)
    .multicast { PassthroughSubject<(data: Data, response: URLResponse), URLError>() }

publisher
    .sink(receiveCompletion: { completion in
        if case let .failure(err) = completion {
            print("Sink1 Retrieving data failed with error \(err)")
        }
    }, receiveValue: { data, response in
        print("Retrieved data of size \(data.count), response = \(response)")
    })
    .store(in: &subscriptions)

publisher
    .sink(receiveCompletion: { completion in
        if case let .failure(err) = completion {
            print("Sink2 Retrieving data failed with error \(err)")
        }
    }, receiveValue: { data, response in
        print("Retrieved data of size \(data.count), response = \(response)")
    })
    .store(in: &subscriptions)

publisher.connect()
```

## Exercice :

En utilisant l'API `https://dummyapi.io/data/api/user`, récupérer un/les user(s) sous la forme sérialisée (Créez le struct User).

## License
MIT
**Free Software, Hell Yeah!**