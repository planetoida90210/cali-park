---
title: Wybór backendu
type: grilling
mode: HITL
status: open
assignee: 
blocked_by: [002, 006]
---

# Wybór backendu

## Pytanie

Na którym backendzie stawiamy Parki i Społeczność w 1.0? Kryteria są w „Zakres CaliPark 1.0”: UE, ok. 100 zł/mies. do ~10k aktywnych użytkowników, bez własnego serwera, szybki i bezpieczny z kontrolą dostępu na poziomie wierszy. Podstawą jest porównanie z „Backend dla Parków i Społeczności: opcje i koszty” i wymagania z „Wymagania App Store i RODO dla 1.0”.

## Kontekst z researchu (2026-11-03)

Ranking z researchu: Supabase Cloud Pro (Frankfurt), potem własne API na Hetznerze, potem PocketBase. Rozstrzygnąć trzeba: czy firma spoza UE z serwerami w UE wystarcza, kto buduje limit zapisów i uzasadnienia usunięć (DSA), oraz politykę limitu wydatków przed ~45k MAU.
