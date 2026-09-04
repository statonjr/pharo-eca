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
		'stderrLog'
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
	self startStderrTail
]

{ #category : 'lifecycle' }
EcaSubprocessTransport >> startStderrTail [
	stderrTailProcess := [
		[ self isRunning ] whileTrue: [
			process stderrStream upToEnd ifNotEmpty: [ :chunk |
				self stderrLog nextPutAll: chunk ].
			(Delay forMilliseconds: 200) wait ] ]
			forkAt: Processor systemBackgroundPriority
			named: 'eca stderr tail'
]

{ #category : 'lifecycle' }
EcaSubprocessTransport >> stop [
	stderrTailProcess ifNotNil: [ :p | p terminate ].
	process ifNotNil: [ :p | [ p terminate ] on: Error do: [ :e | ] ].
	process := nil
]

{ #category : 'testing' }
EcaSubprocessTransport >> isRunning [
	^ process notNil and: [ process isRunning ]
]

{ #category : 'accessing' }
EcaSubprocessTransport >> binaryReadStream [
	^ process stdoutStream
]

{ #category : 'accessing' }
EcaSubprocessTransport >> binaryWriteStream [
	^ process stdinStream
]
