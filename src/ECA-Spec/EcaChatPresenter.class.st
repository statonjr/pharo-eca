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
		'approvalsSeen',
		'selectedContexts',
		'completionProcess',
		'lastCompletionToken'
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
	| client presenter |
	client := EcaClient default.
	client isRunning ifFalse: [ client start ].
	presenter := self on: client.
	presenter open.
	^ presenter
]

{ #category : 'instance creation' }
EcaChatPresenter class >> openOnClass: aClass [
	"Open the chat prefilled with a prompt about aClass, including its
	 Tonel file path when the class lives in an Iceberg repository."

	| presenter context |
	presenter := self open.
	context := EcaCalypsoContextExtension contextForClass: aClass.
	presenter prefill: (context
		ifNil: [ 'Tell me about the Pharo class ' , aClass name ]
		ifNotNil: [ 'Explain the Pharo class defined in ' , (context at: 'path') ]).
	^ presenter
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
		whenTextChangedDo: [ :text | self scheduleCompletionFrom: text asString ];
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
EcaChatPresenter >> prefill: aString [
	input text: aString
]

{ #category : 'accessing' }
EcaChatPresenter >> selectedContexts [
	^ selectedContexts ifNil: [ selectedContexts := OrderedCollection new ]
]

{ #category : 'completion' }
EcaChatPresenter >> scheduleCompletionFrom: aString [
	"Debounce: (re)start a background query 400ms after the last keystroke."

	completionProcess ifNotNil: [ :p | p terminate ].
	aString ifEmpty: [ ^ lastCompletionToken := nil ].
	completionProcess := [
		(Delay forMilliseconds: 400) wait.
		self completeFrom: aString ]
			forkAt: Processor userBackgroundPriority
			named: 'eca completion'
]

{ #category : 'completion' }
EcaChatPresenter >> completeFrom: aString [
	| token |
	(aString beginsWith: '/') ifTrue: [
		(aString includes: Character space) ifTrue: [ ^ self ].
		token := aString allButFirst.
		token = lastCompletionToken ifTrue: [ ^ self ].
		lastCompletionToken := token.
		^ self offerCommandsFor: token ].
	token := self atTokenIn: aString.
	token ifNil: [ ^ self ].
	token = lastCompletionToken ifTrue: [ ^ self ].
	lastCompletionToken := token.
	self offerContextsFor: token
]

{ #category : 'completion' }
EcaChatPresenter >> atTokenIn: aString [
	"Answer the text after a trailing @ at a word boundary, or nil."

	| index |
	index := aString lastIndexOf: $@.
	index = 0 ifTrue: [ ^ nil ].
	(index > 1 and: [ (aString at: index - 1) isSeparator not ])
		ifTrue: [ ^ nil ].
	^ aString copyFrom: index + 1 to: aString size
]

{ #category : 'completion' }
EcaChatPresenter >> offerContextsFor: token [
	| result items |
	result := [ client queryContext: token inChat: chatId ]
		on: Error
		do: [ :e | ^ self ].
	items := result at: 'contexts' ifAbsent: [ #(  ) ].
	items isEmpty ifTrue: [ ^ self ].
	UIManager default defer: [ self chooseContextFrom: items ]
]

{ #category : 'completion' }
EcaChatPresenter >> chooseContextFrom: items [
	| choice text index label |
	choice := UIManager default
		chooseFrom: (items collect: [ :each | self labelForContext: each ])
		values: items
		title: 'Add context'.
	choice ifNil: [ ^ self ].
	self selectedContexts add: choice.
	label := self labelForContext: choice.
	text := input text asString.
	index := text lastIndexOf: $@.
	index = 0 ifTrue: [ ^ self ].
	input text: (text first: index - 1) , '@' , label , ' '
]

{ #category : 'completion' }
EcaChatPresenter >> labelForContext: aContextDictionary [
	^ aContextDictionary
		at: 'path'
		ifAbsent: [ aContextDictionary at: 'type' ifAbsent: [ 'context' ] ]
]

{ #category : 'completion' }
EcaChatPresenter >> offerCommandsFor: token [
	| result items |
	result := [ client queryCommands: token inChat: chatId ]
		on: Error
		do: [ :e | ^ self ].
	items := result at: 'commands' ifAbsent: [ #(  ) ].
	items isEmpty ifTrue: [ ^ self ].
	UIManager default defer: [ self chooseCommandFrom: items ]
]

{ #category : 'completion' }
EcaChatPresenter >> chooseCommandFrom: items [
	| choice |
	choice := UIManager default
		chooseFrom: (items collect: [ :each |
			(each at: 'name' ifAbsent: [ '?' ]) ,
			((each at: 'description' ifAbsent: [ nil ])
				ifNil: [ '' ]
				ifNotNil: [ :d | ' — ' , d ]) ])
		values: items
		title: 'Commands'.
	choice ifNil: [ ^ self ].
	input text: '/' , (choice at: 'name' ifAbsent: [ '' ]) , ' '
]

{ #category : 'actions' }
EcaChatPresenter >> sendPrompt [
	| text contexts |
	text := input text asString trimBoth.
	text ifEmpty: [ ^ self ].
	input text: ''.
	lastCompletionToken := nil.
	contexts := self selectedContexts asArray.
	selectedContexts := OrderedCollection new.
	client session selectedModel: modelList selectedItem.
	[
	[ | result |
	result := client prompt: text inChat: chatId contexts: contexts.
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
	transcript text: (self renderMarkdown: (String streamContents: [ :s |
		aChat contents do: [ :block | self render: block on: s ] ])).
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

{ #category : 'updating' }
EcaChatPresenter >> renderMarkdown: aString [
	"Answer rich Text via Microdown when available (headings, bold, code
	 blocks); fall back to the plain string in images without Microdown
	 or on any composer hiccup mid-stream."

	| microdown composer document |
	microdown := Smalltalk at: #Microdown ifAbsent: [ ^ aString ].
	composer := Smalltalk at: #MicRichTextComposer ifAbsent: [ ^ aString ].
	^ [
		document := microdown parse: aString.
		[ composer new asRichText: document ]
			on: MessageNotUnderstood
			do: [ :e | composer new visit: document ] ]
		on: Error
		do: [ :e | aString ]
]

{ #category : 'initialization' }
EcaChatPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'ECA Chat';
		initialExtent: 520 @ 640
]
