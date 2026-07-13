---
name: Stabilizacja CaliPark przed dalszymi widokami
overview: "Krótki sprint stabilizacyjny utrwalający wzorzec MVVM (fit) w całej apce: naprawa tożsamości mocków, DI zamiast singletonów, usunięcie szablonowego kodu Xcode, widoczne błędy, uprawnienia i pierwsze testy — bez decyzji backendowej, która pozostaje odłożona i nieblokująca."
todos:
  - id: fix-mock-uuids
    content: Stałe UUID w Park.mock i User.mock, weryfikacja relacji wydarzeń/opinii
    status: completed
  - id: premium-favorites
    content: Premium domyślnie false + persystencja ulubionych w UserDefaults
    status: completed
  - id: remove-template
    content: Usunąć szablon Xcode (ContentView, encja Item) i martwe widoki, konsolidacja mocków
    status: completed
  - id: app-environment
    content: AppEnvironment jako composition root, likwidacja singletonu serwisu zdjęć
    status: completed
  - id: surface-errors
    content: Alerty błędów w photos i reviews ViewModelach + uchwyty zadań i anulowanie
    status: completed
  - id: split-maintab
    content: Wydzielić placeholderowe zakładki z MainTabView do osobnych plików
    status: completed
  - id: config-fixes
    content: Privacy keys (lokalizacja, biblioteka zdjęć), AppIcon, poprawa deprecated onChange
    status: completed
  - id: first-tests
    content: "Testy: ParksViewModel, relacje park-wydarzenia-opinie, stany błędów"
    status: completed
isProject: false
---

# Stabilizacja CaliPark przed dalszymi widokami

> **Zasada dla agentów:** NIE uruchamiać `xcodebuild` ani żadnej weryfikacji kompilacji — build i testy sprawdza wyłącznie użytkownik ręcznie w Xcode.

Architektura: zostajemy przy **MVVM (fit)** wg `references/mvvm.md` — Parks już tak działa, rozciągamy wzorzec na resztę. Żadnych nowych zależności (bez TCA). Backend: **decyzja odłożona** — sprint przygotowuje protokoły serwisów tak, żeby wybór (BaaS / FastAPI / Rust) był później czystą podmianą implementacji.

## Etap A — naprawa danych (blokujące bugi)

- **Stałe UUID w mockach** — [cali-park/Features/Parks/Models/Park.swift](cali-park/Features/Parks/Models/Park.swift) (linia 99: `static let mock` z `UUID()`) i [User.swift](cali-park/Features/Parks/Models/User.swift) (linia 13: computed `var mock` — nowe UUID przy każdym odczycie). Zamiana na `UUID(uuidString:"…")!` naprawia puste sekcje wydarzeń/opinii w detalu parku, bo `ParkEvent.events(for:)` i seed `ReviewsService` filtrują po `parkID`.
- **Premium domyślnie `false`** — [ParkDetailView.swift](cali-park/Features/Parks/Views/ParkDetailView.swift) linia 10 (`var isPremiumUser: Bool = true`).
- **Ulubione do UserDefaults** — `ParksViewModel.toggleFavorite` zapisuje zbiór ID; `loadParks()` odtwarza flagi (dziś `refresh()` kasuje ulubione).

## Etap B — sprzątanie szablonu Xcode i duplikatów

- Usunąć: [App/ContentView.swift](cali-park/App/ContentView.swift), `GymCatalogView` z [MainTabView.swift](cali-park/Features/Main/MainTabView.swift) (linie 70–118), [Components/FixedHeaderView.swift](cali-park/Components/FixedHeaderView.swift), nieużywany `PhotoCommentsSheetView`, `addRandomMockPhoto()`.
- Core Data: usunąć encję `Item` i `preview` z [Persistence.swift](cali-park/Core/Services/Persistence.swift); sam `PersistenceController` zostaje jako pusty szkielet na przyszłą lokalną persystencję (bez `fatalError` — log + degradacja).
- Skonsolidować mocki Home: usunąć duplikat `MockData` z [HomeModels.swift](cali-park/Features/Home/Models/HomeModels.swift), zostaje jeden `MockDataProvider`.

## Etap C — MVVM/DI zgodnie ze skillem

- **Composition root `AppEnvironment`** (nowy plik w `Core/`): tworzy serwisy i wstrzykuje przez `init` — likwidacja `InMemoryCommunityPhotoService.shared` ([CommunityPhotoService.swift](cali-park/Features/Parks/Services/CommunityPhotoService.swift) linia 24).
- **Widoczne błędy**: `.alert` podpięty pod `errorMessage` w [ParkPhotosViewModel.swift](cali-park/Features/Parks/ViewModels/ParkPhotosViewModel.swift); dodanie `@Published errorMessage` do [ParkReviewsViewModel.swift](cali-park/Features/Parks/ViewModels/ParkReviewsViewModel.swift) (dziś puste `catch` w liniach 90 i 112).
- **Uchwyty zadań + anulowanie** (swift-concurrency-pro): `Task { await load() }` w initach `ParkReviewsViewModel` i `ParkPhotosViewModel` bez uchwytu — trzymać `loadTask: Task<Void, Never>?`, anulować przed nowym żądaniem i w `deinit` (ochrona przed stale-overwrite po podpięciu prawdziwego backendu).
- Home bez refaktoru totalnego — tylko wydzielenie placeholderowych zakładek z `MainTabView.swift` do osobnych plików (plik ma 352 linie, limit soft 200). Przy okazji wydzielania: usunąć blok `UITabBarAppearance`/`UIColor` z `onAppear` (UIKit zakazany w regułach projektu — zastąpić `.toolbarBackground`/`.tint`), zamienić `NavigationView` → `NavigationStack` i deprecated `.accentColor` → `.tint`.

## Etap D — konfiguracja i testy

- **Privacy keys** w ustawieniach targetu: `NSLocationWhenInUseUsageDescription` (wymagane przez `MapUserLocationButton` w `MapSheetView`), `NSPhotoLibraryAddUsageDescription`.
- **AppIcon**: dodać plik 1024×1024 (choćby tymczasowy) — dziś appiconset jest pusty.
- **Deprecated `onChange`** (3 pliki: `AddParkPhotoSheetView`, `ParkPhotoGalleryView`, `AddReviewSheetView`) → wersja dwuargumentowa.
- **Pierwsze testy** (Swift Testing, już skonfigurowane): filtr/sort/ulubione w `ParksViewModel`, relacja park→wydarzenia→opinie po stałych UUID, stany błędów w reviews VM. Zasady (swift-testing-pro + concurrency): struktury nie klasy, `#expect`/`#require`, filtr/sort jako testy parametryzowane (`@Test(arguments:)`), **wstrzykiwane stuby przez continuation — nie seedowany `ReviewsService` z `Task.sleep`**; dodatkowo ścieżka anulowania (nowsze żądanie nie jest nadpisywane przez stalsze).

## Poza zakresem (świadomie)

- Wybór backendu — osobna rozmowa po sprincie; protokoły serwisów będą gotowe na każdą opcję. **Zasady bezpieczeństwa na tę chwilę** (swift-security-expert): tokeny/credentials wyłącznie w Keychain, nigdy w `UserDefaults`/`Info.plist`; status premium wyprowadzany ze StoreKit/backendu, nigdy jako persystowana flaga w `UserDefaults` (podrabialny plist). Ulubione parki to nie sekret — `UserDefaults` OK.
- Nowe ekrany Ćwiczenia/Społeczność/Profil — wracamy do nich po stabilizacji („najpierw widoki" — ale na zdrowym fundamencie).

Weryfikacja: build w Xcode + testy jednostkowe + ręczny smoke test detalu parku (wydarzenia i opinie muszą się pokazać).