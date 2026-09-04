Class {
	#name : 'EcaJsonRpcFramerTest',
	#superclass : 'TestCase',
	#instVars : [
		'framer'
	],
	#category : 'ECA-Tests-Tests',
	#package : 'ECA-Tests',
	#tag : 'Tests'
}

{ #category : 'running' }
EcaJsonRpcFramerTest >> setUp [
	super setUp.
	framer := EcaJsonRpcFramer new
]

{ #category : 'tests' }
EcaJsonRpcFramerTest >> testRoundTrip [
	| stream message decoded |
	message := Dictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: 1;
		at: 'method' put: 'initialize';
		yourself.
	stream := ReadWriteStream on: ByteArray new.
	framer writeMessage: message on: stream.
	stream reset.
	decoded := framer readMessageFrom: stream.
	self assert: (decoded at: 'method') equals: 'initialize'.
	self assert: (decoded at: 'id') equals: 1
]

{ #category : 'tests' }
EcaJsonRpcFramerTest >> testContentLengthCountsUtf8Bytes [
	"Multi-byte characters: Content-Length must be the UTF-8 byte count,
	 not the character count."

	| stream message header |
	message := Dictionary new
		at: 'text' put: 'héllo — ✓';
		yourself.
	stream := ReadWriteStream on: ByteArray new.
	framer writeMessage: message on: stream.
	stream reset.
	header := framer readHeaderLineFrom: stream.
	self
		assert: (header copyAfter: $:) trimBoth asInteger
		equals: (NeoJSONWriter toString: message) utf8Encoded size.
	stream reset.
	self
		assert: ((framer readMessageFrom: stream) at: 'text')
		equals: 'héllo — ✓'
]

{ #category : 'tests' }
EcaJsonRpcFramerTest >> testTwoConsecutiveMessages [
	| stream |
	stream := ReadWriteStream on: ByteArray new.
	framer writeMessage: (Dictionary new at: 'id' put: 1; yourself) on: stream.
	framer writeMessage: (Dictionary new at: 'id' put: 2; yourself) on: stream.
	stream reset.
	self assert: ((framer readMessageFrom: stream) at: 'id') equals: 1.
	self assert: ((framer readMessageFrom: stream) at: 'id') equals: 2
]

{ #category : 'tests' }
EcaJsonRpcFramerTest >> testEndOfStreamAnswersNil [
	self assert: (framer readMessageFrom: (ReadStream on: ByteArray new)) isNil
]
