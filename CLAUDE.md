# CLAUDE.md

Guidance for AI-assisted work in the KubeAid repository. These are conventions you would get wrong
without being told; general context lives in README.md and docs/.

## Architecture diagram style

The README architecture diagram is the hand-authored SVG pair `docs/images/kubeaid-architecture.svg`
(light) and `kubeaid-architecture-dark.svg` (dark), drawn in the classic **Prometheus
architecture-overview style**. When editing:

- **Edit the light file first**, then regenerate the dark file by applying the palette swap below.
  Geometry and text must stay identical between the two — only colors differ.
- **Visual language** (keep it): plain rectangular boxes with thin strokes; warm orange fill for the
  key component the reader interacts with; a blue header-plus-bullets info box for reference data;
  grey for infrastructure (node-style) boxes; a dashed orange border around the main system group;
  thin grey orthogonal arrows with small 12px labels on them ("git push", "values", "applies");
  stacked offset rectangles to show multiplicity. No rounded pill cards, no gradients, no legends —
  labels live on the arrows.
- **Real project icons** are inlined as nested `<svg x= y= width= height= viewBox=>` elements so the
  file stays self-contained (GitHub and kubeaid.io both render it without network access). Before
  inlining a third-party SVG, **namespace every `id`, `class`, and gradient reference** (e.g.
  `cls-` → `capicls-`, `linear-gradient` → `capi-lg`) — SVG styles and ids are document-global and
  will otherwise collide. Current icons: Argo CD (CNCF artwork), Git (git-scm.com, Jason Long),
  KubeAid K-mark (kubeaid.io nav logo), Cluster API turtle (kubernetes-sigs/cluster-api docs/logos).
- The KubeAid K-mark's ink path is `#11151c` in light and `#E6EDF3` in dark — it is part of the
  palette swap.

### Palette (light → dark)

| Class / element | Light | Dark |
| --- | --- | --- |
| `.box` fill / stroke | `#FFFFFF` / `#666666` | `#161B22` / `#8B949E` |
| `.keybox` (key component) | `#FFE7C8` / `#666666` | `#3D2E17` / `#BB8009` |
| `.infohead` (info box header) | `#AFD3EE` / `#666666` | `#1F3A5F` / `#58A6FF` |
| `.infobody` (info box body) | `#E1F0FB` / `#666666` | `#14273D` / `#58A6FF` |
| `.greybox` (node-style) | `#E6E6E6` / `#888888` | `#30363D` / `#8B949E` |
| `.group` (dashed system border) | `#FFF7EC` / `#C77E2E` | `#1C1712` / `#BB8009` |
| titles `.t` `.tt` | `#1F2328` | `#E6EDF3` |
| body text `.b` `.chipt` | `#1F2328` | `#C9D1D9` |
| secondary `.s` `.lbl` | `#57606A` | `#9DA7B3` |
| arrows `.edge` + marker | `#666666` | `#8B949E` |
| K-mark ink path | `#11151c` | `#E6EDF3` |

The README embeds the pair with a `<picture>` element (`prefers-color-scheme: dark` source), so both
files must always be updated together.

## Content accuracy rules

- Never document a command, flag, or config key without verifying it against the kubeaid-cli source
  or the charts in this repository. The docs have been burned by invented examples before.
- Access management: NetBird mesh + Keycloak SSO is the default; Teleport is deprecated.
- The kubeaid-config repository is the only repo a user must create (from the sample template);
  mirroring KubeAid itself is optional and recommended for production, not a prerequisite.
