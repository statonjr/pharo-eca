"
Approval dialog for a pending tool call: shows tool name, arguments, and (for
file-change tools) the proposed diff; Approve / Reject map to
chat/toolCallApprove and chat/toolCallReject.
"
Class {
	#name : 'EcaToolCallPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'client',
		'chatId',
		'toolCall',
		'detailsText',
		'approveButton',
		'rejectButton'
	],
	#category : 'ECA-Spec-Presenters',
	#package : 'ECA-Spec',
	#tag : 'Presenters'
}

{ #category : 'initialization' }
EcaToolCallPresenter >> setModelBeforeInitialization: anEcaClient [
	client := anEcaClient
]

{ #category : 'accessing' }
EcaToolCallPresenter >> chatId: anId [
	chatId := anId
]

{ #category : 'accessing' }
EcaToolCallPresenter >> toolCall: anEcaContentBlock [
	toolCall := anEcaContentBlock.
	detailsText text: (String streamContents: [ :s |
		s
			nextPutAll: 'Tool: ';
			nextPutAll: (toolCall raw at: 'name' ifAbsent: [ '?' ]);
			cr;
			cr.
		(toolCall raw at: 'details' ifAbsent: [ nil ]) ifNotNil: [ :details |
			(details at: 'diff' ifAbsent: [ nil ])
				ifNotNil: [ :diff | s nextPutAll: diff ]
				ifNil: [ s print: details ] ] ])
]

{ #category : 'initialization' }
EcaToolCallPresenter >> initializePresenters [
	detailsText := self newText
		beNotEditable;
		yourself.
	approveButton := self newButton
		label: 'Approve';
		action: [
			client approveToolCall: toolCall toolCallId inChat: chatId.
			self window close ];
		yourself.
	rejectButton := self newButton
		label: 'Reject';
		action: [
			client rejectToolCall: toolCall toolCallId inChat: chatId.
			self window close ];
		yourself
]

{ #category : 'layout' }
EcaToolCallPresenter >> defaultLayout [
	^ SpBoxLayout newTopToBottom
		add: detailsText;
		add: (SpBoxLayout newLeftToRight
				add: approveButton;
				add: rejectButton;
				yourself)
			expand: false;
		yourself
]

{ #category : 'initialization' }
EcaToolCallPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'ECA Tool Call Approval';
		initialExtent: 560 @ 420
]
