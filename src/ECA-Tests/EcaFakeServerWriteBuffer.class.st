"
Binary write-stream adapter for the fake transport: buffers client bytes and,
on flush, parses complete framed messages and hands them to the transport's
#clientSent: for scripted responses.
"
Class {
	#name : 'EcaFakeServerWriteBuffer',
	#superclass : 'Object',
	#instVars : [
		'transport',
		'buffer',
		'framer'
	],
	#category : 'ECA-Tests-Fakes',
	#package : 'ECA-Tests',
	#tag : 'Fakes'
}

{ #category : 'instance creation' }
EcaFakeServerWriteBuffer class >> on: aFakeTransport [
	^ self new
		setTransport: aFakeTransport;
		yourself
]

{ #category : 'initialization' }
EcaFakeServerWriteBuffer >> setTransport: aFakeTransport [
	transport := aFakeTransport.
	buffer := WriteStream on: ByteArray new.
	framer := EcaJsonRpcFramer new
]

{ #category : 'writing' }
EcaFakeServerWriteBuffer >> nextPutAll: aByteArray [
	buffer nextPutAll: aByteArray
]

{ #category : 'writing' }
EcaFakeServerWriteBuffer >> flush [
	| readStream message |
	readStream := ReadStream on: buffer contents.
	[ readStream atEnd ] whileFalse: [
		message := framer readMessageFrom: readStream.
		message
			ifNil: [ ^ self ]
			ifNotNil: [ transport clientSent: message ] ].
	buffer := WriteStream on: ByteArray new
]
