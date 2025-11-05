# ChatBot
My take on building a chatgpt type app which uses OpenAI responses API

This is WIP project which demonstrates how we can build a chat bot using openAI apis. UI is inspired my imessage app. 

**NOTE**
You need to add your own API_Key in `OpenAIContants` struct if you want to use a live version. You can create one following OpenAI instructions.
If you would rather not, you could still try this app using mock responses.


![chabot_gif](https://github.com/user-attachments/assets/1aa555cf-89ea-46c3-97a1-ef0db0a5dc88)


# Key iOS Features
- Async/Await
- Combine
- SwiftUI List views + cell views
- UIKit CollectionView with diffable datasource
- SwiftData

# Architecture

- Use reactive redux architecture with slight modification
- AppStore connects all pieces and is injected in necessary classes
- Dedicated state and middleware for Chats and conversation views
- Dedicated actions for chats and conversation fetch/set
- Dispatcher uses combines to notify state to handle any set actions and middlewares to handle any get actions

## Class Diagrams

### Views specific diagram
![ChatBot_UI_class_diagram](https://github.com/user-attachments/assets/009fc70f-4dd3-48da-8ce0-276aca246fb0)

### Redux/Data models specific diagram
![ChatBot_class_diagram](https://github.com/user-attachments/assets/2aa444b4-bfcf-4739-ade1-e4ab9c7f400f)

## Sequence Diagram

### Chat sequence diagram

#### Fetch chats from cache/DB
<img width="961" height="574" alt="GetChats" src="https://github.com/user-attachments/assets/61c14add-fbf7-4c21-a908-9e3024dd4199" />

#### Get chat response
<img width="2068" height="1088" alt="GetChatResponse" src="https://github.com/user-attachments/assets/8cbb4e0d-fbf5-465e-b13c-9070c7d4841e" />


### Conversation sequence diagram

#### Get conversations from cache/DB
<img width="1159" height="472" alt="GetConversations" src="https://github.com/user-attachments/assets/84f8d37f-0d82-4998-95ae-77b731a1f5f8" />

#### Create conversation
<img width="1102" height="472" alt="CreateConversation" src="https://github.com/user-attachments/assets/0146c77f-0b23-49d3-b595-6caaef8e5c2a" />

#### Edit Conversation
<img width="1117" height="472" alt="EditConversation" src="https://github.com/user-attachments/assets/47aca2bd-a8e2-4a99-ab6c-af74c49d89b9" />


#### Delete conversations
<img width="1180" height="507" alt="DeleteConversation" src="https://github.com/user-attachments/assets/0492ede3-9cde-4494-95fe-26968808a13f" />



# TODOs
- ~~give chat context to responses API~~
- ~~Error handling like when offline tell user no internet connection, failure of responses API show message to user that something went wrong and allow for retry~~
- ~~Delete conversations, perhapd rename them as well~~
- ~~Currently everything is cached in memory, plan is to use SwiftData for persistent storage~~
- cancellation of previous request, if user types before we get response
- Add pagination ability to only fetch recent convresations/chat messages for a conversation instead of everything even from persistent store
- Eventually use CloudKit to store data on cloud and only fetch what is recent/needed
- Show usage data
- user settings to send context vs not
- Dark mode support
- switch between models
