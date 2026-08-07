---
name: ste-writing
description: Rewrite prose (commit messages, docs, READMEs, PR descriptions, error messages, release notes, comments — never code) into ASD-STE100 Simplified Technical English to remove "AI slop". ALWAYS load before writing a commit message or a README. Use when asked to make writing not sound like AI, make docs clear or plain, enforce a controlled writing style, or write technical documentation that reads human. Two modes — strict (procedures/safety) and STE-flavored (general prose).
---

# ste-writing

Write prose in ASD-STE100 Simplified Technical English. This applies to commit messages, documentation, READMEs, pull-request text, error messages, release notes, and comments. It does not apply to code, identifiers, or command syntax. It is not for marketing copy, essays, or anything that needs a voice — STE strips voice on purpose.

## Standing rule (user, 2026-08-04)

Apply this skill to EVERY commit message and EVERY README, in every repository, without being asked. The rule matters most for code repositories, where the commit log is the durable record of why a change happened.

Apply it going forward only. Do NOT rewrite existing commit messages or published READMEs to conform — rewriting history to fix prose is a worse defect than the prose.

## Rules

WORDS
- Use one name for one thing. Do not call the same item by two different names.
- Use the short common word: start (not begin/commence/initiate), use (not utilize/leverage), help (not facilitate), make sure (not ensure), before (not prior to), after (not subsequent to), about (not regarding/concerning), get (not obtain/acquire), show (not demonstrate), also (not additionally/furthermore/moreover).
- Give each word one meaning. "fall" means to move down, not to decrease.
- No marketing adjectives: seamless, robust, powerful, cutting-edge, effortless, world-class, next-generation, revolutionary.
- American spelling.

VERBS
- Active voice. "the parser reads the file", not "the file is read by the parser".
- Use a verb for an action. "analyze the log", not "perform an analysis of the log".
- No stacked auxiliaries. Not "it is important to note that this may help to improve". Write "this improves X".
- No "-ing" main verb where a simple tense works.

SENTENCES
- One instruction per sentence. Max 20 words (instruction), max 25 (descriptive).
- No contractions. Use articles: a, an, the, this, these.

PUNCTUATION
- No semicolons. Write two sentences. (Note: the em dash is not banned by STE, only the semicolon is — add "no em dash" yourself if you want it gone.)

STRUCTURE
- One topic per paragraph, max six sentences. For steps, use a numbered vertical list, one action per item, imperative form. Put a condition before its command.

Write only the requested text. No preamble, no summary, no closing remarks.

## Modes

- **strict** — procedures, runbooks, safety text, error messages: apply every rule and both length caps.
- **STE-flavored** — general prose (READMEs, PR descriptions, docs): apply the sentence, paragraph, active-voice, and no-phrasal-verb discipline; relax the ~900-word dictionary lockdown so the text keeps enough range to read naturally.
- **commit** — commit messages: strict rules, plus the shape below.

## Commit messages

Use STE-flavored rules, with these additions:

1. **Clarity beats brevity. There is no character cap on the subject line** (user, 2026-08-04). A descriptive subject is a good thing. The house style runs long on purpose: the erpit log has a median subject of 84 characters and 98% of subjects exceed 50. Write the subject that identifies the change, then stop — do not pad it, and do not truncate a clear one to hit a number.
2. Front-load the identifying part. The reader scans a column of subjects, so put the prefix, scope, and the changed thing first. Detail and parentheticals go at the end where truncation costs nothing.
3. Keep the repository's own subject prefix. ERPit uses `m<N>: <what>` (see its CLAUDE.md); the log also uses `m14f p45b-opus:`, `v2: task 4`, `rover:`, `docs:`. Match the neighbors.
4. Write the subject in the imperative or as a plain noun phrase naming the change. Never end it with a period.
5. Leave one blank line, then the body. Wrap the body at 72 characters.
6. State what changed and why. The diff already shows how.
7. Name a file, symbol, ruling, or task the reader can find. Vague subjects ("fix stuff", "update docs") make the log useless. This is the real target — vagueness is the defect, length is not.
8. Add no trailer that certifies anything. A `Signed-off-by:` line is a DCO certification made by a person. Never write one on the user's behalf.
9. A close-out commit after a branch competition or A/B merge must state the DECISION in the subject or body: which branch won, what it delivered, and why it was picked. An ff-only merge leaves no merge commit, so the close-out commit is the only place the log records the decision — naming only the artifacts ("record the findings") fails the reader (user correction, 2026-08-06, erpit m16 t2a `a80a5f4`).

Do not describe your own process ("I then verified..."). The commit records the change, not the session.

STE discipline still applies inside the sentence: active voice, plain verbs, no marketing adjectives, no semicolons. Those rules make a long subject readable. They do not make it short.

## Self-lint (run before returning text)

1. Any sentence over 20 words? Split it.
2. Any semicolon? Replace with a period.
3. Any contraction? Expand it.
4. Any passive voice with a known actor? Make it active.
5. Any "-ing" main verb, nominalization ("perform an analysis"), or phrasal verb ("spin up")? Replace with a plain verb.
6. Same thing named two ways? Pick one name.

The mechanical rules above are lintable and are what removes slop. Full STE also needs human judgment (the right technical noun, whether a sentence "makes good sense") — a checker cannot certify that, and slop is not about that. This skill fixes the FORM of slop. It cannot make a hollow paragraph true.

Free official standard (do not paste it in full; it is copyrighted): https://asd-ste100.org
