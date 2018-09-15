
# yunoqa

yunoqa is a tool that aggregates sets of TAP test results and presents them as (x)HTML pages.
It is meant to be the cornerstone of a future QA and CI system for YunoRock.

## Installation

This software depends on:

- Moonscript
- the Lapis web framework (for the HTML DSL only, this might be replaced in the future)
- lua-toml (to read its configuration file)
- lyaml (to parse YAML blocks within TAP files)

yunoqa’s Makefiles are generated using [build.zsh](https://github.com/Lukc/build.zsh).

To generate the Makefile with build.zsh, simply run `build.zsh`.
To install it, run `make install`.
Many standard installation paths can be redefined from the CLI; use `make help` for more information.

## Usage

```moon
$ cat qa.conf

General
	title: "Test QA Interface"
	resultsDirectory: "tap"

Project "foo",
	template: -> h1 "My custom template goes here!"

```

A more user-friendly (and less error-prone) CLI will be done in the near future (if all goes well).

## Bugs & Limitations

The software is at this stage very much a work in progress.
Many features are sketchy, or simply missing.
This includes:

- Templates should be redefinable (possibly per-project).
- The stylesheet and current templates are to be cleaned, a lot.
- Documentation, examples and manpages.

