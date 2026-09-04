"
Blocking read facade over OSSubprocess's non-blocking pipe streams.
A raw pipe answers nil from #next when no data has arrived yet; this adapter
polls until data is available, the transport stops, or the child process dies.
Answers nil only at true end of stream. Normalizes Characters to byte values
in case the underlying pipe is in text mode.
"
Class {
	#name : 'EcaPollingReadStream',
	#superclass : 'Object',
	#instVars : [
		'stream',
		'transport',
		'pollDelayMs'
	],
	#category : 'ECA-Core-Transport',
	#package : 'ECA-Core',
	#tag : 'Transport'
}

{ #category : 'instance creation' }
EcaPollingReadStream class >> on: aRawStream transport: aTransport [
	^ self new
		setStream: aRawStream transport: aTransport;
		yourself
]

{ #category : 'initialization' }
EcaPollingReadStream >> setStream: aRawStream transport: aTransport [
	stream := aRawStream.
	transport := aTransport.
	pollDelayMs := 10
]

{ #category : 'reading' }
EcaPollingReadStream >> next [
	"Block until one byte is available. Answer nil only at end of stream."

	[ true ] whileTrue: [
		| element |
		element := [ stream next ] on: Error do: [ :e | nil ].
		element ifNotNil: [
			^ element isCharacter
				ifTrue: [ element asInteger ]
				ifFalse: [ element ] ].
		transport isRunning ifFalse: [
			"Drain any bytes buffered after process exit."
			element := [ stream next ] on: Error do: [ :e | nil ].
			^ element ifNotNil: [
				element isCharacter
					ifTrue: [ element asInteger ]
					ifFalse: [ element ] ] ].
		(Delay forMilliseconds: pollDelayMs) wait ]
]

{ #category : 'reading' }
EcaPollingReadStream >> next: aCount [
	"Block until aCount bytes are read or the stream ends."

	^ ByteArray streamContents: [ :out |
		aCount timesRepeat: [
			self next
				ifNil: [ ^ out contents ]
				ifNotNil: [ :byte | out nextPut: byte ] ] ]
]
