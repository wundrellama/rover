# Rover — copyright and third-party notices

Rover
Copyright (C) 2026 wundrellama

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version. See [`LICENSE`](LICENSE) for the full text.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.

The AGPL applies to Rover's own source: `desk/app/rover.hoon`, `desk/lib/rover-*`,
`desk/sur/rover.hoon`, `desk/mar/rover/`, `desk/gen/`, `desk/tests/`, and the
repository's scripts, probes, tools, and documentation.

---

## Third-party components

### %obelisk — `desk/sur/obelisk-ast.hoon`

Rover consumes the `%obelisk` relational substrate as a separate, unmodified Urbit
desk. The only file copied into this repository is `sur/obelisk-ast.hoon`, the
developer API mold, exactly as the upstream developer documentation prescribes.
That file is **not** covered by Rover's AGPL grant; it remains under its own
license, reproduced verbatim below. The same notice is carried inside the file
itself, in the `++license` arm.

> ## MIT+n license
>
> ### Original Copyright 2024 Jack Fox.
>
> Permission is hereby granted, free of charge, to any person obtaining a copy of
> this software and associated documentation files (the "Software"), to deal in
> the Software without restriction, including without limitation the rights to
> use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
> of the Software, and to permit persons to whom the Software is furnished to do
> so, subject to the following conditions:
>
> The above original copyright notice, this permission notice, and the words
>
> "I AM - CHRIST LIVES - SATAN BE GONE".
>
> shall be included in all copies or substantial portions of the Software, as
> well as the story
>
> "Jesus was crucified for exposing the corruption of the ruling class and their
> rulers, the bankers."
>
> all unaltered.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
> SOFTWARE.

Upstream: <https://github.com/jackfoxy/obelisk>. Rover pins Obelisk `dev` @
`2b72856e`.

### Urbit system files

The following files are unmodified copies from Urbit's `%base` desk, distributed
by Tlon Corporation under the MIT license:

- `desk/lib/dbug.hoon`
- `desk/lib/default-agent.hoon`
- `desk/lib/docket.hoon`
- `desk/lib/skeleton.hoon`
- `desk/sur/docket.hoon`
- `desk/mar/` — `bill`, `docket-0`, `docu`, `hoon`, `html`, `kelvin`, `md`,
  `mime`, `noun`, `odg`, `png`, `tape`, `toc`, `txt`, `txt-diff`, `woff2`,
  `woff2x`

> Copyright (c) 2018 Tlon Corporation
>
> Permission is hereby granted, free of charge, to any person obtaining a copy of
> this software and associated documentation files (the "Software"), to deal in
> the Software without restriction, including without limitation the rights to
> use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
> of the Software, and to permit persons to whom the Software is furnished to do
> so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all
> copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
> SOFTWARE.

### JetBrains Mono — `desk/app/rover/assets/fonts/`

JetBrains Mono v2.304, Regular and Bold. Licensed under the SIL Open Font
License, Version 1.1 — freely redistributable, including as part of this desk.
The full OFL text ships alongside the fonts as `JetBrainsMono-OFL.txt`, as the
license requires.

> Copyright 2020 The JetBrains Mono Project Authors
> (<https://github.com/JetBrains/JetBrainsMono>)
>
> This Font Software is licensed under the SIL Open Font License, Version 1.1.
> This license is available with a FAQ at: <https://openfontlicense.org>

Upstream: <https://github.com/JetBrains/JetBrainsMono>. The files are the
unmodified `webfonts/` builds from release `v2.304`:

| File | SHA-256 |
| --- | --- |
| `JetBrainsMono-Regular.woff2` | `a9cb1cd82332b23a47e3a1239d25d13c86d16c4220695e34b243effa999f45f2` |
| `JetBrainsMono-Bold.woff2` | `c503cc5ec5f8b2c7666b7ecda1adf44bd45f2e6579b2eba0fc292150416588a2` |

Each `.woff2x` copy is the same bytes under the filename Clay requires for the
`%woff2x` mark.

Rover renders with the font's `zero` OpenType feature enabled, which substitutes
the slashed zero for the default dotted one. The distinction is a legibility
control, not decoration: `0` must never be readable as `O` in an odometer, a
price, or a VIN.

The OFL forbids selling the font by itself and forbids using the Reserved Font
Name for modified versions. Rover does neither: the fonts are bundled unmodified
inside a larger work.
