/*
 * The editor's strings, in the language Swift says is in effect.
 *
 * The catalogs are not written here: `build.mjs` reads every `Locales/<code>/strings.json` and hands
 * this module the `editor.*` keys, so the web layer and the Swift layer translate from the same
 * files. Adding a language is adding a directory there — nothing in this file names one.
 *
 * Swift owns the choice (Settings > General > Language, or the macOS language when that is
 * "system") and sends the *resolved* code in `applySettings`. This layer never reads
 * `navigator.language`: two places deciding the language is how a menu ends up in one and the
 * editor in another.
 */

import catalogs from "virtual:locales";

const FALLBACK = "en";

let language = FALLBACK;
let plurals = new Intl.PluralRules(FALLBACK);
const listeners = new Set<() => void>();

/** The language code in effect, e.g. `en`, `zh-Hans`. */
export function currentLanguage(): string {
  return language;
}

/**
 * Switches language and re-renders whatever registered with `onLanguageChange`. Safe to call on
 * every `applySettings`: it does nothing when the language has not moved, so a settings change that
 * is not about language does not repaint the chrome.
 */
export function setLanguage(code: string): void {
  const next = code in catalogs ? code : FALLBACK;
  if (next === language) return;
  language = next;
  try {
    plurals = new Intl.PluralRules(next);
  } catch {
    plurals = new Intl.PluralRules(FALLBACK);
  }
  document.documentElement.lang = next;
  listeners.forEach((listener) => listener());
}

/** For static markup and anything else that is built once and must be re-said on a switch. */
export function onLanguageChange(listener: () => void): void {
  listeners.add(listener);
}

function lookup(key: string): string | undefined {
  return catalogs[language]?.[key] ?? catalogs[FALLBACK]?.[key];
}

function fill(template: string, args?: Record<string, string | number>): string {
  if (!args) return template;
  return template.replace(/\{(\w+)\}/g, (whole, name: string) =>
    name in args ? String(args[name]) : whole
  );
}

/**
 * `t("editor.untitled")`, with `{name}` placeholders. A missing key shows as itself — visible and
 * greppable — and `LocalizationTests` is what stops that reaching a release.
 */
export function t(key: string, args?: Record<string, string | number>): string {
  return fill(lookup(key) ?? key, args);
}

/**
 * A string that depends on a count: `key.one`, `key.other`, … by the language's own plural rule.
 * Chinese supplies only `key.other`; English supplies `.one` and `.other`; a language with more
 * categories (Russian, Arabic) adds `.few`, `.many`, … in its `strings.json` and nothing here.
 */
export function plural(key: string, count: number, args: Record<string, string | number> = {}): string {
  const category = plurals.select(count);
  const template =
    lookup(`${key}.${category}`) ?? lookup(`${key}.other`) ?? lookup(key) ?? key;
  return fill(template, { ...args, count });
}

/**
 * Fills the static markup: any element with `data-i18n-aria` or `data-i18n-placeholder` gets that
 * key's text. The English left in the HTML is only what shows before the first call.
 *
 * Re-runs on every language change, so a switch re-labels the chrome that was never rebuilt.
 */
export function translateStaticMarkup(root: ParentNode = document): void {
  root.querySelectorAll<HTMLElement>("[data-i18n-aria]").forEach((el) => {
    el.setAttribute("aria-label", t(el.dataset.i18nAria!));
  });
  root.querySelectorAll<HTMLInputElement>("[data-i18n-placeholder]").forEach((el) => {
    el.placeholder = t(el.dataset.i18nPlaceholder!);
  });
}
