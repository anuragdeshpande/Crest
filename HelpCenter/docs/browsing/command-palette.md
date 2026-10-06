---
title: Use the command palette
description: Search, navigate, switch tabs, revisit history, and run Crest commands from one field.
slug: /command-palette
keywords: [command palette, address bar, search, commands, tabs, history]
---

# Use the command palette

Click the address display or press **Command-L**. The same palette can resolve a web address, search query, open tab, saved page, history entry, or Crest command.

## Read the results

The first row represents what Return will do with the text itself: open a resolved address or search with the current provider. Below it, Crest ranks tabs, available commands, saved pages, and history from the current Space.

Selecting an existing tab avoids making a duplicate. Switch Spaces first to search another Space’s tabs and history.

## Run commands by name

Type a verb or feature name such as “archive,” “downloads,” “reader,” “split,” or “copy Markdown.” The palette uses the same command catalog as the Mac menus and shortcut settings, so an action remains discoverable even when it has no default key equivalent.

Use the arrow keys to change selection, **Return** to run it, and **Escape** to dismiss. On a touch device, tap the result.

## Search behavior

Text that resolves as an HTTP or HTTPS address opens directly. Other text uses the selected search provider. Because the palette also searches current-Space history and saved content, a familiar page may appear above a new web search.

As you type a website address, local autocomplete can complete matching addresses from the current Space. Search suggestions from your chosen provider are optional and separate from local tab and history matches.

## Search a specific site on Mac

Type a saved site's name or shortcut, such as **google**, **yt**, or **gpt**. When the field offers the matching site, press **Tab** (or click the offer). A color-coded site pill with the site's favicon appears beside the field, with a matching soft halo around the palette. If the favicon is unavailable, Crest shows a search icon instead. Enter your query and press **Return** to open that site's search results, regardless of the Space's default search provider. Reduce Transparency or Increase Contrast replaces the halo with a solid outline.

While a site is selected, everything you type is a search query, including text that looks like a URL. Crest does not fetch suggestions from your default provider in this mode. Press **Escape**, click the token's close control, or press **Backspace** in an empty field to leave site search. When no site is offered, Tab continues to accept an available URL completion.

Manage entries in **Settings → General → Site Searches**. Click an entry to edit its name, shortcut, additional shortcuts, search URL, or pill color. Additional shortcuts are optional and separated by commas. The color picker previews the pill before you save. Use **Add Site Search** to create an entry or its remove control to delete it.

Google, YouTube, Wikipedia, GitHub, Reddit, X, ChatGPT, Claude, Perplexity, Stack Overflow, MDN, Amazon, IMDb, Spotify, and Figma Community are included initially and can be edited or removed. Wikipedia uses your Mac's preferred language, and Amazon uses its region. Aliases include **g** for Google, **twitter** for X, and **gpt** or **openai** for ChatGPT. Upgrading an existing nonempty list adds the newly included sites without overwriting custom entries or restoring removed original sites; an intentionally empty list stays empty.

Search URLs must use HTTPS and contain exactly one `%s` or `{searchTerms}` placeholder in the path or query. Search words are URL-encoded before replacing the placeholder. Do not put passwords or tokens in templates.

Site searches are shared across Spaces on this Mac, saved locally, and not synced. They do not change a Space's default search provider.
