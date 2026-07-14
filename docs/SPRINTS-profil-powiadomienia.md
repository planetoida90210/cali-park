# Tracker sprintów — Profil + powiadomienia lokalne

Plan źródłowy: [.cursor/plans/profil_+_powiadomienia_lokalne.plan.md](../.cursor/plans/profil_+_powiadomienia_lokalne.plan.md)

Poprzedni, ukończony plan: [docs/SPRINTS.md](SPRINTS.md) („Zakładka Ćwiczenia + dziennik", Sprinty 1–8, zakończone).

## Instrukcja dla agenta

1. Znajdź w tabeli pierwszy sprint ze statusem `oczekuje` — to twój sprint. Wykonaj TYLKO jego zakres z planu.
2. Jeśli poprzedni sprint ma status `do weryfikacji`, ZATRZYMAJ SIĘ i poproś użytkownika o weryfikację buildu w Xcode — nie zaczynaj kolejnego sprintu na niezweryfikowanym fundamencie.
3. Przed startem przeczytaj cały plan oraz WSZYSTKIE wpisy w dzienniku poniżej.
4. NIE uruchamiaj `xcodebuild` ani żadnej weryfikacji kompilacji — build i testy sprawdza użytkownik ręcznie w Xcode.
5. Po skończeniu pracy: status sprintu → `do weryfikacji`, todos w planie → `completed`, dopisz wpis do dziennika.
6. Status `zakończony` ustawia wyłącznie użytkownik po ręcznym buildzie i testach.

## Status sprintów

| Sprint | Zakres (skrót) | Status | Data |
|---|---|---|---|
| 1 | Powiadomienia — fundament: reminderTime w WorkoutPlan, WorkoutReminderRequest/Planner, WorkoutReminderScheduling + implementacje, rejestracja w AppEnvironment, testy buildera (bez UI) | do weryfikacji | 2026-07-14 |
| 2 | Powiadomienia — integracja: przypomnienie w PlanEditor (toggle + godzina), flow uprawnień, reschedule po save/delete + foreground, testy | oczekuje | — |
| 3 | Profil — fundament: UserProfile + UserProfileStoring + store'y, ProfileStatistics z logów, rejestracja w AppEnvironment, testy (bez UI) | oczekuje | — |
| 4 | Profil — UI + onboarding: ProfileViewModel + przebudowa ProfileView, onboarding pierwszego uruchomienia, podmiana MockDataProvider na realny profil, testy VM | oczekuje | — |

Statusy: `oczekuje` → `w toku` → `do weryfikacji` → `zakończony` (ustawia użytkownik).

## Dziennik sprintów

Szablon wpisu (kopiuj i wypełnij):

```
### Sprint N — <data>, agent

**Zrobione:** (lista plików utworzonych/zmienionych, jednym zdaniem co w każdym)
**Odstępstwa od planu:** (co inaczej i dlaczego; „brak" jeśli nic)
**Decyzje podjęte w trakcie:**
**Znane problemy / TODO:**
**Wskazówki dla następnego agenta:**
**Do ręcznej weryfikacji przez użytkownika:**
```

---

### Sprint 1 — 2026-07-14, agent (pierwszy tego planu)

Uwaga wstępna: poprzedni plan (S1–S8 „Zakładka Ćwiczenia + dziennik") ukończony i zweryfikowany. Ten sprint zaczyna nowy plan „Profil + powiadomienia lokalne" — fundament powiadomień lokalnych (bez UI), analogicznie do Sprintu 1/6 poprzedniego planu.

**Zrobione:**
- `cali-park/Features/Planner/Models/WorkoutPlan.swift` — dodane `reminderTime: DateComponents?` (godzina+minuta pory przypomnienia; `nil` = brak). Wstecznie zgodne: syntezowany Codable dekoduje brak klucza jako `nil` (stare plany bez zmian). Domyślnie `nil` w init.
- `cali-park/Features/Planner/Services/WorkoutReminderRequest.swift` (NOWY) — czysta wartość (`Equatable, Sendable`) opisująca pojedyncze przypomnienie: stabilny `id`, `planID`, `title`, `body`, `dateComponents`, `repeats`. Bez zależności od `UserNotifications`.
- `cali-park/Features/Planner/Services/WorkoutReminderPlanner.swift` (NOWY) — czysty, statyczny builder `requests(for:calendar:asOf:)`: bierze tylko aktywne plany z `reminderTime`; `weekly` → jeden repeatujący request per dzień (`DateComponents(hour,minute,weekday)`), `once` → jednorazowy tylko dla przyszłej daty, `everyNDays` → jednorazowy na najbliższe wystąpienie. Copy PL („Czas na trening · N ćwiczeń") z `PolishPlural.exercises`.
- `cali-park/Features/Planner/Services/WorkoutReminderScheduling.swift` (NOWY) — protokół `Sendable` (`authorizationStatus`, `requestAuthorization`, `reschedule(for:)`, `cancelAll`) + `ReminderAuthorizationStatus` (notDetermined/denied/authorized) + `InMemoryReminderScheduler` (actor, nagrywa requesty i wywołania — do testów/preview).
- `cali-park/Features/Planner/Services/NotificationCenterReminderScheduler.swift` (NOWY) — realna implementacja na `UNUserNotificationCenter`: `reschedule` usuwa nasze pending po prefiksie `plan-` i dodaje `UNNotificationRequest` z `UNCalendarNotificationTrigger` z buildera; mapowanie `ReminderAuthorizationStatus`.
- `cali-park/Core/AppEnvironment.swift` — dodane `reminderScheduler: WorkoutReminderScheduling` (domyślnie `NotificationCenterReminderScheduler()`). BEZ fabryk VM (te w S2, wraz z UI).
- `cali-parkTests/WorkoutReminderTests.swift` (NOWY) — Swift Testing: builder weekly (N requestów, repeats, poprawny `weekday`/`hour`/`minute`), once przyszły/przeszły, everyNDays (najbliższe wystąpienie), plan nieaktywny/bez `reminderTime` = 0, stabilność `id`, copy PL; `InMemoryReminderScheduler` (reschedule nagrywa requesty). Deterministyczny kalendarz UTC.

**Odstępstwa od planu:** brak. Doprecyzowanie: builder ma parametr `asOf:` (domyślnie `.now`) dla deterministycznych testów `once`/`everyNDays`.

**Decyzje podjęte w trakcie:**
- `reminderTime` jako `DateComponents?` na planie (nie osobny store) — plan jest właścicielem swojego przypomnienia; wstecznie zgodne przez opcjonal.
- `weekly` → osobny request per dzień z `repeats: true` (natywne, niezawodne). `everyNDays`/`once` → jednorazowe (nie da się wyrazić „co N dni" jednym `UNCalendarNotificationTrigger`) — wymagają reschedule (S2: przy foreground/zmianie planu). Udokumentowane w kodzie.
- `id` requestu stabilny: `plan-<uuid>-wd<n>` / `-once` / `-interval` — reschedule nadpisuje bez duplikatów; prefiks `plan-` pozwala czyścić tylko nasze.
- `InMemoryReminderScheduler` jako `actor` (Sendable, bezpieczny współbieżnie); realny scheduler to bezstanowy `struct`.

**Znane problemy / TODO:**
- Brak UI — przypomnień nie da się jeszcze ustawić z aplikacji (to S2: toggle+godzina w PlanEditor + flow uprawnień + reschedule po save/delete/foreground). `reminderScheduler` jest w `AppEnvironment`, ale nikt go jeszcze nie woła.
- `everyNDays`/`once` jednorazowe — bez reschedule „co N dni" wystrzeli raz. S2 doda reschedule przy foreground.
- Powiadomienia lokalne nie wymagają Info.plist/capability — potwierdzone; S2 tylko woła `requestAuthorization` w kontekście.

**Wskazówki dla następnego agenta (Sprint 2):**
- W `PlanEditorViewModel` dodaj `reminderEnabled: Bool` + `reminderTime: Date` (godzina); składaj `WorkoutPlan.reminderTime` z nich (`DateComponents([.hour,.minute], from:)`), a przy zapisie wołaj `reminderScheduler.reschedule(for: store.load())` (po `save`). Analogicznie po `delete` w `WorkoutPlansViewModel`.
- Uprawnienia: przy włączeniu toggla → `await reminderScheduler.requestAuthorization()`; przy odmowie pokaż komunikat + link `UIApplication.openSettingsURLString`.
- Reschedule przy foreground: w `HomeView`/root obserwuj `scenePhase == .active` i wołaj reschedule.
- Fabryki: `makePlanEditorViewModel` musi dostać `reminderScheduler` (rozszerz sygnaturę w `AppEnvironment`).
- ZANIM zaczniesz: sprawdź, czy Sprint 1 ma status `zakończony`.

**Do ręcznej weryfikacji przez użytkownika:**
- Build w Xcode (4 nowe pliki app w `Features/Planner/Services/` + 1 plik testów `WorkoutReminderTests`; zmienione: `WorkoutPlan`, `AppEnvironment`). Pliki podpną się same (synchronized groups).
- Testy: `WorkoutReminderTests` (+ wszystkie poprzednie — w starym kodzie zmieniono tylko dodanie opcjonalnego pola w `WorkoutPlan` i pole w `AppEnvironment`; `WorkoutPlanTests` Codable powinny nadal przechodzić dzięki wstecznej zgodności).
- Brak smoke testu UI (sprint bez UI) — aplikacja buduje się i działa jak po poprzednim planie.
- Po pozytywnej weryfikacji: zmień status Sprintu 1 w tabeli na `zakończony`.
