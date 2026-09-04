"
Guards EcaPeerServer's /eval op, following ChatPharoSandbox's pattern:

1. Denylist: source containing any denied substring is rejected before
   compilation (process spawning, FFI, identity swaps, image control, and
   the peer/server machinery itself).
2. Timeout: evaluation runs in a background process that is terminated if it
   exceeds the timeout. The result's printString is computed inside the
   timed process, so hostile printOn: implementations cannot escape it.

Both knobs are class-side configurable:

	EcaPeerSandbox timeoutMs: 10000.
	EcaPeerSandbox deniedPatterns: (EcaPeerSandbox deniedPatterns copyWith: 'MyClass').

The denylist is substring matching — a tripwire against accidents and lazy
misuse, not a security boundary. Approval on the driving side remains the
real gate.
"
Class {
	#name : 'EcaPeerSandbox',
	#superclass : 'Object',
	#classVars : [
		'DeniedPatterns',
		'TimeoutMs'
	],
	#category : 'ECA-Core-Peer',
	#package : 'ECA-Core',
	#tag : 'Peer'
}

{ #category : 'accessing' }
EcaPeerSandbox class >> deniedPatterns [
	^ DeniedPatterns ifNil: [ DeniedPatterns := self defaultDeniedPatterns ]
]

{ #category : 'accessing' }
EcaPeerSandbox class >> deniedPatterns: aCollection [
	DeniedPatterns := aCollection
]

{ #category : 'defaults' }
EcaPeerSandbox class >> defaultDeniedPatterns [
	^ #( 'LibC' 'OSProcess' 'OSSUnixSubprocess' 'OSPlatform'
	     'ExternalAddress' 'FFICallout' 'ffiCall'
	     'become:' 'becomeForward:'
	     'snapshot' 'quitSession' 'exitSuccess' 'exitFailure'
	     'ZnServer' 'EcaPeerServer' 'EcaPeerSandbox' )
]

{ #category : 'accessing' }
EcaPeerSandbox class >> timeoutMs [
	^ TimeoutMs ifNil: [ TimeoutMs := 5000 ]
]

{ #category : 'accessing' }
EcaPeerSandbox class >> timeoutMs: anInteger [
	TimeoutMs := anInteger
]

{ #category : 'evaluating' }
EcaPeerSandbox class >> evaluate: aString [
	"Answer an EcaPeerSandboxResult for evaluating aString."

	(self deniedPatterns
		detect: [ :pattern | aString includesSubstring: pattern ]
		ifNone: [ nil ])
		ifNotNil: [ :pattern | ^ EcaPeerSandboxResult denied: pattern ].
	^ self evaluateWithTimeout: aString
]

{ #category : 'private' }
EcaPeerSandbox class >> evaluateWithTimeout: aString [
	| semaphore result process |
	semaphore := Semaphore new.
	process := [
		[ result := EcaPeerSandboxResult ok:
			(Smalltalk compiler evaluate: aString) printString ]
			on: Error
			do: [ :e |
				result := EcaPeerSandboxResult error:
					e class name , ': ' , e messageText ].
		semaphore signal ] newProcess.
	process priority: Processor userBackgroundPriority.
	process resume.
	(semaphore waitTimeoutMilliseconds: self timeoutMs) ifTrue: [
		process terminate.
		^ EcaPeerSandboxResult timeout: self timeoutMs ].
	^ result
]
