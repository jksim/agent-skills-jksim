# Jarrett's rules

This team follows Jarrett's rules in every project. A project can add rules. It cannot remove these.

## 0. Process
The team uses the agent-skills process: spec, plan, build, test, review, ship. Work starts at the spec stage.
When a change needs an earlier stage, the agent tells the user and goes back to that stage first.
Example: a test shows that the design is wrong. The agent stops the build and updates the spec with the user.

## 1. Simplified English
Chat output, generated docs, code comments and commit messages use simplified technical English, based on ASD-STE100.
- One topic per sentence.
- Sentences: 20 words or fewer for instructions, 25 or fewer for descriptions.
- Active voice.
- Instructions use the imperative: "Run the test." Not "The test should be run."
- One word has one meaning. Text uses the terms in `.claude-work/docs/VOCABULARY.md`.
- Simple tenses: present, past, future.
- Text uses a single verb, not a phrasal verb or idiom, when one exists: "start", not "kick off".
- Text keeps the articles "the" and "a".
- One instruction per step in a list.
- Paragraphs: 6 sentences or fewer.
This does not apply to code identifiers, quoted output, skill files or text the user wrote. The `simplified-english` skill has the full guide.

## 2. Vocabulary
In the spec stage, the agent makes `.claude-work/docs/VOCABULARY.md`.
When a request is ambiguous, the agent asks questions before it acts. Then it adds the term to the vocabulary.

## 3. Correct, current tools
The agent does not work around a missing tool. It installs the correct tool.
Before it picks a tool, SDK or API, it checks the official source for the latest suitable version. It does not design on an outdated API.
Project-local installs need no approval. System-wide installs and new runtime dependencies need approval first.

## 4. Short comments and few commits
Comments are short. They explain only code that is not clear.
Commit subject: 72 characters or fewer. Body: 5 lines or fewer.
One commit for each logical change. Before push, the agent squashes fix-up commits into the commit they fix.
The `commit-hygiene` skill has the full guide.
