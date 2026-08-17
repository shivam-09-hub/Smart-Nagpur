# Design system

No Stitch screenshots, exports, token files, or brand assets were present when
the greenfield implementation was approved. The current visual system is a
centralized interpretation of the textual brief and must not be described as a
pixel-accurate Stitch reproduction.

`lib/core/theme` centralizes colors, typography, spacing, radii, shadows, icon
choices, and the global Material theme. Civic-service accents are applied only
to identity, icons, calls to action, progress, and small highlights:

- Vendor: blue
- Garbage: green
- Water: cyan/blue
- Roads: orange/amber
- Animals: purple
- Drainage: indigo
- Streetlights: gold
- Public spaces: teal
- Encroachment: coral/red
- Other: slate

The shared layouts use safe areas, scrollable content, minimum touch targets,
semantic labels, text status indicators, and adaptive column counts. When Stitch
artifacts become available, update the centralized tokens and shared widgets
first, then validate each route at the supplied device dimensions.
