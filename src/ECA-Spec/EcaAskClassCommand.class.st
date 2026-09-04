"
Calypso context-menu command: 'Ask ECA about this class' on the class list.
Opens the ECA chat prefilled with a prompt referencing the selected class's
Tonel file (via EcaCalypsoContextExtension).
"
Class {
	#name : 'EcaAskClassCommand',
	#superclass : 'SycClassCommand',
	#category : 'ECA-Spec-Calypso',
	#package : 'ECA-Spec',
	#tag : 'Calypso'
}

{ #category : 'activation' }
EcaAskClassCommand class >> browserContextMenuActivation [
	<classAnnotation>
	^ CmdContextMenuActivation
		byRootGroupItemOrder: 100
		for: ClyFullBrowserClassContext
]

{ #category : 'accessing' }
EcaAskClassCommand >> defaultMenuItemName [
	^ 'Ask ECA about this class'
]

{ #category : 'accessing' }
EcaAskClassCommand >> defaultMenuIconName [
	^ #smallTalk
]

{ #category : 'execution' }
EcaAskClassCommand >> execute [
	EcaChatPresenter openOnClass: classes first instanceSide
]
