---
title: Chromium and WebKit on Mac
description: Choose the engine new pages open in, send a website to the other engine, and see what each engine supports.
slug: /engines
keywords: [engine, Chromium, WebKit, ungoogled-chromium, default engine, website rules, protected video, DRM, FairPlay]
---

# Chromium and WebKit on Mac

Crest for Mac includes two web engines. New pages open in Chromium unless you choose otherwise, and any website or page can use WebKit, the engine behind Safari. Crest on iPhone and iPad uses WebKit.

Your Spaces, tabs, history, passwords and settings are the same whichever engine shows a page. Website data is not: each engine keeps its own cookies and storage for a Space, so signing in to a site in Chromium does not sign you in to it in WebKit.

## Chromium

Crest's Chromium engine is built on [ungoogled-chromium](https://github.com/ungoogled-software/ungoogled-chromium), which removes Google integrations from Chromium. It runs [Chrome Web Store extensions](../extensions/install-chrome-web-store.md).

Chromium starts the first time you need it. If WebKit is your default and no page uses Chromium, it stays unloaded. Opening a Chromium page or an extension starts it, and it stays running until you quit Crest.

## Choose the default engine

1. Open **Crest Settings → Engines**.
2. Select **Chromium** or **WebKit**.

The default applies to pages you open afterwards. Open pages keep their engine, and links a page opens stay on that page's engine. Select **Use Recommended Default** to return to Chromium.

## Open a website in the other engine

- **For one page:** choose **Page → Open Page in WebKit** or **Open Page in Chromium**. The page reloads in the other engine. Other pages from the site keep opening where they did.
- **For a whole website:** open Site Controls and change **Opens in**. The page reloads in that engine, and later pages from the website open there too.

A tab whose page runs in the engine that is not your default shows that engine's mark on its icon.

## Website rules

Choosing **Opens in** saves a website rule. Rules are listed under **Crest Settings → Engines → Website rules**, where you can:

- select **Add Website Rule…** to send a website to an engine before you visit it;
- select a rule to change its website or engine;
- select **Remove Rule** to return a website to your default engine.

Rules match the website's scheme, host and port. A rule for `example.com` does not cover its subdomains. A choice made while browsing privately is not saved as a rule; it lasts until you quit Crest.

## Protected video

Chromium in Crest cannot play DRM-protected video. When a page asks for it, Crest moves the page to WebKit, which plays it with Apple's FairPlay, and shows **Moved to WebKit to play protected video**. The website then opens in WebKit. Select **Move Back** to return it to Chromium, or remove its rule in Settings.

## After updating from a WebKit-only Crest

Versions of Crest before 0.6.460 used WebKit only. After updating, new pages open in Chromium. Your Spaces, tabs, history and Crest Passwords carry over, but Chromium starts with its own empty website data, so you may need to sign in to websites again. To keep browsing in WebKit, choose it as your default engine.

Extensions installed in earlier versions do not carry over. Install them again from the Chrome Web Store.

## What each engine supports

| Feature | Chromium | WebKit |
| --- | --- | --- |
| Chrome Web Store extensions | Yes | No |
| Reader | No | Yes |
| Translate the whole page | No. Translate selected text instead. | Yes |
| Built-in ad and tracker blocking | No. Use a blocking extension. | Yes |
| Protected video | Moves the page to WebKit | Yes |
| Find in Page | Shows the number of matches | Shows whether there is a match |
| Save Web Archive | `.mhtml` file | `.webarchive` file |
| Inspect a page | Chromium DevTools | Web Inspector |

Tabs, Spaces, Split View, Peek, Crest Passwords, site permissions, Picture in Picture and downloads work the same in both. See [Translate, read, and use page tools](./page-tools.md) for the page features in detail.
