"
Binary read-stream adapter over a SharedQueue of bytes. `next` blocks until a
byte is available; a queued nil signals end of stream (answers nil), matching
what EcaJsonRpcFramer expects from a real pipe.
"
Class {
	#name : 'EcaFakeServerReadStream',
	#superclass : 'Object',
	#instVars : [
		'queue',
		'atEnd'
	],
	#category : 'ECA-Tests-Fakes',
	#package : 'ECA-Tests',
	#tag : 'Fakes'
}

{ #category : 'instance creation' }
EcaFakeServerReadStream class >> onQueue: aSharedQueue [
	^ self new
		setQueue: aSharedQueue;
		yourself
]

{ #category : 'initialization' }
EcaFakeServerReadStream >> setQueue: aSharedQueue [
	queue := aSharedQueue.
	atEnd := false
]

{ #category : 'reading' }
EcaFakeServerReadStream >> next [
	| byte |
	atEnd ifTrue: [ ^ nil ].
	byte := queue next.
	byte ifNil: [ atEnd := true ].
	^ byte
]

{ #category : 'reading' }
EcaFakeServerReadStream >> next: aCount [
	^ ByteArray new: aCount streamContents: [ :s |
		aCount timesRepeat: [
			self next
				ifNil: [ ^ s contents ]
				ifNotNil: [ :byte | s nextPut: byte ] ] ]
]
