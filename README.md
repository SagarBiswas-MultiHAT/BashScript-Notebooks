# BashScript-Notbook

<div align="right">

[![CI](https://github.com/SagarBiswas-MultiHAT/BashScript-Notebooks/actions/workflows/ci.yml/badge.svg)](https://github.com/SagarBiswas-MultiHAT/BashScript-Notebooks/actions)
&nbsp;
[![Release](https://img.shields.io/github/v/release/SagarBiswas-MultiHAT/BashScript-Notebooks)](https://github.com/SagarBiswas-MultiHAT/BashScript-Notebooks/releases)
&nbsp;
[![License](https://img.shields.io/github/license/SagarBiswas-MultiHAT/BashScript-Notebooks)](LICENSE)
&nbsp;
[![last commit](https://img.shields.io/github/last-commit/SagarBiswas-MultiHAT/BashScript-Notebooks)](https://github.com/SagarBiswas-MultiHAT/BashScript-Notebooks/commits/main)
&nbsp;
[![issues](https://img.shields.io/github/issues/SagarBiswas-MultiHAT/BashScript-Notebooks)](https://github.com/SagarBiswas-MultiHAT/BashScript-Notebooks/issues)

</div>

Caption: I made this notebook while learning bash step-by-step — it helped me go from "echo Hello" to useful scripts for daily tasks. It's written like a student's notes, so it's friendly and practical.

Overview
--------
This repository contains a notebook (BashScript-Notebook) that teaches Bash scripting from basics to practical projects. This `README.md` summarizes every topic and subtopic from that notebook so you can learn the material by reading this file alone.

Who this is for
- Beginners who want a clear path into Bash scripting
- Intermediate users who want a concise reference of common patterns
- Students preparing small automation projects or system scripts

How to use this repo
- Read this `README.md` to understand concepts and examples.
- Open the attached notebook `BashScript-Notebook.pdf` for step-by-step cells and extra exercises.
- To run the examples on your machine, open a terminal on a Linux/macOS system and run the sample commands or copy code into a `.sh` file and run `bash myscript.sh`.

Prerequisites
- A Unix-like system (Linux or macOS) with `bash` installed.
- Basic familiarity with the terminal: opening a shell, navigating directories, and editing files with a text editor.

Table of contents
- Part 1 — Introduction & Hello World
- Part 2 — Comments
- Part 3 — Quoting and Here-docs
- Part 4 — Variables (local & env)
- Part 5 — System-defined variables
- Part 6 — Arrays
- Part 7 — Operators
- Part 8 — Conditional statements (if/elif/else)
- Part 9 — While loops
- Part 10 — Until loops
- Part 11 — For loops
- Part 12 — Command line arguments
- Part 13 — Functions
- Part 14 — File operations & reading lines
- Part 15 — Command history and shortcuts
- Part 16 — Redirection, grep, awk
- Part 17 — Error handling and traps
- Part 18 — Debugging techniques
- Part 19 — Security best practices
- Part 20 — Interactive exercises
- Part 21 — Reference & Projects

Detailed topics and examples
----------------------------

Part 1 — Introduction & Hello World
- Purpose: show how to make a script executable and run it.
- Key ideas: shebang, permissions, echo, comments.
- Example:
	- Script content:
		echo "#!/bin/bash"  # first line indicates bash interpreter
		echo "echo Hello, world!"
	- Make executable and run:
		chmod +x hello.sh
		./hello.sh

Part 2 — Comments
- Single-line comments start with `#`.
- Multi-line comments: no native block comment; use `: <<'COMMENT'` heredoc or surrounding techniques.
- Best practices: add header describing purpose, parameters, and expected output.

Part 3 — Quoting and Here-documents
- Single quotes `'...'` prevent variable expansion and interpretation.
- Double quotes `"..."` allow variable expansion and command substitution.
- Unquoted words can split and glob unexpectedly — prefer quotes for paths and user input.
- Here-doc example:
	cat <<'EOF' > sample.txt
	This is a multi-line
	literal where $VAR is not expanded.
	EOF

Part 4 — Variables (local & env)
- Assign: `name=value` (no spaces). Read: `$name` or ${name}.
- Export environment variables: `export VAR=value`.
- Unset: `unset VAR`.
- Example:
	count=5
	echo "Count is $count"

Part 5 — System-defined variables
- Common ones: `$HOME`, `$PWD`, `$USER`, `$SHELL`, `$BASH_VERSION`, `$UID`, `$OSTYPE`.
- Use them to write portable scripts that adapt to user environment.

Part 6 — Arrays
- Declare: `arr=(one two three)`; access `${arr[0]}`; length `${#arr[@]}`; iterate `for v in "${arr[@]}"`.
- Associative arrays (bash 4+): `declare -A map; map[key]=value`.

Part 7 — Operators
- Arithmetic: `(( a + b ))`, `let`, or use `$(( ))` for expansion.
- Comparison (integers): `-eq`, `-ne`, `-lt`, `-le`, `-gt`, `-ge`.
- String: `=` and `!=`, tests like `-z` (empty) and `-n` (non-empty).
- File tests: `-f` (regular file), `-d` (directory), `-x` (executable), `-r` (readable).

Part 8 — Conditional statements (if/elif/else)
- Structure:
	if [ condition ]; then
		commands
	elif [ other ]; then
		commands
	else
		commands
	fi
- Use `[[ ... ]]` for more powerful pattern matching and safer syntax.

Part 9 — While loops
- Repeat while condition true:
	while [ condition ]; do
		commands
	done
- Example: read file lines:
	while IFS= read -r line; do
		echo "$line"
	done < file.txt

Part 10 — Until loops
- Opposite of while: runs until condition becomes true.
	until [ condition ]; do
		commands
	done

Part 11 — For loops
- Loop over words, files, or sequences:
	for i in 1 2 3; do echo $i; done
	for f in *.txt; do echo $f; done
- C-style loop (bash): `for ((i=0;i<10;i++)); do ...; done`.

Part 12 — Command line arguments
- `$0` script name, `$1` first arg, `$#` number of args, `$@` and `$*` for all arguments.
- Example: parse arguments with a loop:
	while [[ $# -gt 0 ]]; do
		case "$1" in
			-f|--file) file="$2"; shift 2;;
			--) shift; break;;
			*) echo "Unknown $1"; shift;;
		esac
	done

Part 13 — Functions
- Define: `myfun() { commands; }`.
- Return status with `return` and output with `echo`.
- Use `local` inside functions to avoid global variable pollution.

Part 14 — File operations & reading lines
- Read a file safely: `while IFS= read -r line; do ...; done < file`.
- Append `>>` or overwrite `>`; use `>> logfile 2>&1` to capture errors.

Part 15 — Command history and shortcuts
- History shortcuts: `!!` repeats last command, `!$` last argument, `!n` nth command.
- Use `history` to inspect past commands.

Part 16 — Redirection, grep, awk
- Redirection:
	- `>` overwrite stdout, `>>` append stdout.
	- `2>` redirect stderr, `&>` or `>file 2>&1` combine stdout+stderr.
- `grep` basics: `grep -i` ignore case, `-v` invert match, `-r` recursive, `-E` extended regex.
- `awk` basics: field-based processing `awk '{print $1}' file` and more advanced data extraction.

Part 17 — Error handling and traps
- `set -e` exit on error, `set -u` treat unset variables as errors, `set -o pipefail` catch pipeline failures.
- `trap 'cleanup' EXIT` to run cleanup on exit; trap specific signals like SIGINT.

Part 18 — Debugging techniques
- `bash -n script.sh` checks syntax.
- `set -x` and `set +x` enable/disable execution tracing; `bash -x script.sh` runs with trace.
- Add `echo` statements to inspect variables at runtime.

Part 19 — Security best practices
- Validate and sanitize all user input before using in commands.
- Avoid `eval` and unquoted expansions when input is untrusted.
- Use absolute paths and drop privileges where possible.

Part 20 — Interactive exercises
- Examples in the notebook include:
	- Reverse a string using `rev` or parameter expansion.
	- Convert input to uppercase: `tr '[:lower:]' '[:upper:]'`.
	- Generate multiplication table using loops.
	- Practice parsing CSVs with `cut`, `awk`.

Part 21 — Reference & Projects
- Reference: quick cheatsheet for commands, operators, and common patterns.
- Projects included in the notebook (with short descriptions and usage):
	- Check if a file exists: script takes a path and prints status.
	- Count files in a directory: uses `find` or `ls` + `wc -l`.
	- Get machine IP: parse `ip addr` or `hostname -I`.
	- Ping host accessibility and report latency.
	- Detect disk usage: `df -h` + threshold alerts.
	- Get RAM & CPU info: `free -h`, `/proc/cpuinfo`, `top`/`ps` snapshots.
	- Delete files older than N days: `find /path -type f -mtime +7 -delete` (BE CAREFUL).
	- Report total file count in a tree for a directory.

Running notebook examples locally
- If you have Jupyter with a bash kernel (e.g., `bash_kernel`), you can open the notebook and run cells interactively.
- Otherwise, copy code blocks into `.sh` files and run with `bash`.

Tips and common gotchas
- Always quote variables when used in strings or file paths: `"$var"`.
- Prefer `[[ ... ]]` for conditional expressions when scripting in bash.
- Use `set -euo pipefail` at the top of production scripts to fail fast.
- Test destructive commands (like `rm`) on safe directories first.

Further reading
- GNU Bash Reference Manual: https://www.gnu.org/software/bash/manual/
- Advanced Bash-Scripting Guide: https://tldp.org/LDP/abs/html/

Contributing
- If you find typos or want to add examples, open a PR with small, focused changes.

License
- This repository is educational; include your preferred license file if you want to publish (e.g., MIT).

Contact / Feedback
- I wrote this as a student-friendly summary. If something is unclear or you want more examples, open an issue or a PR.

Enjoy scripting! 👩‍💻👨‍💻