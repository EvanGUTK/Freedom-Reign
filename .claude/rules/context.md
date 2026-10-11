# Context discipline

Context is a budget. Spend it on the task, not on getting comfortable.

- Read only the files the task touches. Use Grep and Glob to find them; never open a directory wholesale or read files "to get familiar".
- Never read `node_modules`, build output, `.git`, lockfiles, binary assets, or logs. `.claude/settings.json` blocks most of these; do not route around it with shell commands.
- When you need one function, read that range of the file, not the whole file.
- Broad exploration ("where is X handled?") goes to an `Explore` subagent. Keep its conclusion, not its file dumps.
- Do not re-read a file you just edited, and do not `cat` a file to confirm an edit the tool already confirmed.
- Reports are short: what changed, where, how to verify. No logs, no file contents, no restating the task.
- Commit progress to your branch as you go. A commit survives context compaction; a plan held in your head does not.
