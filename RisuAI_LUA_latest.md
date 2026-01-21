# RisuAI Lua Scripting API Documentation (Latest)

> **Latest Documentation** - Generated from RisuAI codebase analysis
> 
> **Source**: Discovered and documented from `/src/ts/process/scriptings.ts` and related files
>
> **Usage**: Lua scripts can be used in RisuAI modules and character trigger scripts (V3 or Lua selection)

---

## Table of Contents

1. [Overview](#overview)
2. [Getting Started](#getting-started)
3. [Event Handlers](#event-handlers)
4. [Core API Functions](#core-api-functions)
5. [Chat Management](#chat-management)
6. [Variable Management](#variable-management)
7. [UI Functions](#ui-functions)
8. [LLM Integration](#llm-integration)
9. [Character Functions](#character-functions)
10. [Lorebook Functions](#lorebook-functions)
11. [Utility Functions](#utility-functions)
12. [Advanced Features](#advanced-features)
13. [JSON Library](#json-library)
14. [Best Practices](#best-practices)

---

## Overview

RisuAI's Lua scripting system allows you to create dynamic behaviors for characters and modules. Lua scripts run in a sandboxed environment with access to a comprehensive API for chat manipulation, LLM interaction, and more.

### Script Types

Lua scripts can be triggered in several contexts:

- **Trigger Scripts**: Character-specific scripts that run on events
- **Module Scripts**: Global scripts that run across all chats
- **Edit Triggers**: Scripts that modify input/output/display data

### Security Model

- Scripts have access to different permission levels
- **Safe Access**: Basic chat and variable operations
- **Edit Display Access**: Can modify display output
- **Low Level Access**: Full access to advanced features (LLM, image generation, network requests)

---

## Getting Started

### Basic Script Structure

```lua
-- Define event handlers for different triggers
function onStart(id)
    -- Runs when chat starts
    log("Chat started!")
end

function onInput(id)
    -- Runs when user sends input
    log("User input received")
end

function onOutput(id)
    -- Runs after AI generates output
    log("AI output generated")
end
```

### Edit Listeners

For modifying data in real-time:

```lua
-- Listen for different edit events
listenEdit('editInput', function(id, data, meta)
    -- Modify user input before processing
    return data
end)

listenEdit('editOutput', function(id, data, meta)
    -- Modify AI output before display
    return data
end)

listenEdit('editDisplay', function(id, data, meta)
    -- Modify final display output
    return data
end)

listenEdit('editRequest', function(id, data, meta)
    -- Modify request to LLM (data is OpenAIChat[] array)
    return data
end)
```

---

## Event Handlers

### Available Handlers

| Handler | Description | Parameters |
|---------|-------------|------------|
| `onStart(id)` | Triggered when chat starts | `id`: Access key |
| `onInput(id)` | Triggered on user input | `id`: Access key |
| `onOutput(id)` | Triggered after AI output | `id`: Access key |
| `onButtonClick(id, data)` | Triggered on button click | `id`: Access key, `data`: Button data |

### Edit Listeners

Use `listenEdit(type, func)` to register edit handlers:

```lua
listenEdit('editInput', function(id, data, meta)
    -- data: string - The input text
    -- meta: object - Metadata about the request
    
    -- Example: Convert input to uppercase
    return string.upper(data)
end)

listenEdit('editRequest', function(id, data, meta)
    -- data: OpenAIChat[] - Array of chat messages
    -- meta: object - Request metadata
    
    -- Example: Add system message
    table.insert(data, 1, {
        role = 'system',
        content = 'You are a helpful assistant'
    })
    return data
end)
```

---

## Core API Functions

### Logging

```lua
log(value)
```

Output data to the browser console.

**Parameters:**
- `value` (any): Value to log (will be JSON encoded)

**Example:**
```lua
log("Hello World")
log({message = "Hello", count = 42})
```

---

### CBS (Curly Brace Syntax) Parser

```lua
result = cbs(value)
```

Parse Curly Brace Syntax in strings (e.g., `{{char}}`, `{{user}}`).

**Parameters:**
- `value` (string): String containing CBS syntax

**Returns:**
- (string): Parsed string with CBS replaced

**Example:**
```lua
local msg = cbs("Hello {{user}}, I am {{char}}")
log(msg) -- "Hello John, I am Alice"
```

---

## Chat Management

### Get Chat Message

```lua
message = getChat(id, index)
```

Get a specific chat message by index.

**Parameters:**
- `id` (string): Access key
- `index` (number): Message index (negative values count from end, -1 is last message)

**Returns:**
- (table): Message object with fields:
  - `role` (string): 'user' or 'char'
  - `data` (string): Message content
  - `time` (number): Timestamp

**Example:**
```lua
local lastMsg = getChat(id, -1)
log("Last message: " .. lastMsg.data)

local firstMsg = getChat(id, 0)
log("First message role: " .. firstMsg.role)
```

---

### Get Full Chat

```lua
messages = getFullChat(id)
```

Get all chat messages.

**Parameters:**
- `id` (string): Access key

**Returns:**
- (table): Array of message objects

**Example:**
```lua
local chat = getFullChat(id)
log("Total messages: " .. #chat)

for i, msg in ipairs(chat) do
    log(i .. ": " .. msg.role .. " - " .. msg.data)
end
```

---

### Set Chat Message

```lua
setChat(id, index, value)
```

Modify a specific chat message.

**Parameters:**
- `id` (string): Access key (requires Safe Access)
- `index` (number): Message index
- `value` (string): New message content

**Example:**
```lua
-- Modify the last message
setChat(id, -1, "Modified message content")
```

---

### Set Chat Role

```lua
setChatRole(id, index, role)
```

Change the role of a specific message.

**Parameters:**
- `id` (string): Access key (requires Safe Access)
- `index` (number): Message index
- `role` (string): 'user' or 'char'

**Example:**
```lua
setChatRole(id, -1, 'user')
```

---

### Set Full Chat

```lua
setFullChat(id, messages)
```

Replace the entire chat history.

**Parameters:**
- `id` (string): Access key (requires Safe Access)
- `messages` (table): Array of message objects

**Example:**
```lua
local newChat = {
    {role = 'user', data = 'Hello!'},
    {role = 'char', data = 'Hi there!'}
}
setFullChat(id, newChat)
```

---

### Add Chat Message

```lua
addChat(id, role, value)
```

Append a new message to the chat.

**Parameters:**
- `id` (string): Access key (requires Safe Access)
- `role` (string): 'user' or 'char'
- `value` (string): Message content

**Example:**
```lua
addChat(id, 'char', 'This is a new message from the character')
```

---

### Insert Chat Message

```lua
insertChat(id, index, role, value)
```

Insert a message at a specific position.

**Parameters:**
- `id` (string): Access key (requires Safe Access)
- `index` (number): Position to insert
- `role` (string): 'user' or 'char'
- `value` (string): Message content

**Example:**
```lua
-- Insert at the beginning
insertChat(id, 0, 'system', 'System message')
```

---

### Remove Chat Message

```lua
removeChat(id, index)
```

Delete a specific message.

**Parameters:**
- `id` (string): Access key (requires Safe Access)
- `index` (number): Message index

**Example:**
```lua
removeChat(id, -1) -- Remove last message
```

---

### Cut Chat

```lua
cutChat(id, start, end)
```

Keep only messages in the specified range.

**Parameters:**
- `id` (string): Access key (requires Safe Access)
- `start` (number): Start index
- `end` (number): End index (exclusive)

**Example:**
```lua
-- Keep only the first 10 messages
cutChat(id, 0, 10)
```

---

### Get Chat Length

```lua
length = getChatLength(id)
```

Get the number of messages in the chat.

**Parameters:**
- `id` (string): Access key

**Returns:**
- (number): Number of messages

**Example:**
```lua
local count = getChatLength(id)
log("Total messages: " .. count)
```

---

### Get Last Messages

```lua
-- Get last character message
charMsg = getCharacterLastMessage(id)

-- Get last user message
userMsg = getUserLastMessage(id)
```

**Parameters:**
- `id` (string): Access key

**Returns:**
- (string): Message content

**Example:**
```lua
local lastChar = getCharacterLastMessage(id)
local lastUser = getUserLastMessage(id)
log("Last char said: " .. lastChar)
log("Last user said: " .. lastUser)
```

---

## Variable Management

### Get Chat Variable

```lua
value = getChatVar(id, key)
```

Get a chat-scoped variable.

**Parameters:**
- `id` (string): Access key
- `key` (string): Variable name

**Returns:**
- (string): Variable value

**Example:**
```lua
local counter = getChatVar(id, 'messageCount')
```

---

### Set Chat Variable

```lua
setChatVar(id, key, value)
```

Set a chat-scoped variable.

**Parameters:**
- `id` (string): Access key (requires Safe Access or Edit Display Access)
- `key` (string): Variable name
- `value` (string): Variable value

**Example:**
```lua
setChatVar(id, 'messageCount', '42')
```

---

### Get Global Variable

```lua
value = getGlobalVar(id, key)
```

Get a global variable (shared across all chats).

**Parameters:**
- `id` (string): Access key
- `key` (string): Variable name

**Returns:**
- (string): Variable value

**Example:**
```lua
local appVersion = getGlobalVar(id, 'version')
```

---

### State Management (JSON)

Convenience functions for storing complex data:

```lua
-- Get state (auto JSON decode)
data = getState(id, name)

-- Set state (auto JSON encode)
setState(id, name, value)
```

**Example:**
```lua
-- Store complex data
setState(id, 'userPrefs', {
    theme = 'dark',
    fontSize = 14,
    colors = {'red', 'blue', 'green'}
})

-- Retrieve it
local prefs = getState(id, 'userPrefs')
log("Theme: " .. prefs.theme)
log("Font size: " .. prefs.fontSize)
```

---

## UI Functions

### Alert Functions

```lua
-- Show error alert
alertError(id, message)

-- Show normal alert
alertNormal(id, message)

-- Get user input
result = alertInput(id, prompt):await()

-- Show selection dialog
selected = alertSelect(id, options):await()

-- Show confirmation dialog
confirmed = alertConfirm(id, message):await()
```

**Parameters:**
- `id` (string): Access key (requires Safe Access)
- `message` (string): Message to display
- `prompt` (string): Input prompt
- `options` (table): Array of strings for selection

**Returns:**
- `alertInput`: (string) User input
- `alertSelect`: (string) Selected option
- `alertConfirm`: (boolean) True if confirmed

**Example:**
```lua
alertError(id, "An error occurred!")
alertNormal(id, "Operation successful")

local name = alertInput(id, "Enter your name:"):await()
log("User entered: " .. name)

local choice = alertSelect(id, {"Option 1", "Option 2", "Option 3"}):await()
log("User selected: " .. choice)

local confirmed = alertConfirm(id, "Are you sure?"):await()
if confirmed then
    log("User confirmed")
end
```

---

### Reload Functions

```lua
-- Reload the entire GUI
reloadDisplay(id)

-- Reload a specific chat message
reloadChat(id, index)
```

**Parameters:**
- `id` (string): Access key (requires Safe Access)
- `index` (number): Message index for reloadChat

---

### Stop Chat

```lua
stopChat(id)
```

Stop the current chat/generation.

**Parameters:**
- `id` (string): Access key (requires Safe Access)

---

## LLM Integration

### Simple LLM Call

```lua
result = simpleLLM(id, prompt):await()
```

Send a simple prompt to the LLM.

**Parameters:**
- `id` (string): Access key (requires Low Level Access)
- `prompt` (string): Text prompt

**Returns:**
- (table): Result object with:
  - `success` (boolean): Whether the call succeeded
  - `result` (string): LLM response or error message

**Example:**
```lua
local result = simpleLLM(id, "What is the capital of France?"):await()
if result.success then
    log("Answer: " .. result.result)
else
    log("Error: " .. result.result)
end
```

---

### Advanced LLM Call

```lua
result = LLM(id, messages, useMultimodal):await()
```

Send a structured chat to the LLM.

**Parameters:**
- `id` (string): Access key (requires Low Level Access)
- `messages` (table): Array of message objects with:
  - `role` (string): 'system', 'user', or 'assistant'/'char'/'bot'
  - `content` (string): Message content
- `useMultimodal` (boolean, optional): Enable multimodal support (images)

**Returns:**
- (table): Result object with success and result fields

**Example:**
```lua
local messages = {
    {role = 'system', content = 'You are a helpful assistant'},
    {role = 'user', content = 'Tell me a joke'}
}

local result = LLM(id, messages):await()
if result.success then
    log("LLM says: " .. result.result)
end
```

---

### Auxiliary LLM Call

```lua
result = axLLM(id, messages, useMultimodal):await()
```

Call the auxiliary LLM (uses 'otherAx' model instead of 'model').

**Parameters:** Same as `LLM()`

**Example:**
```lua
local result = axLLM(id, {
    {role = 'user', content = 'Summarize this text: ...'}
}):await()
```

---

## Character Functions

### Get Character Name

```lua
name = getName(id)
```

Get the current character's name.

**Returns:**
- (string): Character name

---

### Set Character Name

```lua
setName(id, name)
```

Change the character's name.

**Parameters:**
- `id` (string): Access key (requires Safe Access)
- `name` (string): New name

---

### Get Character Description

```lua
desc = getDescription(id)
```

Get the character's description.

**Returns:**
- (string): Character description

---

### Set Character Description

```lua
setDescription(id, desc)
```

Change the character's description.

**Parameters:**
- `id` (string): Access key (requires Safe Access)
- `desc` (string): New description

---

### Get Character First Message

```lua
msg = getCharacterFirstMessage(id)
```

Get the character's first/greeting message.

**Returns:**
- (string): First message

---

### Set Character First Message

```lua
success = setCharacterFirstMessage(id, message)
```

Set the character's first message.

**Parameters:**
- `id` (string): Access key (requires Safe Access)
- `message` (string): New first message

**Returns:**
- (boolean): True if successful

---

### Get Character Image

```lua
imageTag = getCharacterImage(id):await()
```

Get the character's image as an inlay tag.

**Parameters:**
- `id` (string): Access key

**Returns:**
- (string): Image inlay tag like `{{inlayed::imageId}}`

---

### Get Persona Functions

```lua
-- Get persona name
name = getPersonaName(id)

-- Get persona description (with CBS parsing)
desc = getPersonaDescription(id)

-- Get persona image as inlay tag
image = getPersonaImage(id):await()
```

---

## Lorebook Functions

### Get Lorebooks

```lua
books = getLoreBooks(id, search)
```

Get lorebook entries matching a search string.

**Parameters:**
- `id` (string): Access key
- `search` (string): Search term (matches comment field)

**Returns:**
- (table): Array of lorebook entries with CBS-parsed content

**Example:**
```lua
local books = getLoreBooks(id, "character_bio")
for i, book in ipairs(books) do
    log("Book: " .. book.comment)
    log("Content: " .. book.content)
end
```

---

### Load Lorebooks

```lua
activeBooks = loadLoreBooks(id, reserveTokens):await()
```

Load active lorebook entries within token budget.

**Parameters:**
- `id` (string): Access key (requires Low Level Access)
- `reserveTokens` (number): Tokens to reserve (max_context - reserve)

**Returns:**
- (table): Array of active lorebook entries with:
  - `data` (string): Parsed content
  - `role` (string): 'user', 'char', or 'system'

**Example:**
```lua
local books = loadLoreBooks(id, 1000):await()
log("Loaded " .. #books .. " lorebook entries")
```

---

### Upsert Local Lorebook

```lua
upsertLocalLoreBook(id, name, content, options)
```

Create or update a local lorebook entry for the current chat.

**Parameters:**
- `id` (string): Access key (requires Safe Access)
- `name` (string): Lorebook name/comment
- `content` (string): Lorebook content
- `options` (table): Configuration with:
  - `alwaysActive` (boolean): Always activate
  - `insertOrder` (number): Insert order (default 100)
  - `key` (string): Activation key
  - `secondKey` (string): Secondary key
  - `regex` (boolean): Use regex for keys

**Example:**
```lua
upsertLocalLoreBook(id, "important_fact", "The sky is blue", {
    alwaysActive = true,
    insertOrder = 50,
    key = "sky, weather"
})
```

---

## Utility Functions

### Tokenization

```lua
tokens = getTokens(id, text):await()
```

Get the token count for text.

**Parameters:**
- `id` (string): Access key (requires Safe Access)
- `text` (string): Text to tokenize

**Returns:**
- (number): Token count

**Example:**
```lua
local count = getTokens(id, "Hello world!"):await()
log("Token count: " .. count)
```

---

### Sleep

```lua
sleep(id, milliseconds):await()
```

Pause execution for a specified time.

**Parameters:**
- `id` (string): Access key (requires Safe Access)
- `milliseconds` (number): Duration in milliseconds

**Example:**
```lua
log("Starting...")
sleep(id, 2000):await()
log("2 seconds later")
```

---

### Hash

```lua
hashValue = hash(id, text):await()
```

Generate a hash of the text.

**Parameters:**
- `id` (string): Access key
- `text` (string): Text to hash

**Returns:**
- (string): Hash value

---

### Author's Note

```lua
-- Get author's note
note = getAuthorsNote(id)
```

**Returns:**
- (string): Author's note content

---

### Background Embedding

```lua
-- Get background HTML
html = getBackgroundEmbedding(id)

-- Set background HTML
success = setBackgroundEmbedding(id, html)
```

**Parameters:**
- `id` (string): Access key (requires Safe Access for set)
- `html` (string): HTML content

**Returns:**
- (boolean): True if successful

---

## Advanced Features

### Similarity Search

```lua
results = similarity(id, source, candidates):await()
```

Find similar strings using embeddings.

**Parameters:**
- `id` (string): Access key (requires Low Level Access)
- `source` (string): Source text to compare
- `candidates` (table): Array of candidate strings

**Returns:**
- (table): Array of candidates sorted by similarity (most similar first)

**Example:**
```lua
local similar = similarity(id, "cat", {"dog", "kitten", "car", "feline"}):await()
-- Result: {"kitten", "feline", "dog", "car"}
for i, word in ipairs(similar) do
    log(i .. ": " .. word)
end
```

---

### HTTP Requests

```lua
response = request(id, url):await()
```

Make an HTTP GET request.

**Parameters:**
- `id` (string): Access key (requires Low Level Access)
- `url` (string): URL to request (must be HTTPS, max 120 chars)

**Returns:**
- (table): Response object with:
  - `status` (number): HTTP status code
  - `data` (string): Response body

**Limitations:**
- Only HTTPS URLs allowed
- Max URL length: 120 characters
- Only GET requests
- Rate limited: 5 requests per minute
- Certain domains are blocked (risuai.net, etc.)

**Example:**
```lua
local resp = request(id, "https://api.example.com/data"):await()
local data = json.decode(resp.data)

if resp.status == 200 then
    log("Success: " .. resp.data)
else
    log("Error: " .. resp.status)
end
```

---

### Image Generation

```lua
imageTag = generateImage(id, prompt, negativePrompt):await()
```

Generate an AI image.

**Parameters:**
- `id` (string): Access key (requires Low Level Access)
- `prompt` (string): Image generation prompt
- `negativePrompt` (string, optional): Negative prompt

**Returns:**
- (string): Image inlay tag or error message

**Example:**
```lua
local img = generateImage(id, "a cute cat", "ugly, distorted"):await()
if img:match("^{{inlay::") then
    log("Generated image: " .. img)
else
    log("Error: " .. img)
end
```

---

## JSON Library

RisuAI includes the `json.lua` library for JSON encoding/decoding.

### JSON Encode

```lua
jsonString = json.encode(table)
```

Convert Lua table to JSON string.

**Example:**
```lua
local data = {
    name = "Alice",
    age = 30,
    hobbies = {"reading", "coding"}
}
local jsonStr = json.encode(data)
log(jsonStr) -- {"name":"Alice","age":30,"hobbies":["reading","coding"]}
```

---

### JSON Decode

```lua
table = json.decode(jsonString)
```

Convert JSON string to Lua table.

**Example:**
```lua
local jsonStr = '{"name":"Bob","score":100}'
local data = json.decode(jsonStr)
log(data.name) -- "Bob"
log(data.score) -- 100
```

---

## Best Practices

### 1. Always Use Await for Async Functions

```lua
-- WRONG
local result = LLM(id, messages)

-- CORRECT
local result = LLM(id, messages):await()
```

---

### 2. Error Handling

```lua
function onInput(id)
    local success, error = pcall(function()
        -- Your code here
        local result = simpleLLM(id, "test"):await()
        if not result.success then
            alertError(id, "LLM error: " .. result.result)
        end
    end)
    
    if not success then
        log("Error: " .. tostring(error))
    end
end
```

---

### 3. Use State for Complex Data

Instead of storing JSON strings manually:

```lua
-- GOOD
setState(id, 'config', {
    enabled = true,
    maxLength = 100,
    tags = {"important", "urgent"}
})

local config = getState(id, 'config')
if config.enabled then
    -- Do something
end

-- AVOID
setChatVar(id, 'config', '{"enabled":true,"maxLength":100}')
local configStr = getChatVar(id, 'config')
local config = json.decode(configStr)
```

---

### 4. Efficient Chat Operations

```lua
-- Get last message efficiently
local lastMsg = getChat(id, -1)

-- Instead of:
local chat = getFullChat(id)
local lastMsg = chat[#chat]
```

---

### 5. Safe Variable Access

```lua
-- Check if variable exists
local count = getChatVar(id, 'counter')
if count == "" or count == nil then
    count = "0"
end
count = tonumber(count) or 0
```

---

### 6. Async Helper Function

```lua
-- Use the built-in async helper for complex async flows
myAsyncFunc = async(function(id, param)
    local result1 = LLM(id, messages1):await()
    local result2 = LLM(id, messages2):await()
    return result1.result .. " " .. result2.result
end)

-- Call it
local combined = myAsyncFunc(id, "test"):await()
```

---

## Example Scripts

### Example 1: Message Counter

```lua
function onOutput(id)
    -- Get current count
    local count = getChatVar(id, 'messageCount')
    if count == "" then
        count = "0"
    end
    
    -- Increment
    count = tonumber(count) + 1
    
    -- Save
    setChatVar(id, 'messageCount', tostring(count))
    
    -- Show notification every 10 messages
    if count % 10 == 0 then
        alertNormal(id, "You've sent " .. count .. " messages!")
    end
end
```

---

### Example 2: Sentiment Analysis

```lua
listenEdit('editOutput', function(id, data, meta)
    -- Analyze sentiment with LLM
    local messages = {
        {role = 'system', content = 'Analyze the sentiment of the following text and respond with only: positive, negative, or neutral'},
        {role = 'user', content = data}
    }
    
    local result = LLM(id, messages):await()
    
    if result.success then
        local sentiment = result.result:lower()
        -- Store sentiment
        setChatVar(id, 'lastSentiment', sentiment)
        
        -- You could modify data based on sentiment here
        if sentiment:match("negative") then
            log("Detected negative sentiment")
        end
    end
    
    return data
end)
```

---

### Example 3: Auto-Summarization

```lua
function onOutput(id)
    local chatLength = getChatLength(id)
    
    -- Summarize every 20 messages
    if chatLength % 20 == 0 then
        -- Get recent chat
        local chat = getFullChat(id)
        local recent = {}
        
        -- Get last 10 messages
        for i = math.max(1, #chat - 9), #chat do
            table.insert(recent, chat[i])
        end
        
        -- Build prompt
        local chatText = ""
        for _, msg in ipairs(recent) do
            chatText = chatText .. msg.role .. ": " .. msg.data .. "\n"
        end
        
        -- Request summary
        local result = simpleLLM(id, "Summarize this conversation:\n" .. chatText):await()
        
        if result.success then
            -- Store summary
            setState(id, 'lastSummary', {
                messageCount = chatLength,
                summary = result.result,
                timestamp = os.time()
            })
            
            alertNormal(id, "Chat summarized!")
        end
    end
end
```

---

### Example 4: Dynamic Lorebook

```lua
function onInput(id)
    -- Extract keywords from user input
    local chat = getChat(id, -1)
    local userInput = chat.data
    
    -- Use LLM to extract important entities
    local result = simpleLLM(id, "Extract 1-3 important keywords from this text, separated by commas: " .. userInput):await()
    
    if result.success then
        local keywords = result.result
        
        -- Create/update lorebook entry
        upsertLocalLoreBook(id, "recent_topics", "Recent discussion topics: " .. keywords, {
            alwaysActive = false,
            insertOrder = 90,
            key = keywords,
            regex = false
        })
    end
end
```

---

### Example 5: Image Response Trigger

```lua
listenEdit('editOutput', function(id, data, meta)
    -- Check if output mentions wanting to show an image
    if data:lower():match("show.*image") or data:lower():match("picture of") then
        -- Extract what to generate
        local prompt = "a beautiful landscape"
        
        -- Try to extract from the text (simple approach)
        local match = data:match("picture of (.+)")
        if match then
            prompt = match
        end
        
        -- Generate image
        local img = generateImage(id, prompt, ""):await()
        
        -- Append to output if successful
        if img:match("^{{inlay::") then
            data = data .. "\n\n" .. img
        end
    end
    
    return data
end)
```

---

## Troubleshooting

### Common Issues

1. **"attempt to call a nil value"**
   - Make sure you're calling the function correctly
   - Check that you have the right access level (Safe/Low Level)

2. **"Invalid access key"** 
   - You're trying to use a restricted function without proper permissions
   - Check if the character has "Low Level Access" enabled

3. **Async functions not working**
   - Remember to use `:await()` on all async functions
   - Use the `async()` wrapper for complex async code

4. **Variables not persisting**
   - Make sure you're using `setChatVar`, not just local variables
   - Use `setState` for complex data structures

5. **JSON decode errors**
   - Validate JSON strings before decoding
   - Use `pcall` to catch decode errors

---

## Advanced Patterns

### Stateful Behavior

```lua
-- Initialize state on first run
function onStart(id)
    local state = getState(id, 'myState')
    if state == nil then
        setState(id, 'myState', {
            initialized = true,
            counter = 0,
            history = {}
        })
    end
end

-- Use state in handlers
function onInput(id)
    local state = getState(id, 'myState')
    state.counter = state.counter + 1
    table.insert(state.history, os.time())
    setState(id, 'myState', state)
end
```

---

### Chained LLM Calls

```lua
myComplexOperation = async(function(id, userInput)
    -- First LLM call: analyze intent
    local intent = LLM(id, {
        {role = 'user', content = 'What is the intent of: ' .. userInput}
    }):await()
    
    if not intent.success then
        return "Error in intent analysis"
    end
    
    -- Second LLM call: generate response based on intent
    local response = LLM(id, {
        {role = 'system', content = 'Respond based on intent: ' .. intent.result},
        {role = 'user', content = userInput}
    }):await()
    
    return response.result
end)
```

---

## Summary

RisuAI's Lua scripting API provides powerful capabilities for:

- ✅ Dynamic chat manipulation
- ✅ LLM integration and chaining
- ✅ Character customization
- ✅ Stateful behaviors
- ✅ UI interactions
- ✅ Network requests (limited)
- ✅ Image generation
- ✅ Lorebook management

Remember:
- Use `:await()` for async functions
- Handle errors with `pcall`
- Use `setState` for complex data
- Check access requirements (Safe/Low Level)

Happy scripting! 🚀
