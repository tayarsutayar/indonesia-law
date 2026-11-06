# Tailwind CSS & React Component Guide: Apple Design System

This guide translates the Apple Web Design System tokens into **Tailwind CSS classes** and **React component snippets**.

---

## 1. Tailwind Config Extension (`tailwind.config.ts`)

```typescript
import type { Config } from "tailwindcss";

const config: Config = {
  theme: {
    extend: {
      colors: {
        apple: {
          blue: "#0066cc",
          "blue-focus": "#0071e3",
          "blue-dark": "#2997ff",
          canvas: "#ffffff",
          parchment: "#f5f5f7",
          pearl: "#fafafc",
          "tile-1": "#272729",
          "tile-2": "#2a2a2c",
          "tile-3": "#252527",
          ink: "#1d1d1f",
          "ink-muted-80": "#333333",
          "ink-muted-48": "#7a7a7a",
          hairline: "#e0e0e0",
          "divider-soft": "#f0f0f0",
        },
      },
      fontFamily: {
        sans: [
          "SF Pro Text",
          "SF Pro Display",
          "system-ui",
          "-apple-system",
          "BlinkMacSystemFont",
          "Inter",
          "sans-serif",
        ],
      },
      fontSize: {
        "apple-hero": ["56px", { lineHeight: "1.07", letterSpacing: "-0.28px", fontWeight: "600" }],
        "apple-display-lg": ["40px", { lineHeight: "1.10", letterSpacing: "0px", fontWeight: "600" }],
        "apple-display-md": ["34px", { lineHeight: "1.47", letterSpacing: "-0.374px", fontWeight: "600" }],
        "apple-lead": ["28px", { lineHeight: "1.14", letterSpacing: "0.196px", fontWeight: "400" }],
        "apple-tagline": ["21px", { lineHeight: "1.19", letterSpacing: "0.231px", fontWeight: "600" }],
        "apple-body": ["17px", { lineHeight: "1.47", letterSpacing: "-0.374px", fontWeight: "400" }],
        "apple-body-strong": ["17px", { lineHeight: "1.24", letterSpacing: "-0.374px", fontWeight: "600" }],
        "apple-caption": ["14px", { lineHeight: "1.43", letterSpacing: "-0.224px", fontWeight: "400" }],
        "apple-fine-print": ["12px", { lineHeight: "1.0", letterSpacing: "-0.12px", fontWeight: "400" }],
      },
      borderRadius: {
        "apple-sm": "8px",
        "apple-md": "11px",
        "apple-lg": "18px",
      },
      boxShadow: {
        "apple-product": "3px 5px 30px 0 rgba(0, 0, 0, 0.22)",
      },
    },
  },
};
export default config;
```

---

## 2. React Components

### A. Primary Blue Pill Button (`button-primary`)

```tsx
import React from "react";

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  children: React.ReactNode;
  variant?: "primary" | "secondary";
}

export const AppleButton: React.FC<ButtonProps> = ({
  children,
  variant = "primary",
  className = "",
  ...props
}) => {
  const baseStyle =
    "inline-flex items-center justify-center rounded-full px-[22px] py-[11px] text-[17px] font-normal leading-[1.47] tracking-[-0.374px] transition-transform duration-150 ease-out active:scale-95 focus:outline-none focus:ring-2 focus:ring-[#0071e3]";

  const variantStyle =
    variant === "primary"
      ? "bg-[#0066cc] text-white hover:bg-[#0071e3]"
      : "bg-transparent text-[#0066cc] border border-[#0066cc] hover:bg-[#0066cc]/5";

  return (
    <button className={`${baseStyle} ${variantStyle} ${className}`} {...props}>
      {children}
    </button>
  );
};
```

---

### B. Frosted Sub-Navigation Bar (`sub-nav-frosted`)

```tsx
import React from "react";

export const AppleSubNav: React.FC<{ title: string; onActionClick?: () => void }> = ({
  title,
  onActionClick,
}) => {
  return (
    <div className="sticky top-0 z-40 w-full h-[52px] bg-[#f5f5f7]/80 backdrop-blur-md border-b border-black/[0.08] px-6 flex items-center justify-between">
      <span className="text-[21px] font-semibold tracking-[0.231px] text-[#1d1d1f]">
        {title}
      </span>
      <div className="flex items-center gap-4">
        <button
          onClick={onActionClick}
          className="rounded-full bg-[#0066cc] px-4 py-1.5 text-[14px] text-white font-normal active:scale-95 transition-transform"
        >
          Buy
        </button>
      </div>
    </div>
  );
};
```

---

### C. Product Tile Section (`product-tile-light` & `product-tile-dark`)

```tsx
import React from "react";

interface ProductTileProps {
  theme?: "light" | "parchment" | "dark";
  title: string;
  tagline: string;
  primaryActionLabel?: string;
  secondaryActionLabel?: string;
  imageSrc?: string;
  imageAlt?: string;
}

export const AppleProductTile: React.FC<ProductTileProps> = ({
  theme = "light",
  title,
  tagline,
  primaryActionLabel = "Learn more",
  secondaryActionLabel = "Buy",
  imageSrc,
  imageAlt = "Product image",
}) => {
  const bgClasses = {
    light: "bg-white text-[#1d1d1f]",
    parchment: "bg-[#f5f5f7] text-[#1d1d1f]",
    dark: "bg-[#272729] text-white",
  }[theme];

  return (
    <section className={`w-full py-20 px-6 flex flex-col items-center text-center ${bgClasses}`}>
      <h2 className="text-[40px] md:text-[56px] font-semibold tracking-[-0.28px] leading-[1.07]">
        {title}
      </h2>
      <p className="mt-3 text-[21px] md:text-[28px] font-normal leading-[1.14] tracking-[0.196px] text-neutral-400">
        {tagline}
      </p>

      <div className="mt-6 flex items-center gap-4">
        <button className="rounded-full bg-[#0066cc] px-[22px] py-[11px] text-[17px] text-white active:scale-95 transition-transform">
          {primaryActionLabel}
        </button>
        {secondaryActionLabel && (
          <button className="rounded-full border border-[#0066cc] text-[#0066cc] px-[22px] py-[11px] text-[17px] active:scale-95 transition-transform">
            {secondaryActionLabel}
          </button>
        )}
      </div>

      {imageSrc && (
        <div className="mt-12 max-w-4xl w-full flex justify-center">
          <img
            src={imageSrc}
            alt={imageAlt}
            className="w-full object-contain filter drop-shadow-[3px_5px_30px_rgba(0,0,0,0.22)]"
          />
        </div>
      )}
    </section>
  );
};
```

---

### D. Store Utility Card (`store-utility-card`)

```tsx
import React from "react";

export const AppleStoreCard: React.FC<{
  title: string;
  price: string;
  imageSrc: string;
  actionLabel?: string;
}> = ({ title, price, imageSrc, actionLabel = "Buy" }) => {
  return (
    <div className="w-full max-w-[320px] rounded-[18px] bg-white border border-[#e0e0e0] p-6 flex flex-col items-center text-center">
      <div className="w-full aspect-square rounded-[8px] overflow-hidden flex items-center justify-center p-4">
        <img
          src={imageSrc}
          alt={title}
          className="w-full h-full object-contain filter drop-shadow-[3px_5px_30px_rgba(0,0,0,0.22)]"
        />
      </div>
      <h3 className="mt-4 text-[17px] font-semibold text-[#1d1d1f] tracking-[-0.374px]">
        {title}
      </h3>
      <p className="mt-1 text-[17px] text-[#1d1d1f] font-normal">
        {price}
      </p>
      <a
        href="#buy"
        className="mt-3 text-[17px] text-[#0066cc] hover:underline"
      >
        {actionLabel} &gt;
      </a>
    </div>
  );
};
```

