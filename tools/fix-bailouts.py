#!/usr/bin/env python3
"""Rewrite the silent-drop bail-outs in app/rover.hoon.

Standard shape: a handler reads http-pending plus one input map, and
returns bare `this when either lookup misses. The rewrite answers 503
with a human reason when eyre-id is present and the input is missing,
and deletes the orphaned pending keys. When eyre-id is absent nobody is
listening, so bare `this stays.
"""
import re
import sys

PATH = "desk/app/rover.hoon"
REASON = "'Rover restarted while saving. Please submit again.'"

text = open(PATH).read()

give_503 = (
    "        %:  http-give\n"
    "            u.eyre-id\n"
    "            503\n"
    "            ['content-type' 'text/plain']~\n"
    "            `(text-octs {reason})\n"
    "        ==\n"
)

# --- standard two-map shape ---------------------------------------------------
std = re.compile(
    r"      =/  eyre-id  \(~\(get by http-pending\) wire\)\n"
    r"      =/  (?P<name>[a-z-]+)  \(~\(get by (?P<map>[a-z-]+)\) wire\)\n"
    r"      \?:  \?\|  \?=\(~ eyre-id\)\n"
    r"              \?=\(~ (?P=name)\)\n"
    r"          ==\n"
    r"        `this\n"
)


def std_repl(m):
    name, map_ = m.group("name"), m.group("map")
    return (
        f"      =/  eyre-id  (~(get by http-pending) wire)\n"
        f"      =/  {name}  (~(get by {map_}) wire)\n"
        f"      ?~  eyre-id\n"
        f"        `this\n"
        f"      ?~  {name}\n"
        f"        :_  this(http-pending (~(del by http-pending) wire))\n"
        + give_503.format(reason=REASON)
    )


text, n_std = std.subn(std_repl, text)

# --- three-map shape: rover-fill-lookup ---------------------------------------
fill = (
    "      =/  eyre-id  (~(get by http-pending) wire)\n"
    "      =/  input  (~(get by fill-pending) wire)\n"
    "      =/  body  (~(get by fill-body-pending) wire)\n"
    "      ?:  ?|  ?=(~ eyre-id)\n"
    "              ?=(~ input)\n"
    "              ?=(~ body)\n"
    "          ==\n"
    "        `this\n"
)
fill_new = (
    "      =/  eyre-id  (~(get by http-pending) wire)\n"
    "      =/  input  (~(get by fill-pending) wire)\n"
    "      =/  body  (~(get by fill-body-pending) wire)\n"
    "      ?~  eyre-id\n"
    "        `this\n"
    "      ?:  ?|  ?=(~ input)\n"
    "              ?=(~ body)\n"
    "          ==\n"
    "        :_  %_  this\n"
    "              http-pending  (~(del by http-pending) wire)\n"
    "              fill-pending  (~(del by fill-pending) wire)\n"
    "              fill-body-pending  (~(del by fill-body-pending) wire)\n"
    "            ==\n"
    + give_503.format(reason=REASON)
)
n_fill = text.count(fill)
text = text.replace(fill, fill_new)

# --- consumable-lookup: %.n-res folded into the same bail ---------------------
clk = (
    "      =/  eyre-id  (~(get by http-pending) wire)\n"
    "      =/  body  (~(get by fill-body-pending) wire)\n"
    "      ?:  ?|  ?=(%.n -.res)\n"
    "              ?=(~ eyre-id)\n"
    "              ?=(~ body)\n"
    "          ==\n"
    "        `this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))\n"
)
clk_new = (
    "      =/  eyre-id  (~(get by http-pending) wire)\n"
    "      =/  body  (~(get by fill-body-pending) wire)\n"
    "      ?~  eyre-id\n"
    "        `this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))\n"
    "      ?~  body\n"
    "        :_  this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))\n"
    + give_503.format(reason=REASON)
    + "      ?:  ?=(%.n -.res)\n"
    "        :_  this(http-pending (~(del by http-pending) wire), fill-body-pending (~(del by fill-body-pending) wire))\n"
    "        (http-give u.eyre-id 422 ['content-type' 'text/plain']~ `(text-octs '%database-refused: consumable'))\n"
)
n_clk = text.count(clk)
text = text.replace(clk, clk_new)

open(PATH, "w").write(text)
print(f"standard={n_std} fill-lookup={n_fill} consumable-lookup={n_clk}")
if n_fill != 1 or n_clk != 1:
    sys.exit("special-case shape not found exactly once")
