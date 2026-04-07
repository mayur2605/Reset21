# Design System Strategy: Reset21 – Discipline Builder

## 1. Overview & Creative North Star
This design system is anchored by a Creative North Star we define as **"The Kinetic Archive."** 

It is a visual rejection of the soft, overly-sanitized "SaaS look." Instead, it draws from high-end editorial layouts and the raw, honest energy of the physical habit tracker provided in the reference. By combining the unyielding structure of Neobrutalism with a sophisticated typographic scale, we create an interface that feels like a prestigious physical planner translated into a high-performance digital tool. 

We break the "template" look through intentional asymmetry: heavy, offset shadows that ground elements in a 3D space, and a juxtaposition between the Swiss-style precision of **Inter** and the utilitarian, data-driven soul of **JetBrains Mono**.

---

## 2. Color Architecture
Our palette uses high-chroma accents against a sophisticated neutral base to ensure every interaction feels deliberate and high-stakes.

### Tonal Tokens
- **Primary (The Catalyst):** `#FDC800` (`primary_container`) — Used for primary actions and the "glow" of progress.
- **Secondary (The Deep Focus):** `#432DD7` (`secondary`) — Reserved for secondary navigation and focus-mode elements.
- **Surface (The Canvas):** `#FBFBF9` (`surface`) — An off-white that prevents eye strain and feels like premium paper.
- **Functional States:** Success `#16A34A` (`tertiary`), Warning `#D97706`, Danger `#DC2626` (`error`).

### The Rules of Engagement
- **The "No-Line" Rule for Layout:** Prohibit 1px solid borders for structural sectioning. Boundaries between major page sections must be defined solely through background color shifts (e.g., a `surface_container_low` section sitting on a `surface` background).
- **Surface Hierarchy & Nesting:** Treat the UI as stacked physical layers. An inner habit card should use `surface_container_lowest` to "pop" against a `surface_container` background.
- **The "Glass & Gradient" Rule:** To elevate the "standard" Neobrutalist look, use a 10% opacity `surface_variant` with a 20px backdrop blur for floating headers or navigation bars. For primary CTAs, apply a subtle linear gradient from `primary` to `primary_fixed_dim` at 45 degrees to add a signature "soul" to the flat surfaces.

---

## 3. Typography: Editorial Authority
Typography is the primary driver of the "Discipline Builder" ethos.

- **Display & Headlines (Inter):** Set with tight tracking (-2%) and heavy weights. Use `display-lg` (3.5rem) for day counters (e.g., "DAY 04") to create an authoritative, "no-excuses" atmosphere.
- **Data & Metrics (JetBrains Mono):** All numbers, step counts (e.g., "5,635 steps"), and timestamps (e.g., "7 AM") must use this monospaced face. It signals precision and accountability.
- **Labels (Space Grotesk):** Use for micro-copy and tags. The geometric nature of Space Grotesk at `label-md` (0.75rem) provides a technical contrast to the editorial headlines.

---

## 4. Elevation & Depth: The Stacking Principle
In this system, depth is not an illusion of light, but a physical manifestation of weight.

- **Hard Shadows:** Interactive elements (buttons, active cards) use a 3px or 4px hard offset shadow with **0% blur**. The shadow color must be `#1C293C` (Text) or a 100% opaque version of the element’s border color.
- **The Layering Principle:** Use Tonal Layering for non-interactive hierarchy. Place a `surface_container_highest` element on a `surface` background to create a "soft lift" without the aggression of a shadow.
- **The "Ghost Border" Fallback:** For non-critical containers, avoid heavy black lines. Instead, use a "Ghost Border": the `outline_variant` token at 15% opacity. This maintains the boxy structure without cluttering the user’s cognitive load.

---

## 5. Components

### 5.1 The Discipline Card (Signature Component)
Inspired by the handwritten tracker, these cards house habits like "Meditation" and "3L Water."
- **Style:** `surface_container_lowest` background, 3px solid `#1C293C` border, 4px hard offset shadow.
- **Radius:** `0px` for a brutal, architectural feel.
- **Content:** The task name in `title-lg` (Inter), and the metric or status in `body-sm` (JetBrains Mono).

### 5.2 Kinetic Buttons
- **Primary:** Background `#FDC800`, 3px black border, 4px black shadow. On press, the shadow disappears and the button shifts 4px down and right (simulating a physical press).
- **Secondary:** Background `#FBFBF9`, 2px black border, no shadow. Use for "Add Habit" or "Dismiss."

### 5.3 High-Contrast Progress Bars
- **Frame:** 4px solid `#1C293C` container.
- **Fill:** Solid `#16A34A` (Success) or `#432DD7` (Secondary).
- **Detail:** No rounded caps. The progress should look like a block being filled in a factory, reinforcing the "Discipline Builder" theme.

### 5.4 Habit Checkbox (The "Mark" Action)
Directly translating the "X" and "Checkmark" from the reference image.
- **State - Incomplete:** A simple 3px black box.
- **State - Complete:** Fill with `primary` and an "X" or "Check" in `on_primary`. The stroke of the mark should match the 3px border weight.

---

## 6. Do’s and Don’ts

### Do:
- **Embrace White Space:** With bold borders and high contrast, the UI needs air. Use `surface` areas to let the eye rest between "Discipline Cards."
- **Mix the Type:** Always pair Inter for words and JetBrains Mono for numbers. This is the hallmark of the system's sophisticated data visualization.
- **Align Asymmetrically:** Feel free to offset the "Day of 21 Day Reset" header to the left while keeping the status "Remarks (05/10)" pinned to the hard right.

### Don’t:
- **No Soft Shadows:** Never use `box-shadow` with a blur radius. It breaks the "Kinetic Archive" aesthetic.
- **No Rounded Corners:** Keep the radius between `0px` and `4px`. Anything higher (like the standard 8px or 12px) will make the app look like a generic consumer product rather than a disciplined tool.
- **No Dividers:** Avoid using horizontal lines to separate list items. Use the "No-Line" rule: use a subtle background shift (e.g., alternating between `surface` and `surface_container_low`) or vertical whitespace.

---

## 7. Habit Item Translation (From Reference Image)
The following items from the handwritten log are to be treated as high-priority "Discipline Cards":
1. **Wake up @ 6am** (Inter Headline / JetBrains Mono Time)
2. **Meditation** (Inter Headline)
3. **Exercise** (Inter Headline)
4. **Skin Care Routine** (Inter Headline)
5. **Complete 10K steps** (Inter Headline / JetBrains Mono Steps)
6. **3L Water** (Inter Headline / JetBrains Mono Volume)
7. **No Junk & Sugar** (Inter Headline - Warning State)
8. **1 hr Study** (Inter Headline / JetBrains Mono Duration)
9. **Read book** (Inter Headline)
10. **Plan next day** (Inter Headline)

*Director’s Closing Note: Ensure the "Remarks" section at the bottom of the UI uses a handwritten-style script font or a very loose 'body-md' Inter to mimic the personality of the original note's "Not every day is productive, but I didn't quit" quote.*