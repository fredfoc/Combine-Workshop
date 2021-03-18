# Combine (Workshop 3)

## Opérateurs (suite)

Suite de la présentation des opérateurs.

Pour la suite, nous utiliserons parfois le terme stream en remplacement du terme publisher. Un stream est un flux d'évènements se terminant par une completion ou une erreur.

Remarque : tous les example suivants fonctionnent avec

```swift
var subscriptions = Set<AnyCancellable>()
```

### Opérateurs mathématiques

Nous ne couvrirons pas tous les opérateurs mathématiques. Il y en a 3 (sans compter les try) : `min()`, `max()` et `count()`.

Exemple :

```swift
[-1, 0, 10, 5]
    .publisher
    .min()
    .sink { print("\($0)") }
    .store(in: &subscriptions)
```

> ——— Example of: min ———  
> -1

A noter que `min` (comme les autres opérateurs mathématiques) réclame un nombre illimité d'évènements au stream sur lequel il est attaché, ce qui signifie qu'il attend une completion de ce stream pour sortir un résultat (voir `reduce`).

On comprendra facilement le sens des 2 autres opérateurs.

Il existe aussi des versions `min(by:)` et `max(by:)` qui permettent de choisir la méthode de comparaison via une closure.

### Opérateurs avec critère de matching

#### contains(_:)

`contains(_:)` permet de vérifier qu'un stream contient un élément donné. Dès que le critère est rencontré, l'opérateur émet un true et se termine. Si le stream se termine sans rencontrer de critère de matching, l'opérateur renvoie false et se termine.

```swift
[-1, 0, 10, 5]
    .publisher
    .contains(5)
    .sink { print("\($0)") }
    .store(in: &subscriptions)
```

> ——— Example of: contains ———
> true

Le stream sur lequel s'applique cet opérateur ne peut pas renvoyer d'erreur.
```swift
struct MyError: Error { }
let subject = CurrentValueSubject<Int, MyError>(0)
subject
    .contains(5) // génère une erreur de compilation
    .sink { print("\($0)") }
    .store(in: &subscriptions)
```

> Referencing instance method 'sink(receiveValue:)' on 'Publisher' requires the types 'Publishers.Contains<CurrentValueSubject<Int, MyError>>.Failure' (aka 'MyError') and 'Never' be equivalent

On voit bien que le compilateur attend une erreur de type Never qui est incompatible avec le type MyError.

#### allSatisfy(_:)

 `allSatisfy(_:)` permet de vérifier qu'un stream contient un élément donné. De la même manière que `reduce` cet opérateur attend la fin du stream pour donner une réponse. Le stream doit avoir un type de Failure égal à Never (comme `contains`.

```swift
[-1, 0, 10, 5]
    .publisher
    .allSatisfy({$0 < 11})
    .sink { print("\($0)") }
    .store(in: &subscriptions)
```

> ——— Example of: allSatisfy ———  
> true

### Opérateurs de limitation du stream

#### dropFirst(_:)

 `dropFirst(_:)` retire le nombre d'évènements spécifié et republie le reste. Si le stream se termine avant, l'opérateur forward la completion.

```swift
(1 ... 10)
    .publisher
    .dropFirst(5)
    .sink(receiveCompletion: { print($0) },
          receiveValue: { print($0, terminator: " ") })
    .store(in: &subscriptions)
```

> ——— Example of: dropFirst ———  
> 6 7 8 9 10 finished

#### drop(while:)

 `drop(while:)` retire les évènements tant que la condition spécifiée n'est pas rencontrée et republie le reste ensuite. Si le stream se termine avant, l'opérateur forward la completion.

```swift
(1 ... 10)
    .publisher
    .drop(while: { $0 < 5 })
    .sink(receiveCompletion: { print($0) },
          receiveValue: { print($0, terminator: " ") })
    .store(in: &subscriptions)
```

> ——— Example of: dropWhile ———  
> 5 6 7 8 9 10 finished

#### drop(untilOutputFrom:)

 `drop(while:)` retire les évènements tant que le second stream ne publie rien et republie le reste ensuite. Si le stream se termine avant, l'opérateur forward la completion.

```swift
let upstream = PassthroughSubject<Int,Never>()
let second = PassthroughSubject<String,Never>()
upstream
    .drop(untilOutputFrom: second)
    .sink { print("\($0)", terminator: " ") }
    .store(in: &subscriptions)

upstream.send(1)
upstream.send(2)
second.send("A")
upstream.send(3)
upstream.send(4)
```

> ——— Example of: dropUntil ———  
> 3 4

#### prefix(while:), prefix(), prefix(untilOutputFrom:)

`prefix` fait la même chose que drop mais dans le sens contraire. Il émet tant que la condition n'est pas rencontrée puis se termine.

```swift
(1 ... 10)
    .publisher
    .prefix(while: { $0 < 5 })
    .sink(receiveCompletion: { print($0) },
          receiveValue: { print($0, terminator: " ") })
    .store(in: &subscriptions)
```

> ——— Example of: prefix ———  
> 1 2 3 4 finished

### Opérateurs d'ajout sur le stream

Il existe deux opérateurs pour ajout des events au stream : `append` et `prepend`. `append` ajoute en fin de stream, `prepend` en début de stream.

```swift
(1 ... 10)
    .publisher
    .prepend(-1, -2)
    .sink(receiveCompletion: { print($0) },
          receiveValue: { print($0, terminator: " ") })
    .store(in: &subscriptions)
```

> ——— Example of: prepend ———  
> -1 -2 1 2 3 4 5 6 7 8 9 10 finished

### Opérateurs de sélection

#### first()

`first()` sélectionne le premier évènement d'un stream.

```swift
(1 ... 10)
    .publisher
    .first()
    .sink(receiveCompletion: { print($0) },
          receiveValue: { print($0, terminator: " ") })
    .store(in: &subscriptions)
```

> ——— Example of: first ———  
> 1 finished

#### first(where:)

`first(where:)` sélectionne le premier évènement d'un stream lorsque la condition est rencontrée.

```swift
(1 ... 10)
    .publisher
    .first(where: { $0 > 5 })
    .sink(receiveCompletion: { print($0) },
          receiveValue: { print($0, terminator: " ") })
    .store(in: &subscriptions)
```

> ——— Example of: first(where:) ——— 
> 6 finished

Si la condition n'est jamais rencontrée et que le stream s'arrète alors `first(where:)` émet un évènement de terminaison (ici on pourrait envisager un `replaceEmpty(with:)`).

#### last(), last(where:)

De la même manière que `first`, `last` prend le dernier évènement d'un stream, le publie et se termine.

```swift
(1 ... 10)
    .publisher
    .last()
    .sink(receiveCompletion: { print($0) },
          receiveValue: { print($0, terminator: " ") })
    .store(in: &subscriptions)
```

> ——— Example of: last ———  
> 10 finished

#### output(at:)

`output(at:)` prend l'évènement d'un stream situé à l'index (zero based) défini, le publie et se termine.

```swift
(1 ... 10)
    .publisher
    .output(at: 5)
    .sink(receiveCompletion: { print($0) },
          receiveValue: { print($0, terminator: " ") })
    .store(in: &subscriptions)
```

> ——— Example of: ouput(at:) ———  
> 6 finished

Remarque : Il existe aussi `output(in:)` lorsqu'on veut les évènements dans un range d'index.

## Exercices :

- dans une liste de mots, sélectionner le premier mot de plus de 5 lettres
- dans une liste de mots, sélectionner le mot le plus long
- vérifier que tous les mots présents dans une liste sont des verbes du premier groupe
- prendre un mot, le splitter en charactères er vérifier qu'il contient un @.
- dans une liste de mots, ne prendre que les 5 premiers mots
- dans une liste de mots arrèter le flux dès qu'un mot est considéré comme une insulte, ajouter une remarque sur l'interdiction des insultes et terminer le flux
- mettre en place un système qui détecte un mot clé dans un flux, renvoie ce mot clé précédé d'une autre information (exemple : ["hello", "je", "teste", "mot-cle", "ici."] -> "le mot clé est :" , "mot-cle")