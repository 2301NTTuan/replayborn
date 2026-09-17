# Anime title presentation — 2026-09-17

Scope: startup intro and main menu only. Combat sprites and HUD are unchanged by this work.

## Art direction and assets

Original AI-generated artwork created with the imagegen skill/tool using the existing
`assets/original_v1/astria_run_v1.png` as the character identity reference.
Keep navy bob hair, coral streak, amber eyes, black techwear and cyan time energy.
No third-party anime franchise or externally downloaded illustration is used.

- `assets/ui/astria_title.png`: 1024×1536 painted anime key art, nighttime ruined city.
- `assets/ui/replayborn_emblem.png`: 1536×1024 transparent portrait + REPLAYBORN lockup.
- `assets/ui/replayborn_wordmark.png`: 1536×1024 transparent typography-only companion.

Original generated outputs retained in
`C:/Users/tuann/.codex/generated_images/01a0adc2-d793-7501-81dc-06a5405bc27a/`:

- `exec-5e42938c-6597-4753-81c3-0b52ccad18f0.png` → title art.
- `exec-696feab0-3330-4854-9aa4-fa68588a955e.png` → emblem.
- `exec-deb6815f-0421-4f26-8832-4cef87110262.png` → wordmark.

Menu uses the full illustration and only the wordmark, avoiding a second face over
the heroine. Intro uses the complete portrait emblem on a restrained dark background.
The title wordmark is displayed through an AtlasTexture that removes empty vertical
padding; the source asset is unchanged. Smooth gradient scrims protect text contrast.
The only home action remains Play, as requested earlier. Existing subpage methods
remain intact. No economy/navigation dashboard has been reintroduced.

## Behavior

- Intro asynchronously loads the menu, auto-continues after 2.1 seconds, and accepts
  touch, mouse, keyboard or gamepad to skip after 0.15 seconds.
- Reduced motion: 0.5-second intro, no animated particles or menu fade.
- No fictional percentage/loading bar. Loading errors keep a readable message.
- Home uses proportional anchors, a large touch target and keyboard focus on Play.
- Repeated Play input cannot trigger duplicate scene transitions.
- Vietnamese and English text are supported.

## Verification

Run with Godot 4.7.2:

```powershell
godot --headless --path . --script tests/title_flow_smoke.gd
godot --headless --path . --script tests/menu_flow_smoke.gd
godot --path . --rendering-method gl_compatibility --script tools/capture_title.gd
```

The capture script requires a real renderer; it explicitly rejects headless mode.
It captures fresh intro/menu/gameplay frames in `artifacts/ui_qa/`.
9:20 and 3:4 use rendered SubViewports with asserted pixel and logical dimensions,
so Windows cannot silently clamp a tall capture window. Screens cover 540×960,
540×1200 and 768×1024, Vietnamese/English, and touch Play → gameplay.
QA artifacts are local and excluded from exports. This is desktop-rendered QA,
not verification on a physical Android device.

Result: title-flow smoke, existing menu-flow smoke, and rendered visual/flow QA pass.
Godot currently reports two RefCounted ObjectDB instances at shutdown for the
boot/scene-transition harnesses; there are no script errors or failed assertions.
This warning is not treated as proof of a clean resource-leak audit.

## Generation prompts

### Title key art

Use case: stylized-concept. Create a polished original anime game title-screen key visual, portrait 1024x1536. Input is a character identity reference only: Astria has short windswept navy-black bob hair, coral-pink hair streak by ear, amber eyes, black urban technical jacket, coral straps, cyan wrist time-energy. Redraw her beautifully as a single confident young adult heroine, waist-up in three-quarter view, face turned toward viewer, excellent anatomy, detailed eyes and hair, serious warm expression. A dramatic dark midnight-blue ruined futuristic city with restrained turquoise time-light ribbons, distant architecture in mist and a few pink sparks. Character occupies middle 55 percent of vertical canvas, head around 32 percent height; keep upper 18 percent dark atmospheric empty space for a separate logo and bottom 23 percent mostly dark for a real UI button. Rich hand-painted anime key art, exquisite linework, luminous rim lighting, cinematic composition. Face is the focal point, never a cropped tiny sprite. No text, no logo, no interface, no watermark. No other characters. Do not imitate any existing anime franchise.

### Portrait lockup

Use case: logo-brand. Deliver ONE premium game logo lockup on genuine transparent alpha background, wide 1536x1024 canvas. Brand exact text REPLAYBORN (R E P L A Y B O R N), one word on a single line, very legible sharp white custom sci-fi sans lettering with restrained cyan lower edges, no other text. Above the word, a beautifully illustrated compact anime head emblem of Astria using attached original character as identity reference: short tousled navy-black hair, distinctive coral streak near her ear, amber eyes, confident three-quarter face toward viewer, black high collar. Face drawn anew as intentional finished emblem with beautifully tapered contour, NOT rectangle cut from a sprite, no truncated shoulders. A small angular cyan fractured-time crest behind hair, subtle coral accent. Emblem and lettering form an integrated balanced silhouette, symbol no more than half total lockup width, strong graphic clarity at small sizes, polished commercial anime game branding. Restrained effects, no glowing circles, no tiny technical text, no drop shadow square, no mockup, no watermark, no extra text. Generous transparent outer margins, no opaque background. Retain character identity, no existing franchise imitation.

### Companion wordmark

Create the companion typography-only logo for this exact attached game brand. Exact text REPLAYBORN, same beautiful custom angular white sci-fi lettering with turquoise lower edge. Single horizontal line, all 10 letters fully legible. Remove the anime portrait and ALL emblems and background haze completely. Only the crisp lettering, restrained cyan edge lighting, generous clean transparent margins. Genuine fully transparent alpha background everywhere outside the actual letterforms. No black rectangle, no background, no glow cloud, no subtitle, no additional objects. 1536x1024 canvas with text horizontally centered in middle 35% of canvas height. Match the original letter design closely.
