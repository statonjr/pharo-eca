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

Type your prompt and press Enter (or Send). Features:

- **Streaming chat** with Microdown-rendered markdown and reasoning indicators
- **`@` context completion** — pause after `@token` for a chooser backed by
  `chat/queryContext`; chosen contexts ride along with your next prompt
- **`/` command completion** — `/login`, `/config`, `/doctor`, `/resume`, …
- **Tool-call approval** — dialogs for gated tools (shell, file edits), with
  status lines (`-> tool (awaiting approval)`, `ok tool`, `rejected tool`)
- **Session tokens/cost** in the window title
- **Calypso integration** — right-click a class → *Ask ECA about this class*
- Model selector fed live from `config/updated`; Stop button for running prompts

## Image-to-image communication

`EcaPeerServer` is a deliberately tiny, nREPL-flavored HTTP endpoint (Zinc,
loopback-only) that lets one image be driven by another image's ECA agent —
no MCP required, the "protocol" fits in a sentence of prompt.

In the image to be driven (Image B):

```smalltalk
EcaPeerServer startOn: 8086.    "EcaPeerServer stop. to shut down"
```

Ops: `GET /describe` (JSON: image info + ops), `GET /classes?q=Substring`
(matching class names), `POST /eval` (raw Smalltalk source → `printString`).

Then, in the driving image's ECA chat, a prompt like:

> There's another Pharo image listening on localhost:8086. GET /describe
> returns JSON about it, GET /classes?q=Substring searches its class names,
> and POST /eval with Smalltalk source in the body (use `--data-binary` and
> `Content-Type: text/plain`) evaluates it and returns the result. Find out
> which image it is, then evaluate `Smalltalk globals allClasses size` in it.

The agent drives Image B through approved `shell_command`/curl tool calls.
Every evaluation passes through the driving side's ECA approval gate; the
endpoint binds to loopback only and must be started explicitly. `/eval`
executes arbitrary code by design — keep it to experiments, or sandbox it
before anything more.

### Custom tools (recommended)

[`.eca/config.json`](.eca/config.json) in this repo defines `pharo-peer-eval`
and `pharo-peer-classes` as [ECA custom tools](https://eca.dev/config/tools/),
so the LLM gets typed, named tools instead of improvising curl (the source is
passed via a quoted heredoc, sidestepping shell-quoting bugs). Picked up
automatically when this repo is one of your ECA workspace folders; copy the
`customTools` stanza into `~/.config/eca/config.json` to have it everywhere.
Then the driving prompt shrinks to:

> Using pharo-peer-eval (port 8086), find out how many classes the peer
> image has loaded.

To auto-deny dangerous evaluations while auto-approving the rest, add:

```json
{
  "toolCall": {
    "approval": {
      "allow": { "pharo-peer-classes": {} },
      "deny": {
        "pharo-peer-eval": {
          "argsMatchers": { "code": [ ".*become:.*", ".*Smalltalk snapshot.*" ] }
        }
      }
    }
  }
}
```

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
