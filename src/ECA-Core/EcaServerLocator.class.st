"
Resolves the eca server executable, in order:
1. EcaSettings serverPath (Settings Browser)
2. `eca` on $PATH
3. Well-known install locations (~/.local/bin, Homebrew prefixes)
Signals EcaError with install instructions when nothing is found.
"
Class {
	#name : 'EcaServerLocator',
	#superclass : 'Object',
	#category : 'ECA-Core-Client',
	#package : 'ECA-Core',
	#tag : 'Client'
}

{ #category : 'resolving' }
EcaServerLocator >> resolve [
	EcaSettings serverPath ifNotEmpty: [ :path |
		path asFileReference exists ifTrue: [ ^ path ] ].
	self pathCandidates do: [ :candidate |
		candidate exists ifTrue: [ ^ candidate fullName ] ].
	^ EcaError signal:
		'eca server binary not found. Install with `brew bundle --file Brewfile` or set the path in Settings > ECA.'
]

{ #category : 'private' }
EcaServerLocator >> pathCandidates [
	| fromPath |
	fromPath := ((OSEnvironment current at: 'PATH' ifAbsent: [ '' ])
		substrings: ':')
		collect: [ :dir | dir asFileReference / 'eca' ].
	^ fromPath , {
		FileLocator home / '.local' / 'bin' / 'eca'.
		'/opt/homebrew/bin/eca' asFileReference.
		'/usr/local/bin/eca' asFileReference }
]
