# ForkFuel

Fuel that matches the session. ForkFuel is an offline-first calorie and macro tracker for athletes who eat differently on Training days than on Rest days. There is no account, no ads, and no remote configuration. Food data comes from [Open Food Facts](https://world.openfoodfacts.org). The app is a personal food log, not medical advice.

## Architecture

The Composable Architecture (TCA) 1.26.1, pinned exactly in `project.yml`.

A calorie log is a tree of decisions: which day, which training tag, which catalog hit, how many grams, which slot, eaten or planned. TCA keeps that tree as value-type state. `RootFeature` owns a `StackState` path and composes children with `Scope`. Every mutation happens in `Reducer.body`. Network and SwiftData work returns as `Effect.run`. Each service is a `@Dependency` with its own `DependencyKey` (`NutritionGateway`, `FuelVaultClient`, haptics, calendar, preference flags).

This fits ForkFuel because the linear stack (Today → Catalog → Detail → Assign → Today) is a navigation state machine, and Training vs Rest is a pure policy (`TrainingDayPolicy`) that the UI must not reinvent.

`ModelContext` is not `Sendable`. Persistence runs inside `@ModelActor FuelVaultActor` and maps to Sendable snapshots before crossing back to the store.

## Training-day mode

Each calendar day is tagged Training or Rest. Each tag has its own energy and macro targets. Today's meters use the active tag. Session Tags pre-tags the next 14 days. Weekdays default to Training; weekends default to Rest until the user overrides. This is the reason to pick ForkFuel over a single-budget tracker.

## How this app is different

- TCA + `StackState`, not UIKit coordinators or a tab root.
- Search and scan share one Catalog screen with inner segments.
- The eaten log is inline on Today. Plan and Goals push from Today.
- Slots are Pre-Fuel, Refuel, Recovery, Top-Up. Top-Up remaps to Refuel (Midday) when a future date is chosen.
- Search uses `/api/v2/search` with a fields list and `page_size` 12.
- Day keys are `Calendar.startOfDay`.
- Three UIKit bridges: VisionKit `DataScannerViewController`, `UIPickerView` gram wheel, `UISlider` macro tuner.

Planner horizon: **14 days** from today.

## Build

```bash
cd App04_ForkFuel
/Users/belzephyrus/Documents/gambling/21AUG/tools/xcodegen/bin/xcodegen generate
xcodebuild -scheme ForkFuel -destination 'generic/platform=iOS' build
xcodebuild -scheme ForkFuel -destination 'platform=iOS Simulator,name=iPhone 16' test
```

iOS 17+, Swift 6.2, strict concurrency complete. SPM only. Bundle `com.forkfuel.fuel`. User-Agent `ForkFuel/1.0 (iOS; +https://forkfuel.pro)`.

Demo entries seed only on the Simulator, once, behind `ffl.demo.v1`.

## AI art

Style: flat vector illustration, corporate sports style, clean geometric lines, bold lime accent on charcoal, no gradients, no texture.

Base prompt reused and extended for every asset:

```
flat vector illustration, corporate sports style, clean geometric lines, bold lime accent on charcoal, no gradients, no texture
```

| Image set | Exact prompt used |
| --- | --- |
| `ffl_AppIcon` | flat vector illustration, corporate sports style, clean geometric lines, bold lime accent on charcoal, no gradients, no texture, the app's single emblem, centred, filling the canvas edge to edge |
| `ffl_Splash` | flat vector illustration, corporate sports style, clean geometric lines, bold lime accent on charcoal, no gradients, no texture, a vertical hero composition with a calm, uncluttered centre band |
| `ffl_Onboarding1` | flat vector illustration, corporate sports style, clean geometric lines, bold lime accent on charcoal, no gradients, no texture, a person or object representing discovering what is in packaged food |
| `ffl_Onboarding2` | flat vector illustration, corporate sports style, clean geometric lines, bold lime accent on charcoal, no gradients, no texture, a scanning or measuring motif showing a product being identified |
| `ffl_Onboarding3` | flat vector illustration, corporate sports style, clean geometric lines, bold lime accent on charcoal, no gradients, no texture, a goal or target motif showing daily progress being met |
| `ffl_EmptyLog` | flat vector illustration, corporate sports style, clean geometric lines, bold lime accent on charcoal, no gradients, no texture, an empty vessel, surface or container waiting to be filled |
| `ffl_EmptySearch` | flat vector illustration, corporate sports style, clean geometric lines, bold lime accent on charcoal, no gradients, no texture, a search motif that has come back with nothing found |
| `ffl_EmptyPlan` | flat vector illustration, corporate sports style, clean geometric lines, bold lime accent on charcoal, no gradients, no texture, an empty schedule, grid or horizon with nothing scheduled |
| `ffl_EmptyWish` | flat vector illustration, corporate sports style, clean geometric lines, bold lime accent on charcoal, no gradients, no texture, an empty basket, list or shelf |
| `ffl_SlotPreFuel` | flat vector illustration, corporate sports style, clean geometric lines, bold lime accent on charcoal, no gradients, no texture, a morning motif appropriate to the theme |
| `ffl_SlotRefuel` | flat vector illustration, corporate sports style, clean geometric lines, bold lime accent on charcoal, no gradients, no texture, a midday motif appropriate to the theme |
| `ffl_SlotRecovery` | flat vector illustration, corporate sports style, clean geometric lines, bold lime accent on charcoal, no gradients, no texture, an evening motif appropriate to the theme |
| `ffl_SlotTopUp` | flat vector illustration, corporate sports style, clean geometric lines, bold lime accent on charcoal, no gradients, no texture, a small extra or in-between motif appropriate to the theme |
| `ffl_MacroProtein` | flat vector illustration, corporate sports style, clean geometric lines, bold lime accent on charcoal, no gradients, no texture, a symbol standing for protein, rendered as a single clear emblem |
| `ffl_MacroCarbs` | flat vector illustration, corporate sports style, clean geometric lines, bold lime accent on charcoal, no gradients, no texture, a symbol standing for carbohydrate, rendered as a single clear emblem |
| `ffl_MacroFat` | flat vector illustration, corporate sports style, clean geometric lines, bold lime accent on charcoal, no gradients, no texture, a symbol standing for dietary fat, rendered as a single clear emblem |
| `ffl_ProductPlaceholder` | flat vector illustration, corporate sports style, clean geometric lines, bold lime accent on charcoal, no gradients, no texture, a generic packaged grocery item with no readable branding |
| `ffl_CardBackdrop` | flat vector illustration, corporate sports style, clean geometric lines, bold lime accent on charcoal, no gradients, no texture, an abstract backdrop suitable for sitting behind a product card |
| `ffl_Texture` | generated from the base prompt as a repeating sports surface, then rebuilt as a seamless 2048 tile of lime chevrons and hex marks so edges meet with no visible seam |
| `ffl_ControlFace` | flat vector illustration, corporate sports style, clean geometric lines, bold lime accent on charcoal, no gradients, no texture, the face of a single physical control such as a dial, key or slider handle |
| `ffl_ScanOverlay` | framing reticle with lime L-brackets; centre is fully transparent so the camera feed reads through |
| `ffl_TwistHero` | flat vector illustration, corporate sports style, clean geometric lines, bold lime accent on charcoal, no gradients, no texture, an emblem representing this app's signature feature |
| `ffl_SuccessMark` | flat vector illustration, corporate sports style, clean geometric lines, bold lime accent on charcoal, no gradients, no texture, a confirmation mark or celebratory emblem |
| `ffl_HeaderDecor` | flat vector illustration, corporate sports style, clean geometric lines, bold lime accent on charcoal, no gradients, no texture, a wide decorative band or ornament |

Contact: https://forkfuel.pro/contact-us
