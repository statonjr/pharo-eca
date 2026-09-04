"
One `chat/contentReceived` payload: role (user/assistant/system) plus a content
dictionary whose `type` is one of: text, reasonStarted/reasonText/reasonFinished,
toolCallPrepare, toolCallRun, toolCallRunning, toolCalled, toolCallRejected,
usage, progress. Keeps the raw dictionary; exposes typed accessors for the UI.
"
Class {
	#name : 'EcaContentBlock',
	#superclass : 'Object',
	#instVars : [
		'role',
		'content'
	],
	#category : 'ECA-Core-Model',
	#package : 'ECA-Core',
	#tag : 'Model'
}

{ #category : 'instance creation' }
EcaContentBlock class >> fromDictionary: params [
	^ self new
		setRole: (params at: 'role' ifAbsent: [ 'assistant' ])
		content: (params at: 'content' ifAbsent: [ Dictionary new ]);
		yourself
]

{ #category : 'initialization' }
EcaContentBlock >> setRole: aString content: aDictionary [
	role := aString.
	content := aDictionary
]

{ #category : 'accessing' }
EcaContentBlock >> role [
	^ role
]

{ #category : 'accessing' }
EcaContentBlock >> type [
	^ content at: 'type' ifAbsent: [ 'text' ]
]

{ #category : 'accessing' }
EcaContentBlock >> text [
	^ content at: 'text' ifAbsent: [ '' ]
]

{ #category : 'accessing' }
EcaContentBlock >> raw [
	^ content
]

{ #category : 'testing' }
EcaContentBlock >> isText [
	^ self type = 'text'
]

{ #category : 'testing' }
EcaContentBlock >> isToolCall [
	^ self type beginsWith: 'toolCall'
]

{ #category : 'testing' }
EcaContentBlock >> isToolCallAwaitingApproval [
	^ self type = 'toolCallRun' and: [
		(content at: 'manualApproval' ifAbsent: [ false ]) = true ]
]

{ #category : 'accessing' }
EcaContentBlock >> toolCallId [
	^ content at: 'id' ifAbsent: [ nil ]
]

{ #category : 'printing' }
EcaContentBlock >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: role;
		nextPutAll: '/';
		nextPutAll: self type;
		nextPutAll: ')'
]
