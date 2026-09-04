"
One chat conversation identified by the server-assigned chatId, accumulating
EcaContentBlock instances in arrival order.
"
Class {
	#name : 'EcaChat',
	#superclass : 'Object',
	#instVars : [
		'id',
		'contents'
	],
	#category : 'ECA-Core-Model',
	#package : 'ECA-Core',
	#tag : 'Model'
}

{ #category : 'instance creation' }
EcaChat class >> id: aChatId [
	^ self new
		setId: aChatId;
		yourself
]

{ #category : 'initialization' }
EcaChat >> setId: aChatId [
	id := aChatId.
	contents := OrderedCollection new
]

{ #category : 'accessing' }
EcaChat >> id [
	^ id
]

{ #category : 'accessing' }
EcaChat >> contents [
	^ contents
]

{ #category : 'adding' }
EcaChat >> addContent: anEcaContentBlock [
	contents add: anEcaContentBlock
]

{ #category : 'adding' }
EcaChat >> clearContents [
	contents := OrderedCollection new
]

{ #category : 'accessing' }
EcaChat >> pendingToolCalls [
	^ contents select: [ :block | block isToolCallAwaitingApproval ]
]

{ #category : 'printing' }
EcaChat >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		print: id;
		nextPutAll: ', ';
		print: contents size;
		nextPutAll: ' blocks)'
]
