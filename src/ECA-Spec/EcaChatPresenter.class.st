"
Main chat window: streaming transcript, prompt input, model selector, stop
button. Subscribes to the session announcer and re-renders on
EcaChatContentAdded / EcaSessionChanged. Opens from the World menu (ECA Chat).
"
Class {
	#name : 'EcaChatPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'client',
		'chatId',
		'transcript',
		'input',
		'modelList',
		'sendButton',
		'stopButton'
	],
	#category : 'ECA-Spec-Presenters',
	#package : 'ECA-Spec',
	#tag : 'Presenters'
}

{ #category : 'world menu' }
EcaChatPresenter class >> menuCommandOn: aBuilder [
	<worldMenu>
	(aBuilder item: #'ECA Chat')
		parent: #Tools;
		order: 30;
		action: [ self open ];
		iconName: #smallTalk;
		help: 'AI pair programming via ECA'
]

{ #category : 'instance creation' }
EcaChatPresenter class >> open [
	| client |
	client := EcaClient default.
	client isRunning ifFalse: [ client start ].
	^ (self on: client) open
]

{ #category : 'initialization' }
EcaChatPresenter >> setModelBeforeInitialization: anEcaClient [
	client := anEcaClient
]

{ #category : 'initialization' }
EcaChatPresenter >> initializePresenters [
	transcript := self newText
		beNotEditable;
		yourself.
	input := self newTextInput
		placeholder: 'Prompt (@ context, / commands)';
		yourself.
	modelList := self newDropList
		items: client session models;
		yourself.
	sendButton := self newButton
		label: 'Send';
		action: [ self sendPrompt ];
		yourself.
	stopButton := self newButton
		label: 'Stop';
		action: [ client stopPrompt: chatId ];
		yourself.
	"Announcements fire on the background JSON-RPC reader process:
	 route all widget mutations through the UI process (ChatPharo idiom)."
	client session announcer
		when: EcaChatContentAdded
		do: [ :ann |
			UIManager default defer: [ self updateTranscriptWith: ann chat ] ]
		for: self.
	client session announcer
		when: EcaSessionChanged
		do: [ :ann |
			UIManager default defer: [ modelList items: client session models ] ]
		for: self
]

{ #category : 'layout' }
EcaChatPresenter >> defaultLayout [
	^ SpBoxLayout newTopToBottom
		add: (SpBoxLayout newLeftToRight
				add: modelList;
				add: stopButton expand: false;
				yourself)
			expand: false;
		add: transcript;
		add: (SpBoxLayout newLeftToRight
				add: input;
				add: sendButton expand: false;
				yourself)
			expand: false;
		yourself
]

{ #category : 'actions' }
EcaChatPresenter >> sendPrompt [
	| text |
	text := input text asString trimBoth.
	text ifEmpty: [ ^ self ].
	input text: ''.
	client session selectedModel: modelList selectedItem.
	[ | result |
	result := client prompt: text inChat: chatId.
	chatId ifNil: [ chatId := result at: 'chatId' ifAbsent: [ nil ] ] ]
		forkAt: Processor userBackgroundPriority
		named: 'eca prompt'
]

{ #category : 'updating' }
EcaChatPresenter >> updateTranscriptWith: aChat [
	chatId = aChat id ifFalse: [ chatId ifNotNil: [ ^ self ] ].
	transcript text: (String streamContents: [ :s |
		aChat contents do: [ :block |
			block isText
				ifTrue: [ s nextPutAll: block text ]
				ifFalse: [
					s
						nextPutAll: '[';
						nextPutAll: block type;
						nextPutAll: ']';
						cr.
					block isToolCallAwaitingApproval ifTrue: [
						(EcaToolCallPresenter on: client)
							chatId: aChat id;
							toolCall: block;
							open ] ] ] ])
]

{ #category : 'initialization' }
EcaChatPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'ECA Chat';
		initialExtent: 520 @ 640
]
