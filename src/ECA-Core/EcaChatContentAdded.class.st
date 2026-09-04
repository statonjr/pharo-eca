"
Announced when a chat/contentReceived block is appended to (or cleared from)
an EcaChat. Carries the affected chat so listeners can re-render it.
"
Class {
	#name : 'EcaChatContentAdded',
	#superclass : 'Announcement',
	#instVars : [
		'chat'
	],
	#category : 'ECA-Core-Announcements',
	#package : 'ECA-Core',
	#tag : 'Announcements'
}

{ #category : 'instance creation' }
EcaChatContentAdded class >> chat: anEcaChat [
	^ self new
		chat: anEcaChat;
		yourself
]

{ #category : 'accessing' }
EcaChatContentAdded >> chat [
	^ chat
]

{ #category : 'accessing' }
EcaChatContentAdded >> chat: anEcaChat [
	chat := anEcaChat
]
