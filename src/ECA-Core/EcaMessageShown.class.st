"
Announced for $/showMessage server notifications (info/warning/error popups).
The message dictionary carries 'type' and 'message' keys.
"
Class {
	#name : 'EcaMessageShown',
	#superclass : 'Announcement',
	#instVars : [
		'message'
	],
	#category : 'ECA-Core-Announcements',
	#package : 'ECA-Core',
	#tag : 'Announcements'
}

{ #category : 'instance creation' }
EcaMessageShown class >> message: aDictionary [
	^ self new
		message: aDictionary;
		yourself
]

{ #category : 'accessing' }
EcaMessageShown >> message [
	^ message
]

{ #category : 'accessing' }
EcaMessageShown >> message: aDictionary [
	message := aDictionary
]
