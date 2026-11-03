---
title: Warstwa danych treningów: naprawione pliki JSON czy SwiftData
type: grilling
mode: HITL
status: open
assignee: 
blocked_by: [009]
---

# Warstwa danych treningów: naprawione pliki JSON czy SwiftData

## Pytanie

Czy dane treningowe zostają w plikach JSON po naprawie z audytu (wspólny `JSONFileStore`, wersjonowanie, bez cichego wipe'u), czy przechodzą na SwiftData albo inny magazyn wymuszony przez wybraną technologię syncu? Od tego zależy pierwszy sprint fundamentu. Audyt: P0 #1, P1 „dane długoterminowo”.

## Kontekst z researchu (2026-11-03)

Research proponuje Fazę 0 bez płatnego konta: naprawa wipe'u, wersjonowane pliki, stabilne ID szczebli, Application Support, eksport i import. Pliki JSON zostają źródłem prawdy pod CKSyncEngine.
