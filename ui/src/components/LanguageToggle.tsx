import { Languages } from "lucide-react";

import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuRadioGroup,
  DropdownMenuRadioItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { cn } from "@/lib/utils";
import { availableLocales, setLocale, useTranslation } from "@/i18n";
import { localeDisplayName } from "@/i18n/locale-preference";
import { TruncatedText } from "./TruncatedText";

type LanguageToggleVariant = "menu-action" | "compact-menu-action";

interface LanguageToggleProps {
  className?: string;
  variant?: LanguageToggleVariant;
  locales?: readonly string[];
  onAfterToggle?: () => void;
}

export function LanguageToggle({
  className,
  variant = "compact-menu-action",
  locales = availableLocales,
  onAfterToggle,
}: LanguageToggleProps) {
  const { t, i18n } = useTranslation();
  const currentLocale = i18n.resolvedLanguage ?? i18n.language;
  const currentLocaleName = localeDisplayName(currentLocale);
  const accessibleLabel = t("app.language.description");

  function handleLocaleChange(locale: string) {
    void setLocale(locale).then(() => onAfterToggle?.());
  }

  const localeMenu = (
    <DropdownMenuContent
      align={variant === "menu-action" ? "start" : "end"}
      className="w-(--sz-16rem)"
    >
      <DropdownMenuRadioGroup value={currentLocale} onValueChange={handleLocaleChange}>
        {locales.map((locale) => (
          <DropdownMenuRadioItem key={locale} value={locale}>
            <span className="min-w-0 flex-1 truncate" lang={locale}>
              {localeDisplayName(locale)}
            </span>
            <span className="font-mono text-xs text-muted-foreground">{locale}</span>
          </DropdownMenuRadioItem>
        ))}
      </DropdownMenuRadioGroup>
    </DropdownMenuContent>
  );

  if (locales.length < 2) return null;

  if (variant === "menu-action") {
    return (
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <button
            type="button"
            className={cn(
              "flex w-full items-start gap-3 rounded-xl px-3 py-3 text-left transition-colors hover:bg-accent/60",
              className,
            )}
            aria-label={accessibleLabel}
          >
            <span className="mt-0.5 rounded-lg border border-border bg-background/70 p-2 text-muted-foreground">
              <Languages className="size-4" />
            </span>
            <span className="min-w-0 flex-1">
              <span className="block text-sm font-medium text-foreground" lang={currentLocale}>
                {currentLocaleName}
              </span>
              <span className="block text-xs text-muted-foreground">{accessibleLabel}</span>
            </span>
          </button>
        </DropdownMenuTrigger>
        {localeMenu}
      </DropdownMenu>
    );
  }

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <button
          type="button"
          className={cn(
            "flex h-(--profile-popover-row-height) w-full items-center gap-(--profile-popover-row-gap) rounded-lg px-2.5 text-left text-(length:--text-compact) font-medium leading-(--profile-popover-label-line-height) text-foreground transition-colors hover:bg-accent",
            className,
          )}
          aria-label={accessibleLabel}
        >
          <span className="flex size-5 shrink-0 items-center justify-center text-muted-foreground">
            <Languages className="size-4" />
          </span>
          <TruncatedText className="min-w-0 flex-1 truncate">
            <span lang={currentLocale}>{currentLocaleName}</span>
          </TruncatedText>
        </button>
      </DropdownMenuTrigger>
      {localeMenu}
    </DropdownMenu>
  );
}
