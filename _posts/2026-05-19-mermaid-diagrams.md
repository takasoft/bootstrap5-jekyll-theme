---
title: Diagrams with Mermaid
date: 2026-05-19T12:01:00+00:00
layout: post
categories:
  - Demo
tags:
  - mermaid
  - demo
---

Mermaid is loaded lazily — the script in `_includes/footer.html` checks
for `.language-mermaid` elements in the DOM and only fetches Mermaid
when at least one is present. Posts without diagrams don't pay the cost.

A simple flowchart:

```mermaid
flowchart LR
    A[Markdown post] -->|jekyll build| B[HTML]
    B --> C{Has .language-mermaid?}
    C -->|yes| D[Lazy-load Mermaid ESM]
    C -->|no| E[Done — no Mermaid loaded]
    D --> F[Render diagrams in place]
```

A sequence diagram:

```mermaid
sequenceDiagram
    participant Reader
    participant Browser
    participant Jekyll
    Reader->>Browser: visits /blog/post
    Browser->>Jekyll: GET /blog/post.html
    Jekyll-->>Browser: HTML with code.language-mermaid
    Browser->>Browser: detect mermaid block
    Browser->>Browser: import mermaid ESM
    Browser-->>Reader: render diagram
```
