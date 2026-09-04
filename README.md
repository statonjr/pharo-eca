# pharo-eca

A Pharo Smalltalk client for [ECA (Editor Code Assistant)](https://eca.dev) — AI pair
programming in your Pharo image via the ECA JSON-RPC protocol.

## Prerequisites

- Pharo 14 (64-bit)
- The `eca` server binary. With [Homebrew](https://brew.sh), install it from the
  bundled [Brewfile](Brewfile):

  ```sh
  brew bundle --file Brewfile
  ```

  This taps `editor-code-assistant/brew` and installs the native `eca` binary.
  Alternatively, install manually (see the [ECA install docs](https://eca.dev/install/))
  and either put `eca` on your `$PATH` or set its location in the Settings Browser
  under *ECA > Server path*.

## Install

From a GitHub clone:

```smalltalk
Metacello new
	baseline: 'ECA';
	repository: 'github://statonjr/pharo-eca:main/src';
	load.
```

Or from this local checkout:

```smalltalk
Metacello new
	baseline: 'ECA';
	repository: 'gitlocal:///Users/statonjr/code/personal/pharo-eca/src';
	load.
```

## Usage

```smalltalk
EcaClient default start.        "spawn eca server + initialize handshake"
EcaChatPresenter open.          "open the chat window (World menu > ECA Chat)"
```

Type your prompt and press Send. Use `@` to attach context and `/` for commands.
Tool calls that modify files ask for approval; edits to Tonel `.st` files offer an
Iceberg reload so the image stays in sync.

## Architecture

| Package | Responsibility |
| --- | --- |
| `ECA-Core` | Transport (OSSubprocess), LSP-style `Content-Length` JSON-RPC framing, client lifecycle, session model |
| `ECA-Spec` | Spec2 chat UI, tool-call approval, MCP server list, Calypso integration |
| `ECA-Tests` | Unit tests with a scripted fake server; opt-in integration test |

## Protocol coverage

Implements the [ECA protocol](https://eca.dev/protocol/): `initialize`/`initialized`,
`shutdown`/`exit`, `chat/prompt`, `chat/queryContext`, `chat/queryCommands`,
`chat/toolCallApprove`, `chat/toolCallReject`, `chat/promptStop`, and handles
`chat/contentReceived`, `chat/cleared`, `config/updated`, `tool/serverUpdated`,
`$/showMessage` notifications.
