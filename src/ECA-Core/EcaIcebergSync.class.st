"
Closes the disk-vs-image gap: when the ECA agent's file tools edit a Tonel
.st file inside a registered Iceberg repository, the image's compiled classes
don't change until the package is reloaded. This listener watches completed
tool calls (toolCalled content blocks), detects .st paths under registered
repos, and offers a one-click reload of the affected package (Tonel layout:
the file's parent directory is the package).

Installed by EcaClient start; a session Set prevents re-prompting for the
same path within one image session.
"
Class {
	#name : 'EcaIcebergSync',
	#superclass : 'Object',
	#classVars : [
		'PromptedPaths'
	],
	#category : 'ECA-Core-Client',
	#package : 'ECA-Core',
	#tag : 'Client'
}

{ #category : 'installing' }
EcaIcebergSync class >> installOn: aSession [
	aSession announcer unsubscribe: self.
	aSession announcer
		when: EcaChatContentAdded
		do: [ :ann | self checkChat: ann chat ]
		for: self
]

{ #category : 'private' }
EcaIcebergSync class >> promptedPaths [
	^ PromptedPaths ifNil: [ PromptedPaths := Set new ]
]

{ #category : 'private' }
EcaIcebergSync class >> checkChat: aChat [
	aChat contents ifEmpty: [ ^ self ].
	self checkBlock: aChat contents last
]

{ #category : 'private' }
EcaIcebergSync class >> checkBlock: aBlock [
	| path repo |
	aBlock type = 'toolCalled' ifFalse: [ ^ self ].
	path := self editedPathIn: aBlock raw.
	path ifNil: [ ^ self ].
	(path endsWith: '.st') ifFalse: [ ^ self ].
	(self promptedPaths includes: path) ifTrue: [ ^ self ].
	repo := IceRepository registry
		detect: [ :each |
			each location notNil and: [
				path beginsWith: each location fullName ] ]
		ifNone: [ ^ self ].
	self promptedPaths add: path.
	self offerReloadOf: path in: repo
]

{ #category : 'private' }
EcaIcebergSync class >> editedPathIn: aRawBlockDictionary [
	"Answer the file path argument of a file-editing tool call, or nil."

	| arguments |
	arguments := aRawBlockDictionary at: 'arguments' ifAbsent: [ ^ nil ].
	arguments isDictionary ifFalse: [ ^ nil ].
	^ arguments
		at: 'path'
		ifAbsent: [ arguments at: 'file_path' ifAbsent: [ nil ] ]
]

{ #category : 'private' }
EcaIcebergSync class >> offerReloadOf: aPathString in: aRepository [
	UIManager default defer: [
		| packageName |
		packageName := aPathString asFileReference parent basename.
		(UIManager default confirm:
			'ECA edited ' , aPathString asFileReference basename
			, ' in repository ''' , aRepository name
			, '''. Reload package ''' , packageName , ''' from disk?')
			ifTrue: [ self reloadPackageNamed: packageName in: aRepository ] ]
]

{ #category : 'private' }
EcaIcebergSync class >> reloadPackageNamed: aPackageName in: aRepository [
	[ (aRepository workingCopy packageNamed: aPackageName) load.
	  UIManager default inform: aPackageName , ' reloaded from disk' ]
		on: Error
		do: [ :e |
			UIManager default inform:
				'Could not reload automatically (' , e messageText
				, '). Open Iceberg to load ' , aPackageName , '.' ]
]
