---
name: simplified-english
description: Writes and edits text in simplified technical English, based on ASD-STE100. Use when writing docs, specs, plans, READMEs, comments or commit messages, or when the user asks for plain technical text.
---

# Simplified English

## Overview

Rule 1 of Jarrett's rules: chat output, generated docs, code comments and commit messages use simplified technical English. The style is based on the principles of ASD-STE100. Readers find facts faster. Readers whose first language is not English understand more.

This skill is our own summary. It is not the ASD-STE100 standard and does not include its dictionary.

## When to Use

- You write or edit a spec, plan, ADR, README, vocabulary entry or other doc.
- You write a code comment or a commit message.
- You review text for rule 1.

Do not apply it to code identifiers, quoted output (errors, logs, command output), skill files or text the user wrote.

## Process

Write the text. Then check it against each rule.

| # | Rule | Not this | This |
|---|---|---|---|
| 1 | One topic per sentence. | The hook reads the file and, if it is missing, it prints a warning, which the user sees. | The hook reads the file. If the file is missing, the hook prints a warning. The user sees the warning. |
| 2 | Instructions: 20 words or fewer. Descriptions: 25 words or fewer. | Make sure that before you go ahead and push the branch you have run the full test suite and checked the output. | Run `./scripts/test.sh`. Then push the branch. |
| 3 | Use the active voice. | The rules are loaded by the hook. | The hook loads the rules. |
| 4 | Instructions use the imperative. | The test should be run before the commit. | Run the test before the commit. |
| 5 | One word has one meaning. Use the terms in `.claude-work/docs/VOCABULARY.md`. | Warn, then later "flag", "alert" or "notify" for the same action. | Warn, every time. |
| 6 | Use simple tenses: present, past, future. | The hook would have been checking the input. | The hook checks the input. |
| 7 | Use a single verb, not a phrasal verb or idiom. | Kick off the build. Figure out the cause. | Start the build. Find the cause. |
| 8 | Keep "the" and "a". | Run script, check output. | Run the script. Check the output. |
| 9 | One instruction per step. | 1. Open the file and change the version. | 1. Open the file. 2. Change the version. |
| 10 | Paragraphs: 6 sentences or fewer. | A block of ten sentences. | Two short paragraphs, or a list. |

More rules:
- Write a warning or caution before the step it applies to. Start with the danger: "Warning: this deletes the branch."
- Use numbers, not words, for values: "72 characters", not "seventy-two characters".
- Use a list or a table when you give three or more items.
- Do not use synonyms to vary the text. Repeat the same term.
- Do not use "it" or "this" when the noun is not clear. Name the noun again.
- When a term is not in the vocabulary and the meaning is not clear, ask the user. Then add the term to the vocabulary.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "Short sentences sound robotic." | Short sentences are fast to read and hard to misread. The reader's speed matters more than style. |
| "A synonym makes the text less repetitive." | A synonym makes the reader ask if it is a different thing. |
| "This comment is too small for the rules." | Comments and commit messages are in scope. Small text is easy to fix. |
| "The passive voice is more formal." | The passive voice hides who does the action. Name the actor. |

## Red Flags

- Sentences with "and", "which" or "so that" that join two topics.
- "Should", "could" or "might" in an instruction.
- The same thing has two names in one doc.
- A step with two actions.
- A warning after the step it applies to.

## Verification

- [ ] Each sentence has one topic.
- [ ] No instruction is longer than 20 words. No description is longer than 25 words.
- [ ] All instructions use the imperative and the active voice.
- [ ] All terms match the vocabulary.
- [ ] Each list step has one instruction.
- [ ] No paragraph is longer than 6 sentences.
