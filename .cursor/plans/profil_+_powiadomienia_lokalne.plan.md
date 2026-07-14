---
name: Profil + powiadomienia lokalne
overview: "Dwa nowe tematy po ukończeniu planu „Zakładka Ćwiczenia + dziennik\" (S1–S8): (A) powiadomienia lokalne dla harmonogramu planów treningowych, (B) zakładka Profil (onboarding + statystyki z logów). MVVM jak dotąd, zero nowych zależności, persystencja za protokołami. Praca podzielona na 4 sprinty wykonywane przez osobnych agentów — status w docs/SPRINTS-profil-powiadomienia.md."
todos:
  - id: n1-model
    content: "S1: reminderTime (DateComponents?) w WorkoutPlan (wstecznie zgodny) + WorkoutReminderRequest (czysta wartość opisująca przypomnienie)"
    status: completed
  - id: n1-planner
    content: "S1: WorkoutReminderPlanner — czysty builder requestów z aktywnych planów (weekly→per-dzień repeat, once/everyNDays→jednorazowy)"
    status: completed
  - id: n1-scheduler
    content: "S1: WorkoutReminderScheduling (protokół) + NotificationCenterReminderScheduler (UNUserNotificationCenter) + InMemoryReminderScheduler"
    status: completed
  - id: n1-env
    content: "S1: rejestracja reminderScheduler w AppEnvironment (bez UI wejścia)"
    status: completed
  - id: n1-tests
    content: "S1: testy buildera (weekly/once/everyNDays, plan nieaktywny/bez przypomnienia/przeszły once), copy PL"
    status: completed
  - id: n2-editor
    content: "S2: PlanEditor — opcjonalne przypomnienie (toggle + godzina), zapis reminderTime w planie"
    status: pending
  - id: n2-permission
    content: "S2: flow uprawnień (request przy włączeniu przypomnienia), reschedule po save/delete planu + przy foreground"
    status: pending
  - id: n2-tests
    content: "S2: testy VM edytora (reminderTime składany z toggle+godziny, walidacja), reschedule woła scheduler"
    status: pending
  - id: p1-model
    content: "S3: UserProfile (name, skillLevel, weeklyPullUpGoal, hasCompletedOnboarding, createdAt) + UserProfileStoring + File/InMemory store"
    status: pending
  - id: p1-stats
    content: "S3: ProfileStatistics — czyste statystyki z logów (liczba treningów/sesji, suma powtórzeń, streak, ćwiczone grupy, ten tydzień)"
    status: pending
  - id: p1-env
    content: "S3: rejestracja userProfileStore + fabryki w AppEnvironment (bez UI konsumenta — VM/UI w S4)"
    status: pending
  - id: p1-tests
    content: "S3: testy — roundtrip store, ProfileStatistics na deterministycznych logach, Codable wstecznej zgodności"
    status: pending
  - id: p2-viewmodel
    content: "S4: ProfileViewModel + przebudowa ProfileView (header, statystyki z logów, edycja profilu, sekcja Ustawienia/powiadomienia)"
    status: pending
  - id: p2-onboarding
    content: "S4: onboarding pierwszego uruchomienia (imię + poziom + cel) i podmiana MockDataProvider (imię/weeklyGoal) na realny profil w HomeView/HeroCard"
    status: pending
  - id: p2-tests
    content: "S4: testy VM profilu (edycja, walidacja celu, onboarding gate)"
    status: pending
isProject: false
---

# Profil + powiadomienia lokalne

Kontynuacja po ukończonym planie „Zakładka Ćwiczenia + dziennik" (Sprinty 1–8). Dwa niezależne feature'y, wykonywane małymi sprintami — kolejność zależnościowa: najpierw powiadomienia (planer z S6–S8 jest gotowy → szybki, shippable feature), potem Profil (jego ekran Ustawień pomieści zarządzanie przypomnieniami i podmieni mockowe imię/cel z `MockDataProvider`).

## Zasady dla agentów (obowiązkowe)

1. **NIE uruchamiać `xcodebuild`** ani żadnej weryfikacji kompilacji — build i testy sprawdza wyłącznie użytkownik ręcznie w Xcode.
2. **Wykonujesz TYLKO swój sprint** (sprawdź w [docs/SPRINTS-profil-powiadomienia.md](../../docs/SPRINTS-profil-powiadomienia.md), który jest następny). Nie wybiegaj w przód.
3. **Przed startem** przeczytaj cały ten plan + dziennik poprzednich agentów w trackerze.
4. **Po sprincie obowiązkowo**: (a) zmień statusy swoich todos tutaj na `completed`, (b) uzupełnij wpis w dzienniku trackera (co zrobione, odstępstwa, decyzje, wskazówki), (c) ustaw status sprintu na „do weryfikacji" — na „zakończony" zmienia użytkownik po ręcznym buildzie.
5. Nowe pliki Swift podpinają się same (projekt używa `PBXFileSystemSynchronizedRootGroup` na `cali-park` i `cali-parkTests`) — wystarczy położyć plik w katalogu.

## Kontekst architektoniczny (wszystkie sprinty)

Wzorzec **MVVM** jak dotąd: protokoły serwisów, DI przez [cali-park/Core/AppEnvironment.swift](../../cali-park/Core/AppEnvironment.swift), modele `Codable`/`UUID`, ViewModele na `@Observable`. Zero nowych zależności. **Kolory tylko z AppTheme** (`Color.accent` #D1FF00, `.appBackground`, `.componentBackground`, `.textPrimary/.textSecondary`). Siatka spacingu 4/8, `clipShape(.rect(cornerRadius:))`, `foregroundStyle`, przyciski jako `Button`. Jeden typ = jeden plik. **Deployment target: iOS 18.4** (bez API iOS 26). Persystencja lokalna za protokołami — gotowa pod backend.

**App Store — powiadomienia:** lokalne powiadomienia NIE wymagają klucza `INFOPLIST_KEY_*` ani capability/entitlement (to tylko dla push remote). Wymagają jedynie `UNUserNotificationCenter.requestAuthorization` — prosić o zgodę w kontekście (przy włączeniu przypomnienia), nie na starcie.

---

## Sprint 1 — powiadomienia: fundament (bez UI)

- **Model**: dodać `reminderTime: DateComponents?` (godzina+minuta; `nil` = brak przypomnienia) do `WorkoutPlan`. Wstecznie zgodny (syntezowany Codable dekoduje brak klucza jako `nil`). Harmonogram (`WorkoutSchedule`) nadal jest dzienny — przypomnienie dokłada porę dnia.
- **`WorkoutReminderRequest`** (`Features/Planner/Services/`) — czysta wartość: `id: String` (stabilny, per plan+wariant), `planID`, `title`, `body`, `dateComponents: DateComponents`, `repeats: Bool`. Bez zależności od UN.
- **`WorkoutReminderPlanner`** — czysty, statyczny builder `requests(for plans: [WorkoutPlan], calendar:) -> [WorkoutReminderRequest]`:
  - tylko `isActive` plany z `reminderTime != nil`,
  - `weekly(days)` → jeden request per dzień (`DateComponents(hour, minute, weekday:)`, `repeats: true`, id `plan-<uuid>-wd<n>`),
  - `once(date)` → jednorazowy request na `date`+godzina, tylko gdy w przyszłości (id `plan-<uuid>-once`),
  - `everyNDays` → jednorazowy request na `nextOccurrence(onOrAfter: now)`+godzina, `repeats: false` (ograniczenie: wymaga reschedule przy foreground/zmianie — udokumentować; id `plan-<uuid>-interval`).
  - Copy PL: tytuł = nazwa planu; treść krótka, np. „Czas na trening · {N ćwiczeń}" (reużyj `PolishPlural.exercises`).
- **`WorkoutReminderScheduling`** (protokół, `Sendable`): `authorizationStatus() async`, `@discardableResult requestAuthorization() async -> Bool`, `reschedule(for: [WorkoutPlan]) async`, `cancelAll() async`. + `ReminderAuthorizationStatus` (notDetermined/denied/authorized).
- **`NotificationCenterReminderScheduler`** — realna implementacja na `UNUserNotificationCenter` (usuwa nasze pending po prefiksie `plan-`, dodaje z `UNCalendarNotificationTrigger`). **`InMemoryReminderScheduler`** (actor) — do testów/preview.
- **AppEnvironment**: `reminderScheduler: WorkoutReminderScheduling = NotificationCenterReminderScheduler()` (bez fabryk VM — te w S2).
- **Testy**: builder (weekly = N requestów repeat; once przyszły/przeszły; everyNDays; plan nieaktywny/bez `reminderTime` = 0 requestów), stabilność `id`, copy PL. Deterministyczny kalendarz UTC.

**Definition of done:** model + builder + scheduler istnieją, testy buildera przechodzą, zero zmian w UI.

## Sprint 2 — powiadomienia: integracja (UI wejścia + uprawnienia)

- **PlanEditor**: sekcja „Przypomnienie" — `Toggle` + `DatePicker(.hourAndMinute)` (widoczny gdy włączone). `PlanEditorViewModel` składa `reminderTime` z toggle+godziny; zapis w planie.
- **Uprawnienia**: przy włączeniu przypomnienia → `requestAuthorization`; gdy odmowa — czytelny komunikat + link do Ustawień systemowych. Nie prosić na starcie aplikacji.
- **Reschedule**: po `save`/`delete` planu i przy `foreground` aplikacji (`scenePhase`) wołać `reminderScheduler.reschedule(for: store.load())`.
- **Testy**: `PlanEditorViewModel` (reminderTime składany/kasowany, walidacja), reschedule woła scheduler (stub liczący wywołania / `InMemoryReminderScheduler`).

**Definition of done:** plan „co tydzień · Pon · 18:00" ustawia przypomnienie; edycja/usunięcie aktualizuje; smoke test na urządzeniu (użytkownik) — powiadomienie przychodzi.

---

## Sprint 3 — Profil: fundament danych (bez UI)

- **`UserProfile`** (`Features/Profile/Models/`) — `id: UUID`, `name`, `skillLevel` (enum basic/intermediate/advanced, polskie `displayName`), `weeklyPullUpGoal: Int`, `hasCompletedOnboarding: Bool`, `createdAt`. `Codable`.
- **`UserProfileStoring`** + `FileUserProfileStore` (JSON `user-profile.json`, jeden obiekt) + `InMemoryUserProfileStore`. Analogicznie do `WorkoutPlanStore`.
- **`ProfileStatistics`** — czysta, testowalna kalkulacja z `[WorkoutLogEntry]`: liczba treningów (sesje liczone jako jeden + pojedyncze), suma powtórzeń, `currentStreak`/`longestStreak` (reużyj `WorkoutStreak`), liczba różnych ćwiczonych grup mięśniowych, treningi w tym tygodniu. Wstrzykiwany `Calendar`/`today`.
- **AppEnvironment**: `userProfileStore` + fabryki (bez UI konsumenta — VM/UI w S4).
- **Testy**: roundtrip store (InMemory + File temp dir), `ProfileStatistics` na deterministycznych logach, Codable wstecznej zgodności (brak `hasCompletedOnboarding` → `false`).

**Definition of done:** model + store + statystyki istnieją, testy przechodzą, zero zmian w UI.

## Sprint 4 — Profil: UI + onboarding

- **`ProfileViewModel`** (`@Observable`) + przebudowa **`ProfileView`**: header (imię + poziom), siatka statystyk z logów (nie hardkod „24"), edycja profilu (sheet: imię, poziom, cel tygodniowy), sekcja „Ustawienia" (m.in. wejście do zarządzania przypomnieniami / stan uprawnień z S1–S2). Kolory z AppTheme, spacing 4/8.
- **Onboarding** pierwszego uruchomienia (gdy `!hasCompletedOnboarding`): sheet/kroki — imię, poziom, cel tygodniowy → zapis + `hasCompletedOnboarding = true`.
- **Podmiana mocka**: `HomeView`/`HeroCardView` czytają imię i `weeklyGoal` z `UserProfile` zamiast `MockDataProvider` (koniec hardkodu „Michał"/75); usunąć nieużywane pola mocka jeśli osierocone.
- **Testy**: `ProfileViewModel` (edycja, walidacja celu > 0, onboarding gate, zapis przez store + błąd przez stub).

**Definition of done:** onboarding przy pierwszym uruchomieniu; Profil pokazuje realne statystyki; imię/cel na Home z profilu; edycja działa; testy VM przechodzą.

---

## Poza zakresem (świadomie)

- HealthKit + Apple Watch (osobny duży temat — architektura gotowa: `QuickWorkoutViewModel.finish()` z jednym `sessionID`).
- Backend (Supabase/Firebase — store'y gotowe do podmiany).
- Zdjęcie profilowe / avatar (na razie glif systemowy).
- Powiadomienia typu „streak w niebezpieczeństwie" / motywacyjne (osobny temat po harmonogramowych).
