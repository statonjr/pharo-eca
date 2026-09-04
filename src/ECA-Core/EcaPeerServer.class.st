"
A poor man's nREPL for Pharo: a minimal Zinc HTTP endpoint that lets a peer
image (or an ECA agent wielding curl) evaluate expressions and inspect this
image. Ops, nREPL-style:

	GET  /describe        image info + available ops (JSON)
	GET  /classes?q=Str   class names matching a substring (text, max 100)
	POST /eval            body = Smalltalk source, answers printString

Binds to loopback only. /eval executes arbitrary code by design — the safety
gate is the *driving* side's ECA tool approval, plus this server being
localhost-only and explicitly started. Consider sandboxing before exposing
anything beyond experiments.

	EcaPeerServer startOn: 8086.
	EcaPeerServer stop.
"
Class {
	#name : 'EcaPeerServer',
	#superclass : 'Object',
	#instVars : [
		'server',
		'port'
	],
	#classVars : [
		'Default'
	],
	#category : 'ECA-Core-Peer',
	#package : 'ECA-Core',
	#tag : 'Peer'
}

{ #category : 'lifecycle' }
EcaPeerServer class >> startOn: aPort [
	Default ifNotNil: [ :s | s stop ].
	^ Default := self new startOn: aPort
]

{ #category : 'lifecycle' }
EcaPeerServer class >> stop [
	Default ifNotNil: [ :s | s stop ].
	Default := nil
]

{ #category : 'lifecycle' }
EcaPeerServer >> startOn: aPort [
	port := aPort.
	server := (ZnServer on: aPort)
		bindingAddress: NetNameResolver loopBackAddress;
		yourself.
	server delegate: self.
	server start.
	^ self
]

{ #category : 'lifecycle' }
EcaPeerServer >> stop [
	server ifNotNil: [ :s | [ s stop ] on: Error do: [ :e | ] ].
	server := nil
]

{ #category : 'accessing' }
EcaPeerServer >> port [
	^ port
]

{ #category : 'request handling' }
EcaPeerServer >> handleRequest: request [
	"Dispatch on the first path segment: ZnUrl>>path leading-slash semantics
	 vary, firstPathSegment does not."

	| op |
	op := request uri firstPathSegment.
	op = 'eval' ifTrue: [ ^ self handleEval: request ].
	op = 'describe' ifTrue: [ ^ self handleDescribe: request ].
	op = 'classes' ifTrue: [ ^ self handleClasses: request ].
	op = 'test' ifTrue: [ ^ self handleTest: request ].
	^ ZnResponse notFound: request uri
]

{ #category : 'request handling' }
EcaPeerServer >> handleTest: request [
	"GET /test?class=Name or /test?package=Name -> JSON SUnit report."

	| className packageName result |
	className := request uri queryAt: 'class' ifAbsent: [ nil ].
	packageName := request uri queryAt: 'package' ifAbsent: [ nil ].
	(className isNil and: [ packageName isNil ]) ifTrue: [
		^ ZnResponse badRequest: request ].
	result := EcaPeerSandbox
		protect: [
			className
				ifNotNil: [ EcaPeerTestRunner runClassNamed: className ]
				ifNil: [ EcaPeerTestRunner runPackageNamed: packageName ] ]
		timeoutMs: EcaPeerTestRunner timeoutMs.
	result isOk ifFalse: [ ^ ZnResponse serverError: result message ].
	result value ifNil: [ ^ ZnResponse notFound: request uri ].
	^ ZnResponse ok: (ZnEntity
		with: (NeoJSONWriter toString: result value)
		type: ZnMimeType applicationJson)
]

{ #category : 'request handling' }
EcaPeerServer >> handleEval: request [
	| result |
	request method = #POST ifFalse: [
		^ ZnResponse badRequest: request ].
	result := EcaPeerSandbox evaluate: request contents.
	result isOk ifTrue: [
		^ ZnResponse ok: (ZnEntity text: result value) ].
	result isDenied ifTrue: [
		^ ZnResponse new
			statusLine: (ZnStatusLine code: 403);
			entity: (ZnEntity text: result message);
			yourself ].
	^ ZnResponse serverError: result message
]

{ #category : 'request handling' }
EcaPeerServer >> handleDescribe: request [
	| info |
	info := Dictionary new
		at: 'server' put: 'eca-peer';
		at: 'image' put: Smalltalk image imageDirectory basename;
		at: 'pharo' put: SystemVersion current version;
		at: 'ops' put: #( 'describe' 'classes' 'eval' 'test' );
		yourself.
	^ ZnResponse ok: (ZnEntity
		with: (NeoJSONWriter toString: info)
		type: ZnMimeType applicationJson)
]

{ #category : 'request handling' }
EcaPeerServer >> handleClasses: request [
	| query names |
	query := request uri queryAt: 'q' ifAbsent: [ '' ].
	names := (Smalltalk globals allClassesAndTraits
		select: [ :each |
			query isEmpty or: [
				each name asLowercase includesSubstring: query asLowercase ] ]
		thenCollect: [ :each | each name ]) asSortedCollection.
	^ ZnResponse ok: (ZnEntity text:
		(String cr join: (names asArray first: (names size min: 100))))
]
y text:
		(String cr join: (names asArray first: (names size min: 100))))
]
