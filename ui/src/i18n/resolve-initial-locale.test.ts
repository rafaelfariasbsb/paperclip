import { describe, expect, it } from "vitest";

import { resolveInitialLocale } from "./index";

const supported = ["en", "pt-BR", "pt-PT", "es", "zh-CN"];

describe("resolveInitialLocale", () => {
  it("prefers a stored locale over the browser languages", () => {
    expect(resolveInitialLocale("es", ["pt-BR"], supported)).toBe("es");
  });

  it("matches an exact browser locale case-insensitively", () => {
    expect(resolveInitialLocale(null, ["pt-br"], supported)).toBe("pt-BR");
  });

  it("falls back to a supported locale with the same base language", () => {
    expect(resolveInitialLocale(null, ["es-MX"], supported)).toBe("es");
    expect(resolveInitialLocale(null, ["zh"], supported)).toBe("zh-CN");
  });

  it("skips unsupported entries and uses the next browser language", () => {
    expect(resolveInitialLocale("xx", ["de-DE", "pt-BR"], supported)).toBe("pt-BR");
  });

  it("returns the default locale when nothing matches", () => {
    expect(resolveInitialLocale(null, ["de-DE"], supported)).toBe("en");
    expect(resolveInitialLocale(null, [], supported)).toBe("en");
  });
});
