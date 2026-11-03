# Swift agent skills research (2026-11-03)

> **Correction (orchestrator):** the table says to keep Core Data Expert because the app uses Core Data. That is wrong. The audit found the Core Data stack is dead code: the model is empty and nothing reads it (findings C-10, F-12, G-25). All persistence is JSON files plus UserDefaults. Core Data Expert is only useful if you decide to migrate to Core Data or SwiftData.

## 1. Swift/iOS skills and MCP servers

Star counts come from the GitHub API and install counts from skills.sh, both checked 2026-11-03. "npx skills" below means `npx skills add <url> --skill <name> -a claude-code`.

| Name | Author | URL | Covers | Have? | Rec. | Install |
|---|---|---|---|---|---|---|
| SwiftUI Pro | Paul Hudson | https://github.com/twostraws/SwiftUI-Agent-Skill (6.4k stars, 36.7K installs) | The SwiftUI mistakes LLMs make: deprecated API, navigation, state, layout, performance, VoiceOver. Built for iOS 26+ and Swift 6.4+ | No | **Add** | `/plugin marketplace add twostraws/SwiftUI-Agent-Skill` then `/plugin install swiftui-pro@swiftui-agent-skill`, or npx skills `https://github.com/twostraws/swiftui-agent-skill --skill swiftui-pro` |
| SwiftUI Expert | Antoine van der Lee | https://github.com/AvdLee/SwiftUI-Agent-Skill (3.8k, 35.8K) | SwiftUI best practices and a deprecated-to-modern guide for iOS 15 through 27+ | No | Use as an alternative to SwiftUI Pro, not alongside it | `/plugin marketplace add AvdLee/SwiftUI-Agent-Skill`, then `/plugin install swiftui-expert@swiftui-expert-skill` |
| Swift Concurrency Pro | Paul Hudson | https://github.com/twostraws/Swift-Concurrency-Agent-Skill (579, 12.4K) | Actors, isolation, cancellation, Swift 6.2 changes | Yes | Keep | `/plugin install swift-concurrency-pro@...` after adding the marketplace |
| Swift Concurrency (Expert) | Antoine van der Lee | https://github.com/AvdLee/Swift-Concurrency-Agent-Skill (1.7k, 17.3K) | Same area | No | Skip, it duplicates the one you have | `/plugin marketplace add AvdLee/Swift-Concurrency-Agent-Skill` |
| Swift Testing Pro | Paul Hudson | https://github.com/twostraws/Swift-Testing-Agent-Skill (473) | Swift Testing, moving off XCTest | Yes | Keep | Plugin or npx |
| Swift Testing Expert | Antoine van der Lee | https://github.com/AvdLee/Swift-Testing-Agent-Skill (478) | Same area | No | Skip, duplicate | — |
| SwiftData Pro | Paul Hudson | https://github.com/twostraws/SwiftData-Agent-Skill (459) | SwiftData | No | Skip. The repo has 0 SwiftData files and uses Core Data | — |
| Core Data Expert | Antoine van der Lee | https://github.com/AvdLee/Core-Data-Agent-Skill (320) | Core Data stack, threading, migrations, CloudKit | Yes | Keep (`Core/Services/Persistence.swift` uses Core Data) | — |
| Xcode Build Optimization | Antoine van der Lee | https://github.com/AvdLee/Xcode-Build-Optimization-Agent-Skill (1.3k) | Benchmarking and speeding up incremental and clean builds | No | Optional, once builds get slow | `/plugin marketplace add AvdLee/Xcode-Build-Optimization-Agent-Skill` then `/plugin install xcode-build-skills@xcode-build-skills` |
| Dimillian/Skills: swiftui-ui-patterns, swiftui-view-refactor, swiftui-performance-audit, ios-debugger-agent, swiftui-liquid-glass, app-store-changelog | Thomas Ricouard | https://github.com/Dimillian/Skills (4.0k; ui-patterns 3.6K installs) | UI patterns, view refactors, performance audits, simulator debugging (needs XcodeBuildMCP), Liquid Glass (iOS 26+), release notes | No | Add **swiftui-performance-audit** and **swiftui-view-refactor**. Skip liquid-glass and ui-patterns, which overlap SwiftUI Pro. The repo targets Codex and was last pushed 2026-03 | `npx skills add https://github.com/dimillian/skills --skill swiftui-performance-audit -a claude-code` |
| Xcode MCP (`xcrun mcpbridge`) | Apple | https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode | Lets Claude Code use your open Xcode project to build, test and use Xcode tools. `mcpbridge` is present in your Xcode 27.2 | No | **Add** | Turn on Xcode › Settings › Intelligence › "Allow external agents to use Xcode tools", then `claude mcp add --transport stdio xcode -- xcrun mcpbridge` |
| MobileBuildMCP (formerly XcodeBuildMCP; the old repo now redirects) | Sentry (Cameron Cooke) | https://github.com/getsentry/MobileBuildMCP (6.5k) | Headless simulator and device build/run/test, UI automation, screenshots, logs, debugging | No | **Add** (works without Xcode open) | `claude mcp add MobileBuildMCP -- npx -y mobilebuildmcp@latest mcp`. Optional skill: `npx -y mobilebuildmcp@latest init` |
| Sosumi | NSHipster | https://github.com/NSHipster/sosumi.ai (482) | Apple documentation in a form agents can read | No | Optional | Remote MCP server at `https://sosumi.ai/mcp` |
| Axiom | Charles Wiltgen | https://github.com/CharlesWiltgen/Axiom (1.2k) | 286 skills and 43 agents for xOS | No | Skip. It would crowd the skill listing and overlaps the set above | `/plugin marketplace add CharlesWiltgen/Axiom` |
| swiftui-design-principles | arjitj2 | https://github.com/arjitj2/swiftui-design-principles (34) | Spacing, type and widget polish | Yes | Keep (complements SwiftUI Pro) | — |
| swift-architecture-skill | efremidze | https://github.com/efremidze/swift-architecture-skill (81) | MVVM/TCA/Clean playbooks | Yes | Keep, low usage | — |
| swift-api-design-guidelines-skill | Erikote04 | https://github.com/Erikote04/Swift-API-Design-Guidelines-Agent-Skill (32) | API naming | Yes | Optional, consider dropping | — |
| swift-security-expert | ivan-magda | https://github.com/ivan-magda/swift-security-skill (40) | Keychain, CryptoKit, biometrics | Yes | Keep only if you add auth or Keychain code. The repo has none today | — |

To find more, Paul Hudson keeps a curated list at https://github.com/twostraws/Swift-Agent-Skills (3.0k).

## 2. Does Claude Code load `<project>/.agents/skills`?

**No.** The Claude Code skills docs (https://code.claude.com/docs/en/skills, "Choose where skills load") list only these locations:
- managed `.claude/skills/`
- `~/.claude/skills/<name>/SKILL.md`
- project `.claude/skills/<name>/SKILL.md`, from the start directory and every parent up to the repo root
- nested `<subdir>/.claude/skills/`, loaded on first access
- `--add-dir` `.claude/skills/`
- plugin `<plugin>/skills/`
- skills synced from your claude.ai account

The memory docs say Claude Code does not read "anything under a `.agents/` directory".

The vercel-labs skills CLI (https://github.com/vercel-labs/skills/blob/main/docs/agents.md) maps Claude Code to `.claude/skills/` and `~/.claude/skills/`. `.agents/skills/` is the path for Codex, Cursor, Gemini, Amp and other agents.

**Your 19 skills in `.agents/skills` are invisible to Claude Code right now.** There is no `.claude/skills` directory, and none of them show up in this session's skill list. Two ways to fix it:
- Re-run `npx skills add <repo> -a claude-code`.
- Symlink each skill: `ln -s ../../.agents/skills/<name> .claude/skills/<name>`. The docs say a `<skill-name>` entry "can be a symlink to a directory elsewhere on disk". Symlinking the whole `.claude/skills` directory is a bad idea because `claude plugin validate` errors on it.

## 3. Recommended minimal "pro" set (7)

1. **SwiftUI Pro (twostraws).** It is the most installed SwiftUI skill and the same family as the two you already have. It targets iOS 26 and Swift 6.4, so put "deployment target iOS 18.4; gate newer APIs with `#available`" in CLAUDE.md.
2. **Swift Concurrency Pro (already installed).** Swift 6 strict concurrency is where LLMs go wrong most often.
3. **Swift Testing Pro (already installed).**
4. **Core Data Expert (already installed).** The app's persistence layer is Core Data.
5. **swiftui-design-principles (already installed).** It covers visual polish, which SwiftUI Pro does not.
6. **Apple Xcode MCP (`xcrun mcpbridge`).** This is Apple's own build/test path and already ships in your Xcode 27.2.
7. **MobileBuildMCP.** It drives the simulator headlessly and takes screenshots, which lets Claude check UI changes itself.

Optional additions:
- Dimillian's **swiftui-performance-audit**, if you see scroll or rendering jank.
- **Xcode Build Optimization**, when builds slow down.

Uninstall or ignore these:
- the duplicate AvdLee concurrency and testing skills
- swift-api-design-guidelines
- swift-security-expert, until you add Keychain code

Fewer skills means fewer descriptions to fit into Claude Code's listing budget, which is 1% of the context window.

Before any of this helps, link or reinstall the skills into `.claude/skills` (section 2).