// @vitest-environment jsdom

import { act } from "react";
import { createRoot, type Root } from "react-dom/client";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { i18n } from "@/i18n";
import { LOCALE_STORAGE_KEY } from "@/i18n/locale-preference";
import { LanguageToggle } from "./LanguageToggle";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
(globalThis as any).IS_REACT_ACT_ENVIRONMENT = true;

describe("LanguageToggle", () => {
  let container: HTMLDivElement;
  let root: Root;

  beforeEach(async () => {
    container = document.createElement("div");
    document.body.appendChild(container);
    root = createRoot(container);
    await i18n.changeLanguage("en");
  });

  afterEach(async () => {
    act(() => root.unmount());
    container.remove();
    localStorage.clear();
    await i18n.changeLanguage("en");
  });

  it("offers each selectable locale by its native name and code", async () => {
    act(() => {
      root.render(<LanguageToggle locales={["en", "pt-BR"]} />);
    });

    const trigger = container.querySelector("button");
    await act(async () => {
      trigger?.dispatchEvent(new PointerEvent("pointerdown", { bubbles: true, button: 0 }));
      trigger?.dispatchEvent(new MouseEvent("click", { bubbles: true }));
      await new Promise((resolve) => window.setTimeout(resolve, 0));
    });

    const options = Array.from(document.body.querySelectorAll('[data-slot="dropdown-menu-radio-item"]'));
    expect(options).toHaveLength(2);
    expect(options.map((option) => option.textContent)).toEqual([
      expect.stringContaining("English"),
      expect.stringContaining("Português (Brasil)"),
    ]);
    expect(options[1]?.textContent).toContain("pt-BR");
  });

  it("switches to a selected locale, persists it, and updates the document language", async () => {
    let afterToggleCalls = 0;
    act(() => {
      root.render(<LanguageToggle locales={["en", "pt-BR"]} onAfterToggle={() => { afterToggleCalls += 1; }} />);
    });

    const button = container.querySelector("button");
    expect(button?.textContent).toContain("English");
    expect(button?.getAttribute("aria-label")).toBe(
      "Change the interface language. Some areas may still appear in English.",
    );

    await act(async () => {
      button?.dispatchEvent(new PointerEvent("pointerdown", { bubbles: true, button: 0 }));
      button?.dispatchEvent(new MouseEvent("click", { bubbles: true }));
      await new Promise((resolve) => window.setTimeout(resolve, 0));
      const ptBrOption = Array.from(document.body.querySelectorAll('[data-slot="dropdown-menu-radio-item"]'))
        .find((option) => option.textContent?.includes("pt-BR"));
      ptBrOption?.dispatchEvent(new MouseEvent("click", { bubbles: true }));
      await new Promise((resolve) => window.setTimeout(resolve, 0));
    });

    expect(i18n.language).toBe("pt-BR");
    expect(localStorage.getItem(LOCALE_STORAGE_KEY)).toBe("pt-BR");
    expect(document.documentElement.lang).toBe("pt-BR");
    expect(afterToggleCalls).toBe(1);
    expect(container.querySelector("button")?.textContent).toContain("Português (Brasil)");
    expect(container.querySelector("button")?.getAttribute("aria-label")).toBe(
      "Altera o idioma da interface. Algumas partes ainda podem aparecer em inglês.",
    );
  });

  it("renders nothing when only one locale is selectable", () => {
    act(() => {
      root.render(<LanguageToggle locales={["en"]} />);
    });
    expect(container.querySelector("button")).toBeNull();
  });
});
