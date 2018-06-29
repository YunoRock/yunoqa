
# yunoqa

yunoqa is a tool that aggregates sets of TAP test results and presents them as (x)HTML pages.
It is meant to be the cornerstone of a future QA and CI system for YunoRock.

## Installation

This software depends on:

- Moonscript
- the Lapis web framework (for the HTML DSL only)
- lua-toml (to read its configuration file)

yunoqa’s Makefiles are generated using [build.zsh](https://github.com/Lukc/build.zsh).

To generate the Makefile with build.zsh, simply run `build.zsh`.
To install it, run `make install`.
Many standard installation paths can be redefined from the CLI; use `make help` for more information.

## Usage

```
$ cat qa.toml

[[project]]
name = "foo"

$ ls foo
foo#environment-name#revision-number-or-name.tap
```

A more user-friendly (and less error-prone) CLI will be done in the near future (if all goes well).

## Bugs & Limitations

The software is at this stage very much a work in progress.
Many features are sketchy, or simply missing.
This includes:

- Templates should be redefinable (possibly per-project).
- A CLI should be provided to receive TAP results through UNIX pipes.
- The stylesheet and current templates are to be cleaned, a lot.
- Documentation, examples and manpages.

