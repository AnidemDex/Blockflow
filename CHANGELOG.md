All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres loosely to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!--
FYI here's a hint about versioning:

    Added for new features.
    Changed for changes in existing functionality.
    Deprecated for soon-to-be removed features.
    Removed for now removed features.
    Fixed for any bug fixes.
    Security in case of vulnerabilities.

-->

## Unreleased 
### Added
- More documentation about project structure and usage.
- A simple example. It just prints something in console.
- **Multiple selection of commands**. This is part of our new UI.
- `Command` properties:
  - `block_name` as `command_name` alias to change the display name in editor.
  - `block_color` to tint the block representation in editor.
  - `block_icon` to define the texture used in the block representation in editor.
### Changed
- `Set` command behavior. Now includes more operations and hints to be done in the command - [#153](https://github.com/AnidemDex/Blockflow/pull/153).
- **Editor UI**. We now have a new custom displayer.
- `Command.background_color` to `Command.block_color`.
- `Command.command_hint_icon` to `Command.block_icon`
### Deprecated
- `Set.PlusOperables` constant. Now `Operables` is used instead.
- `Command.Group`. Unused constant.
- `Command.background_color`.
- `Command.command_hint_icon`.
- `Command.command_text_color`.
- `Command.defines_default_branches`.
- `Command.can_be_moved`.
- `Command.go_to_branch()`.
- `Command._get_hint_icon()`.
- `Command._can_be_selected()`.
- `Command._defines_default_branches()`.
- `Command._get_default_branch_for()`.
### Removed
- Old `Timeline` references. You _really_ should not be using those, they were not meant to exist in 1.0 but it was keep to preserve an older project stability.
## \[[1.1](https://github.com/AnidemDex/Blockflow/releases/tag/1.1)] 2024-06-02
### Added
- Copy and paste command functionality - [#105](https://github.com/AnidemDex/Blockflow/pull/105).
- Blockflow custom icon - [#109](https://github.com/AnidemDex/Blockflow/pull/109).
- `Command` categories - [#117](https://github.com/AnidemDex/Blockflow/pull/117).
- Editor layout, to save editor status between sessions - [#128](https://github.com/AnidemDex/Blockflow/pull/128).
- Shortcuts to right-click menu actions - [#132](https://github.com/AnidemDex/Blockflow/pull/132).
- Code of conduct - [#136](https://github.com/AnidemDex/Blockflow/pull/136).
- Contribution guideline - [#137](https://github.com/AnidemDex/Blockflow/pull/137).
- `CommandRecord` class to manage registered commands in editor - [#144](https://github.com/AnidemDex/Blockflow/pull/144).
### Changed
- `Print` command now has fancy colors and a different icon - [#103](https://github.com/AnidemDex/Blockflow/pull/103).
- CommandList and Editor recent files layout - [#110](https://github.com/AnidemDex/Blockflow/pull/110) [#124](https://github.com/AnidemDex/Blockflow/pull/124).
- `CommandProcessor` history behavior when calling `jump_to_command` - [#116](https://github.com/AnidemDex/Blockflow/pull/116).
- Show the resource oath instead of the resource object ID in the command displayer - [#122](https://github.com/AnidemDex/Blockflow/pull/122).
### Fixed
- Plugin error caused by static typing - [#111](https://github.com/AnidemDex/Blockflow/pull/111).
- `Collection` error that caused subresources being broken due duplication - [#112](https://github.com/AnidemDex/Blockflow/pull/112).
- 
## \[[1.0.1](https://github.com/AnidemDex/Blockflow/releases/tag/1.0.1)] 2023-11-25

### Fixed
- Fix `Return` command, where wrong index were used - [#101](https://github.com/AnidemDex/Blockflow/pull/101)

## \[[1.0](https://github.com/AnidemDex/Blockflow/releases/tag/1.0)] 2023-11-21
### Added
- Blockflow core.
- Collection, Command and CommandCollection classes.
- CommandProcessor node.
- Blockflow editor.
- Basic commands.