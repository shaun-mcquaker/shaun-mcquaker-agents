---
name: frontend-design
description: Use when building or polishing UI. Applies deliberate typography, colour, layout, motion, and responsive design standards so interfaces do not collapse into generic AI-looking pages.
---

# Frontend Design

Use this skill whenever the work includes pages, components, styling, layout, interactions, or visual polish.

## Goals

- Build interfaces that feel intentional, not boilerplate.
- Preserve the existing design system when the repo already has one.
- When no design system exists, make a clear visual choice and carry it through consistently.

## Visual Rules

### Typography

- Avoid default stacks like Inter, Roboto, Arial, or raw system UI unless the codebase already standardizes on them.
- Pick a type direction that matches the product.
- Use clear hierarchy: one strong display style, one body style, one utility style.

### Colour

- Define a small palette with purpose.
- Prefer CSS variables or theme tokens over scattered literals.
- Avoid generic purple-on-white defaults.
- Use contrast intentionally for hierarchy and state.

### Layout

- Create strong focal points.
- Use spacing deliberately; do not let everything sit in evenly padded boxes.
- Design for both desktop and mobile from the start.

### Backgrounds

- Avoid flat, empty backgrounds when the page needs atmosphere.
- Use gradients, subtle noise, soft shapes, or restrained patterns where appropriate.

### Motion

- Prefer a few meaningful transitions over constant micro-animation.
- Good defaults: page reveal, staggered entrance, emphasis on state change.

## Implementation Rules

- Reuse existing primitives first.
- If introducing new tokens or helpers, centralize them.
- Keep accessibility intact: semantic HTML, focus states, reduced-motion friendly behaviour, and sufficient colour contrast.
- Test mobile and desktop layouts before calling work done.
