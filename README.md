# CodingChallenge

A small SwiftUI app that consumes the GitHub public API to play with emojis, user
avatars and Apple's repositories. Built with a feature-modular, testable
architecture and SwiftData for local persistence.

## Features

The app is a single stack of screens reachable from the main screen, mapping to
the challenge tasks:

| Task      | Feature          | Notes                                                                      |
| --------- | ---------------- | -------------------------------------------------------------------------- |
| 1         | Fetch all emojis | GitHub returns a `Map<String, String>`; decoded into a list and persisted  |
| 2         | Local Storage    | API calls are stored to SwiftData                                          |
| 3         | Cache            | API is only called when there is no cached data or on pull to refresh      |
| 4         | Random Emoji     | Shows a random emoji from the cached set on each tap                       |
| 5         | Emoji List       | Grid of all emojis; tapping one hides it (in memory only, order preserved) |
| 5 + bonus | Pull-to-refresh  | Resets the list and reloads all emojis                                     |
| 7         | Avatar search    | Search a GitHub user by name, fetch and store their avatar (cache-first)   |
| 8         | Avatar List      | History of searched avatars; deleting an item removes it from the DB       |
| 9         | Apple Repos      | All of Apple's repos with pagination (10 per page, infinite scroll)        |

### Endpoints used

- `GET https://api.github.com/emojis`
- `GET https://api.github.com/users/:username`
- `GET https://api.github.com/users/:username/repos?page=&per_page=`

Pagination for Apple repos relies on the response's `Link` header (`rel="next"`)
to decide whether more pages exist, rather than guessing from the page size.

## Tech stack

- **Swift** / **SwiftUI**
- **SwiftData** for local persistence (in-memory store used in tests)
- **Swift Concurrency** (`async/await`, `@MainActor`)
- **Swift Testing** for unit tests
- Xcode 26.x · iOS 26.4 deployment target

## Architecture

The project follows a layered, feature-modular approach (a pragmatic Clean
Architecture):

```
feature/
├── data/          # DTOs (API shape), Entities (@Model), API clients
├── domain/        # Value types (UI shape) + Repository (protocol + impl)
└── presentation/  # ViewModels (state machine) + SwiftUI Views
```

Key conventions:

- **Three model shapes, decoupled:**
  - `DTO` Used to decode JSON from the API.
  - `Entity` (`@Model`, persisted) Used to persist data in SwiftData.
  - `Value` (immutable, what the UI consumes) Used by the UI to display data.
- **Repositories.** Each repository owns the cache-vs-network
  decision and is injected via its protocol, so it can be mocked in tests.
- **Unidirectional view models.** Every view model conforms to a generic
  `ViewModel<State, Events>` contract: a `@Published` `State` enum and an
  `async send(_:)` that handles `Events`. Views render state and dispatch events.
- **Dependency injection via a composition root.** Dependencies (API clients,
  repositories, the shared `ModelContainer`) are constructed in
  `CodingChallengeBApp` and injected downward through initialisers.
  This can be improved by using a Service Locator or a third party dependency injection.
  Manually initializing dependencies leads to maintainability issues in large projects.
- **Navigation** is driven by a typed `AppRouter` backed by a
  `NavigationStack` path.

### Project structure

```
CodingChallengeB/
├── CodingChallengeBApp.swift        # @main · ModelContainer · composition root
├── app/
│   ├── core/
│   │   ├── navigation/AppRouter.swift
│   │   ├── viewmodel/ViewModel.swift
│   │   └── ui/                      # CachedAsyncImage, ImageCache
│   └── features/
│       ├── emojis/                  # emojis random and list feature
│       ├── avatars/                 # avatar search and history feature
│       ├── appleRepos/              # apple's repos list feature
│       └── main/                    # main screen + view model
├── CodingChallengeBTests/           # Swift Testing unit tests
└── CodingChallengeBUITests/         # UI test target
```

## Getting started

### Requirements

- Xcode 26.x
- iOS 26.4 simulator (or device)

## Git workflow

Work is organised with a Git Flow–style branching model — one feature branch per
area (`feat/emojis`, `feat/avatars`, `feat/apple_repo`) merged back into `main`.

## Possible improvements

- Improve error management
  - Surface API rate-limit / error states more explicitly in the UI.
  - Show no internet connection
  - Show avatar not found (maybe a default avatar)
- Better dependency injection
- Move large SwiftData writes (the full emoji set) off the main `ModelContext`.
