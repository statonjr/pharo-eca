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
		'stopButton',
		'approvalsSeen'
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
		whenSubmitDo: [ :text | self sendPrompt ];
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
	[
	[ | result |
	result := client prompt: text inChat: chatId.
	chatId ifNil: [ chatId := result at: 'chatId' ifAbsent: [ nil ] ] ]
		on: Error
		do: [ :e |
			UIManager default defer: [
				transcript text: transcript text asString
					, String cr , '[error] ' , e messageText ] ] ]
		forkAt: Processor userBackgroundPriority
		named: 'eca prompt'
]

{ #category : 'updating' }
EcaChatPresenter >> updateTranscriptWith: aChat [
	chatId = aChat id ifFalse: [ chatId ifNotNil: [ ^ self ] ].
	transcript text: (String streamContents: [ :s |
		aChat contents do: [ :block | self render: block on: s ] ]).
	"Open the approval dialog once per tool call, not once per re-render."
	aChat pendingToolCalls do: [ :block |
		(self approvalsSeen includes: block toolCallId) ifFalse: [
			self approvalsSeen add: block toolCallId.
			(EcaToolCallPresenter on: client)
				chatId: aChat id;
				toolCall: block;
				open ] ].
	self updateTitleFrom: aChat
]

{ #category : 'updating' }
EcaChatPresenter >> updateTitleFrom: aChat [
	"Surface the latest usage block (tokens/cost) in the window title.
	 Key names are looked up tolerantly across protocol versions."

	| usage parts |
	usage := (aChat contents reversed
		detect: [ :block | block type = 'usage' ]
		ifNone: [ ^ self ]) raw.
	parts := OrderedCollection new.
	(#( 'sessionTokens' 'totalTokens' )
		detect: [ :key | usage includesKey: key ]
		ifNone: [ nil ])
		ifNotNil: [ :key | parts add: (usage at: key) asString , ' tokens' ].
	(#( 'sessionCost' 'totalCost' 'lastMessageCost' 'messageCost' )
		detect: [ :key | usage includesKey: key ]
		ifNone: [ nil ])
		ifNotNil: [ :key | parts add: '$' , (usage at: key) asString ].
	parts isEmpty ifTrue: [ ^ self ].
	self window ifNotNil: [ :w |
		w title: 'ECA Chat — ' , (' · ' join: parts) ]
]

{ #category : 'updating' }
EcaChatPresenter >> render: aBlock on: aStream [
	"Text streams inline (user turns prefixed); reasoning collapses to a
	 thinking marker; bookkeeping blocks (progress/metadata/usage) are
	 hidden so they cannot interleave mid-word with text deltas."

	| type |
	aBlock isText ifTrue: [
		aBlock role = 'user' ifTrue: [ aStream cr; nextPutAll: '> ' ].
		^ aStream nextPutAll: aBlock text ].
	type := aBlock type.
	type = 'reasonStarted' ifTrue: [ ^ aStream cr; nextPutAll: '… thinking' ].
	type = 'reasonFinished' ifTrue: [ ^ aStream nextPutAll: ' done.'; cr ].
	(#( 'reasonText' 'progress' 'metadata' 'usage'
	    'toolCallPrepare' 'toolCallRunning' ) includes: type)
		ifTrue: [ ^ self ].
	type = 'toolCallRun' ifTrue: [
		^ aStream
			cr;
			nextPutAll: '-> ';
			nextPutAll: (aBlock raw at: 'name' ifAbsent: [ 'tool' ]);
			nextPutAll: (aBlock isToolCallAwaitingApproval
					ifTrue: [ ' (awaiting approval)' ]
					ifFalse: [ '' ]);
			cr ].
	type = 'toolCalled' ifTrue: [
		^ aStream
			nextPutAll: 'ok ';
			nextPutAll: (aBlock raw at: 'name' ifAbsent: [ 'tool' ]);
			cr ].
	type = 'toolCallRejected' ifTrue: [
		^ aStream
			nextPutAll: 'rejected ';
			nextPutAll: (aBlock raw at: 'name' ifAbsent: [ 'tool' ]);
			cr ].
	aStream
		nextPutAll: '[';
		nextPutAll: type;
		nextPutAll: ']';
		cr
]

{ #category : 'accessing' }
EcaChatPresenter >> approvalsSeen [
	^ approvalsSeen ifNil: [ approvalsSeen := Set new ]
]

{ #category : 'initialization' }
EcaChatPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'ECA Chat';
		initialExtent: 520 @ 640
]
