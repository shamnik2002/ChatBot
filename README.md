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

### Conversation sequence diagram

# TODOs
- Error handling like when offline tell user no internet connection, failure of responses API show message to user that something went wrong and allow for retry
- ~~Delete conversations, perhapd rename them as well~~
- cancellation of previous request, if user types before we get response
- ~~Currently everything is cached in memory, plan is to use SwiftData for persistent storage~~
- Eventually use CloudKit to store data on cloud and only fetch what is recent/needed
- After cloudkit, add pagination ability to only fetch recent chat messages for a conversation instead of everything
