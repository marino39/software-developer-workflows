---
name: research-sources
description: Source playbooks for /research — which sources a sub-question MUST attempt, by subject type (Polish company, person's professional profile, product/offer, market), how to record each source as reached or blocked, and how to spot a JavaScript app shell that a plain fetch cannot read. Use in research R0 to build the source plan, and in every scout and verifier dispatch.
---

# Research sources (the source plan)

A scout left to choose its own sources stops at the first page that answers, or at the
first wall. On 2026-10-17 a five-scout run never queried a single business registry,
although the VAT whitelist answered the core question with one public request, and five
"nothing found" claims were really "the fetch saw only page metadata". The source plan
fixes both: R0 assigns each sub-question its **mandatory sources**, every scout reports a
**reach status** per source, and an absence claim is only as strong as the sources that
were actually reached.

## 1. Reach status — recorded for every mandatory source

| Status | Meaning |
|---|---|
| `reached` | content was read (not just a title or meta tags) |
| `blocked (robots)` | the fetch tool refused the URL (robots.txt) |
| `blocked (auth)` | login or paywall |
| `blocked (js-render)` | the fetch returned an app shell — see §2 |
| `blocked (http)` | error status, timeout, bot challenge |
| `n/a` | the source does not apply (e.g. KRS when the subject is a sole proprietorship) |

A `blocked` source is never evidence of absence. It goes to **Gaps**, or to the R3
render step when the session can render pages.

## 2. Spotting an app shell (`blocked (js-render)`)

Treat a fetch as an app shell when the result is only the title and meta/OG tags, or a
body of a few lines ("enable JavaScript", a root `<div>`), while the site's sitemap or
links show real pages. Check `/sitemap.xml` to enumerate routes. Record every route as
`blocked (js-render)` and never write "the page shows no contact / price / X".

## 3. Playbooks — mandatory sources by subject type

R0 picks the playbook(s) a sub-question needs and lists the concrete URLs in the brief.

### 3.1 Polish business (any form)

1. **VAT whitelist (MF) — always first, by NIP/REGON:**
   `https://wl-api.mf.gov.pl/api/search/nip/<NIP>?date=<YYYY-MM-DD>` (or `/regon/<REGON>`).
   Public JSON, no key. Gives the registered name (a sole proprietorship shows the
   owner's name), VAT status, REGON, KRS if any, working address and registration
   dates. **Never record bank account numbers** from it.
2. **CEIDG** (sole proprietorships): `https://aplikacja.ceidg.gov.pl/ceidg/ceidg.public.ui/search.aspx`
   or `biznes.gov.pl` — often `blocked (js-render)`; then a mirror (`rejestr.io`,
   `aleo.com`, `owg.pl`) and say it is a mirror.
3. **KRS** (companies): `https://api-krs.ms.gov.pl/api/krs/OdpisAktualny/<KRS>?rejestr=P&format=json`.
   `n/a` when 1. shows no KRS.
4. **The subject's own site**, every route from `sitemap.xml` — footer/stopka carries
   NIP and the legal name.
5. **Domain age:** `https://www.dns.pl/whois` (creation date; registrants who are
   individuals are not disclosed) and the Wayback availability API
   `https://archive.org/wayback/available?url=<domain>`.
6. **Reviews/presence:** Oferteo, Google Maps profile, the business's Facebook page.

No NIP known yet → get it from 4., else search `"<name>" NIP`; the first NIP found is
then confirmed through 1.

### 3.2 A person's professional profile

Scope is **professional and public-business only** — role, companies, qualifications,
public talks and posts about the business. Never home address, family, personal
accounts, age.

1. The business's own site (about/kontakt/footer) and the registry entry from 3.1.
2. LinkedIn profile (usually `blocked (robots)` for fetch tools).
3. The business's Facebook page and YouTube channel; talks, podcasts, interviews.
4. GitHub/GitLab, forum or community profiles under the business name.
5. Qualification registers relevant to the trade (e.g. SEP/UDT certificate lookups)
   when the question needs qualifications.

A same-name hit elsewhere is not the same person until a shared identifier (NIP,
business name, address) links them.

### 3.3 A product or offer

1. Every product/pricing route of the vendor site (`sitemap.xml`), rendered.
2. Datasheets, manuals, changelogs, compatibility lists.
3. Repositories, package registries, integration directories (HACS, app stores).
4. ≥1 independent source per headline claim (reviews, forum threads, trade press).

### 3.4 Market and competitors

≥2 independent comparisons or trade-press pieces (e.g. gramwzielone.pl, globenergia.pl
for Polish energy), each competitor's own offer page, and a note of any sponsored
article as sponsored.

## 4. Absence claims

When a scout looked for something and did not find it, it writes an absence claim
naming the sources (see `agents/researcher.md`, claim lines). R3 treats an absence as
**covered only if every mandatory source for it is `reached`**; with any source
blocked, the absence is a Gap and the report says what was not reachable.
