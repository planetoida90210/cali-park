# CaliPark

[![CI](https://github.com/planetoida90210/cali-park/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/planetoida90210/cali-park/actions/workflows/ci.yml)

Aplikacja iOS do treningu kalisteniki: dziennik treningów, plany, ścieżki progresji i mapa parków do street workoutu.

**Wkrótce dostępna w App Store.**

## Dla deweloperów

Wymagania: Xcode 26 lub nowszy, symulator iOS 26.5. Projekt nie ma zależności zewnętrznych. Zasady pracy, polecenie budowania i testów oraz konwencje są w [CLAUDE.md](CLAUDE.md).

Testy jednostkowe (współdzielony schemat `cali-park` i plan testów `cali-park.xctestplan`):

```sh
xcodebuild -project cali-park.xcodeproj -scheme cali-park \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -only-testing:cali-parkTests test
```

### Skille Swift dla Claude Code

Skille nie są w repozytorium: każdy instaluje je u siebie. Claude Code czyta skille projektu tylko z `.claude/skills/` (ten katalog jest w `.gitignore`). Z katalogu repozytorium:

```sh
npx skills add twostraws/SwiftUI-Agent-Skill -a claude-code             # swiftui-pro
npx skills add twostraws/Swift-Testing-Agent-Skill -a claude-code       # swift-testing-pro
npx skills add twostraws/Swift-Concurrency-Agent-Skill -a claude-code   # swift-concurrency-pro
npx skills add efremidze/swift-architecture-skill -a claude-code        # swift-architecture-skill
```

Bez `-a claude-code` `npx skills add` instaluje do `.agents/skills/` (też w `.gitignore`), którego Claude Code nie czyta. Taki skill podłącz dowiązaniem:

```sh
mkdir -p .claude/skills
ln -s ../../.agents/skills/swift-testing-pro .claude/skills/swift-testing-pro
```

Sprawdź w nowej sesji Claude Code, że skill jest na liście dostępnych skilli.
