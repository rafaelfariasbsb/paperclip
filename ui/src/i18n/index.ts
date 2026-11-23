import i18n, { type InitOptions, type TOptions } from "i18next";
import { initReactI18next, useTranslation as useReactI18nextTranslation } from "react-i18next";

import { DEFAULT_LOCALE, i18nextResources, supportedLocales } from "./locales";

export const LOCALE_STORAGE_KEY = "paperclip.locale";

export function resolveInitialLocale(
  stored: string | null,
  browserLanguages: readonly string[],
  supported: readonly string[] = supportedLocales,
): string {
  const candidates = [stored, ...browserLanguages].filter((value): value is string => !!value);
  for (const candidate of candidates) {
    const exact = supported.find((locale) => locale.toLowerCase() === candidate.toLowerCase());
    if (exact) return exact;
    const base = candidate.split("-")[0].toLowerCase();
    const byBase = supported.find((locale) => locale.toLowerCase() === base)
      ?? supported.find((locale) => locale.toLowerCase().startsWith(`${base}-`));
    if (byBase) return byBase;
  }
  return DEFAULT_LOCALE;
}

function readStoredLocale(): string | null {
  try {
    return typeof localStorage === "undefined" ? null : localStorage.getItem(LOCALE_STORAGE_KEY);
  } catch {
    return null;
  }
}

const initialLocale = resolveInitialLocale(
  readStoredLocale(),
  typeof navigator === "undefined" ? [] : navigator.languages ?? [navigator.language],
);

const i18nextOptions: InitOptions = {
  resources: i18nextResources,
  lng: initialLocale,
  fallbackLng: DEFAULT_LOCALE,
  supportedLngs: supportedLocales,
  defaultNS: "translation",
  interpolation: { escapeValue: false },
  returnObjects: false,
  initAsync: false,
};

void i18n.use(initReactI18next).init(i18nextOptions).catch((error: unknown) => {
  console.error("Failed to initialize i18next", error);
});

export function t(key: string, options: TOptions = {}) {
  return i18n.t(key, options);
}

export const useTranslation = useReactI18nextTranslation;
export { i18n };
