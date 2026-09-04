"
Spawns `eca server` as a child process with piped stdin/stdout/stderr using
OSSubprocess. stderr is tailed into an in-image log for debugging (the ECA
server logs to stderr).
"
Class {
	#name : 'EcaSubprocessTransport',
	#superclass : 'Object',
	#traits : 'TEcaTransport',
	#classTraits : 'TEcaTransport classTrait',
	#instVars : [
		'command',
		'process',
		'stderrTailProcess',
		'stderrLog',
		'readAdapter'
	],
	#category : 'ECA-Core-Transport',
	#package : 'ECA-Core',
	#tag : 'Transport'
}

{ #category : 'instance creation' }
EcaSubprocessTransport class >> command: anArrayOfStrings [
	^ self new
		command: anArrayOfStrings;
		yourself
]

{ #category : 'accessing' }
EcaSubprocessTransport >> command: anArrayOfStrings [
	command := anArrayOfStrings
]

{ #category : 'accessing' }
EcaSubprocessTransport >> stderrLog [
	^ stderrLog ifNil: [ stderrLog := WriteStream on: String new ]
]

{ #category : 'lifecycle' }
EcaSubprocessTransport >> start [
	process := OSSUnixSubprocess new
		command: command first;
		arguments: command allButFirst asArray;
		redirectStdin;
		redirectStdout;
		redirectStderr;
		run.
	[ process stdinStream binary.
	  process stdoutStream binary ]
		on: Error
		do: [ :e | "streams stay in their default mode" ].
	readAdapter := EcaPollingReadStream on: process stdoutStream transport: self.
	self startStderrTail
]

{ #category : 'lifecycle' }
EcaSubprocessTransport >> startStderrTail [
	stderrTailProcess := [
		[ self isRunning ] whileTrue: [
			| chunk |
			chunk := [ process stderrStream upToEnd ] on: Error do: [ :e | '' ].
			chunk isEmptyOrNil ifFalse: [
				self stderrLog nextPutAll: (chunk isString
					ifTrue: [ chunk ]
					ifFalse: [ chunk utf8Decoded ]) ].
			(Delay forMilliseconds: 200) wait ] ]
			forkAt: Processor systemBackgroundPriority
			named: 'eca stderr tail'
]

{ #category : 'lifecycle' }
EcaSubprocessTransport >> stop [
	stderrTailProcess ifNotNil: [ :p | p terminate ].
	process ifNotNil: [ :p | [ p terminate ] on: Error do: [ :e | ] ].
	process := nil.
	readAdapter := nil
]

{ #category : 'testing' }
EcaSubprocessTransport >> isRunning [
	^ process notNil and: [ process isRunning ]
]

{ #category : 'accessing' }
EcaSubprocessTransport >> binaryReadStream [
	^ readAdapter
]

{ #category : 'accessing' }
EcaSubprocessTransport >> binaryWriteStream [
	^ process stdinStream
]
