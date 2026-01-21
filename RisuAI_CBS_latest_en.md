# RisuAI CBS (Curly Brace Syntax) Complete Guide

> **Last Updated**: 2026-01-07  
> **Version**: Latest (Direct Codebase Analysis)

## Table of Contents
1. [What is CBS?](#what-is-cbs)
2. [Basic Syntax](#basic-syntax)
3. [CBS Functions by Category](#cbs-functions-by-category)
4. [Detailed Reference](#detailed-reference)
5. [Examples and Use Cases](#examples-and-use-cases)

---

## What is CBS?

**CBS (Curly Brace Syntax)** is a **template variable substitution system** used in RisuAI. Using curly brace syntax in the format `{{variable_name}}`, you can dynamically substitute and manipulate text.

### Basic Example
```
{{char}} said to {{user}}: "Hello!"
```
At runtime, this becomes:
```
Alice said to John: "Hello!"
```
(when the character name is Alice and the user name is John).

---

## Basic Syntax

### 1. Simple Variables
```
{{variable_name}}
```

### 2. Functions with Arguments
```
{{function_name::arg1::arg2::arg3}}
```
- Arguments are separated by `::` (double colon)
- Some functions support variadic arguments

### 3. Conditionals
```
{{#when condition}}
  Content displayed when condition is true
{{:else}}
  Content displayed when condition is false
{{/when}}
```

### 4. Loops
```
{{#each array as item}}
  {{slot::item}}
{{/each}}
```

---

## CBS Functions by Category

### 📌 1. Basic Character/User Variables

| Function | Alias | Description | Example |
|----------|-------|-------------|---------|
| `{{char}}` | `{{bot}}` | Returns current character/bot name or nickname | `{{char}}` → "Alice" |
| `{{user}}` | - | Returns current user's name | `{{user}}` → "John" |
| `{{personality}}` | `{{charpersona}}` | Returns character's personality field | `{{personality}}` |
| `{{description}}` | `{{chardesc}}` | Returns character's description field | `{{description}}` |
| `{{scenario}}` | - | Returns character's scenario field | `{{scenario}}` |
| `{{exampledialogue}}` | `{{examplemessage}}` | Returns character's example dialogue | `{{exampledialogue}}` |
| `{{persona}}` | `{{userpersona}}` | Returns user persona prompt | `{{persona}}` |

### 📝 2. Prompts and System

| Function | Alias | Description | Example |
|----------|-------|-------------|---------|
| `{{mainprompt}}` | `{{systemprompt}}` | Returns main system prompt | `{{mainprompt}}` |
| `{{jb}}` | `{{jailbreak}}` | Returns jailbreak prompt | `{{jb}}` |
| `{{globalnote}}` | `{{systemnote}}`, `{{ujb}}` | Returns global note | `{{globalnote}}` |
| `{{jbtoggled}}` | - | Whether jailbreak is enabled (1/0) | `{{jbtoggled}}` → "1" |

### 💬 3. Chat History

| Function | Alias | Description | Example |
|----------|-------|-------------|---------|
| `{{history}}` | `{{messages}}` | Returns chat history as JSON array | `{{history}}` |
| `{{history::role}}` | - | Returns history with role prefixes | `{{history::role}}` |
| `{{previouscharchat}}` | `{{lastcharmessage}}` | Returns last character message | `{{previouscharchat}}` |
| `{{previoususerchat}}` | `{{lastusermessage}}` | Returns last user message | `{{previoususerchat}}` |
| `{{userhistory}}` | `{{usermessages}}` | All user messages as JSON array | `{{userhistory}}` |
| `{{charhistory}}` | `{{charmessages}}` | All character messages as JSON array | `{{charhistory}}` |
| `{{lastmessage}}` | - | Content of last message in chat | `{{lastmessage}}` |
| `{{lastmessageid}}` | `{{lastmessageindex}}` | Index of last message | `{{lastmessageid}}` → "42" |
| `{{previouschatlog::N}}` | - | Content of message at index N | `{{previouschatlog::5}}` |

### 🔢 4. Chat Index and Metadata

| Function | Alias | Description | Example |
|----------|-------|-------------|---------|
| `{{chatindex}}` | - | Current message index | `{{chatindex}}` → "10" |
| `{{firstmsgindex}}` | `{{firstmessageindex}}` | Selected first message index | `{{firstmsgindex}}` → "-1" |
| `{{role}}` | - | Role of current message (user/char) | `{{role}}` → "char" |
| `{{isfirstmsg}}` | - | Whether this is first message (1/0) | `{{isfirstmsg}}` → "1" |
| `{{trigger_id}}` | `{{triggerid}}` | ID value of trigger element | `{{trigger_id}}` |

### ⏰ 5. Time and Date

| Function | Alias | Description | Example |
|----------|-------|-------------|---------|
| `{{time}}` | - | Current local time (HH:MM:SS) | `{{time}}` → "14:30:25" |
| `{{isotime}}` | - | Current UTC time (HH:MM:SS) | `{{isotime}}` → "05:30:25" |
| `{{date}}` | - | Date/time format (YYYY-M-D if no args) | `{{date}}` → "2026-1-7" |
| `{{date::YYYY-MM-DD}}` | - | Returns date in custom format | `{{date::YYYY-MM-DD}}` → "2026-01-07" |
| `{{isodate}}` | - | Current UTC date (YYYY-M-D) | `{{isodate}}` → "2026-1-7" |
| `{{unixtime}}` | - | Current Unix timestamp (seconds) | `{{unixtime}}` → "1704672000" |
| `{{messagetime}}` | - | Sent time of current message | `{{messagetime}}` → "14:30:25" |
| `{{messagedate}}` | - | Sent date of current message | `{{messagedate}}` → "1/7/2026" |
| `{{messageunixtimearray}}` | - | Array of all message timestamps | `{{messageunixtimearray}}` |
| `{{idleduration}}` | - | Elapsed time since last message | `{{idleduration}}` → "0:05:30" |
| `{{messageidleduration}}` | - | Elapsed time between user messages | `{{messageidleduration}}` → "0:10:15" |

### 🔤 6. String Manipulation

| Function | Alias | Description | Example |
|----------|-------|-------------|---------|
| `{{replace::text::find::replace}}` | - | Replace all occurrences | `{{replace::Hello::l::L}}` → "HeLLo" |
| `{{split::text::delimiter}}` | - | Split string into array | `{{split::a,b,c::,}}` → ["a","b","c"] |
| `{{join::array::delimiter}}` | - | Join array into string | `{{join::["a","b"]::,}}` → "a,b" |
| `{{trim::text}}` | - | Remove leading/trailing whitespace | `{{trim::  hello  }}` → "hello" |
| `{{length::text}}` | - | String length | `{{length::Hello}}` → "5" |
| `{{lower::text}}` | - | Convert to lowercase | `{{lower::HELLO}}` → "hello" |
| `{{upper::text}}` | - | Convert to uppercase | `{{upper::hello}}` → "HELLO" |
| `{{capitalize::text}}` | - | Capitalize first letter only | `{{capitalize::hello}}` → "Hello" |
| `{{startswith::text::prefix}}` | - | Whether string starts with prefix (1/0) | `{{startswith::hello::he}}` → "1" |
| `{{endswith::text::suffix}}` | - | Whether string ends with suffix (1/0) | `{{endswith::hello::lo}}` → "1" |
| `{{contains::text::substring}}` | - | Whether contains substring (1/0) | `{{contains::hello::ell}}` → "1" |
| `{{reverse::text}}` | - | Reverse string | `{{reverse::hello}}` → "olleh" |

### 🔢 7. Math and Calculations

| Function | Alias | Description | Example |
|----------|-------|-------------|---------|
| `{{calc::expression}}` | - | Calculate math expression | `{{calc::2+2*3}}` → "8" |
| `{{?::expression}}` | - | Math operation (includes comparison) | `{{?::1+2}}` → "3" |
| `{{round::number}}` | - | Round to nearest integer | `{{round::3.7}}` → "4" |
| `{{floor::number}}` | - | Round down | `{{floor::3.9}}` → "3" |
| `{{ceil::number}}` | - | Round up | `{{ceil::3.1}}` → "4" |
| `{{abs::number}}` | - | Absolute value | `{{abs::-5}}` → "5" |
| `{{pow::base::exponent}}` | - | Power/exponentiation | `{{pow::2::3}}` → "8" |
| `{{remaind::number::divisor}}` | - | Remainder (modulo) | `{{remaind::10::3}}` → "1" |
| `{{fixnum::number::decimals}}` | - | Fix decimal places | `{{fixnum::3.14159::2}}` → "3.14" |
| `{{tonumber::text}}` | - | Extract numbers only | `{{tonumber::abc123.45}}` → "123.45" |
| `{{min::val1::val2::...}}` | - | Minimum value | `{{min::5::2::8}}` → "2" |
| `{{max::val1::val2::...}}` | - | Maximum value | `{{max::5::2::8}}` → "8" |
| `{{sum::val1::val2::...}}` | - | Sum of values | `{{sum::1::2::3}}` → "6" |
| `{{average::val1::val2::...}}` | - | Average of values | `{{average::2::4::6}}` → "4" |

### ⚖️ 8. Comparison and Logic Operations

| Function | Alias | Description | Example |
|----------|-------|-------------|---------|
| `{{equal::A::B}}` | - | Whether A equals B (1/0) | `{{equal::hello::hello}}` → "1" |
| `{{notequal::A::B}}` | `{{not_equal}}` | Whether A differs from B (1/0) | `{{notequal::a::b}}` → "1" |
| `{{greater::A::B}}` | - | Whether A is greater than B (1/0) | `{{greater::10::5}}` → "1" |
| `{{less::A::B}}` | - | Whether A is less than B (1/0) | `{{less::5::10}}` → "1" |
| `{{greaterequal::A::B}}` | `{{greater_equal}}` | Whether A is greater than or equal to B (1/0) | `{{greaterequal::10::10}}` → "1" |
| `{{lessequal::A::B}}` | `{{less_equal}}` | Whether A is less than or equal to B (1/0) | `{{lessequal::5::5}}` → "1" |
| `{{and::A::B}}` | - | Logical AND | `{{and::1::1}}` → "1" |
| `{{or::A::B}}` | - | Logical OR | `{{or::1::0}}` → "1" |
| `{{not::A}}` | - | Logical NOT | `{{not::1}}` → "0" |
| `{{all::val1::val2::...}}` | - | Check if all values are 1 | `{{all::1::1::1}}` → "1" |
| `{{any::val1::val2::...}}` | - | Check if any value is 1 | `{{any::0::1::0}}` → "1" |

### 📦 9. Array Manipulation

| Function | Alias | Description | Example |
|----------|-------|-------------|---------|
| `{{makearray::A::B::C}}` | `{{array}}`, `{{a}}` | Create array | `{{makearray::a::b::c}}` → ["a","b","c"] |
| `{{arraylength::array}}` | - | Array length | `{{arraylength::["a","b"]}}` → "2" |
| `{{arrayelement::array::index}}` | - | Access array element | `{{arrayelement::["a","b"]::1}}` → "b" |
| `{{arraypush::array::element}}` | - | Add to end of array | `{{arraypush::["a"]::b}}` → ["a","b"] |
| `{{arraypop::array}}` | - | Remove last element | `{{arraypop::["a","b"]}}` → ["a"] |
| `{{arrayshift::array}}` | - | Remove first element | `{{arrayshift::["a","b"]}}` → ["b"] |
| `{{arraysplice::array::start::count::add}}` | - | Replace array elements | `{{arraysplice::["a","b"]::1::1::x}}` → ["a","x"] |
| `{{arrayassert::array::index::value}}` | - | Set value if index is out of range | `{{arrayassert::["a"]::5::b}}` |
| `{{spread::array}}` | - | Join array with :: | `{{spread::["a","b"]}}` → "a::b" |
| `{{filter::array::type}}` | - | Filter array (all/nonempty/unique) | `{{filter::["a","","a"]::unique}}` → ["a",""] |
| `{{range::[N]}}` | - | Array from 0 to N-1 | `{{range::[5]}}` → [0,1,2,3,4] |
| `{{range::[start,end,step]}}` | - | Generate range array | `{{range::[2,8,2]}}` → [2,4,6] |

### 🗂️ 10. Object/Dictionary Manipulation

| Function | Alias | Description | Example |
|----------|-------|-------------|---------|
| `{{makedict::key1=val1::key2=val2}}` | `{{dict}}`, `{{d}}`, `{{object}}`, `{{o}}` | Create object | `{{makedict::name=John::age=25}}` → {"name":"John","age":"25"} |
| `{{dictelement::object::key}}` | `{{objectelement}}` | Access object value | `{{dictelement::{"name":"John"}::name}}` → "John" |
| `{{objectassert::object::key::value}}` | `{{dictassert}}` | Set key only if not exists | `{{objectassert::{"a":1}::b::2}}` → {"a":1,"b":2} |
| `{{element::JSON::key1::key2...}}` | `{{ele}}` | Access nested elements | `{{element::{"user":{"name":"John"}}::user::name}}` → "John" |

### 💾 11. Variable Management

| Function | Alias | Description | Example |
|----------|-------|-------------|---------|
| `{{getvar::varname}}` | - | Get chat variable | `{{getvar::counter}}` |
| `{{setvar::varname::value}}` | - | Set chat variable | `{{setvar::counter::5}}` |
| `{{addvar::varname::value}}` | - | Add number to chat variable | `{{addvar::counter::1}}` |
| `{{setdefaultvar::varname::value}}` | - | Set variable only if not exists | `{{setdefaultvar::count::0}}` |
| `{{getglobalvar::varname}}` | - | Get global variable | `{{getglobalvar::global_count}}` |
| `{{tempvar::varname}}` | `{{gettempvar}}` | Get temporary variable | `{{tempvar::temp}}` |
| `{{settempvar::varname::value}}` | - | Set temporary variable | `{{settempvar::temp::value}}` |
| `{{return::value}}` | - | Return value from script | `{{return::result}}` |

### 🎲 12. Random and Hash

| Function | Alias | Description | Example |
|----------|-------|-------------|---------|
| `{{random}}` | - | Random number between 0-1 | `{{random}}` → "0.7234" |
| `{{random::A,B,C}}` | - | Random selection | `{{random::apple,banana,cherry}}` → "banana" |
| `{{random::A::B::C}}` | - | Random argument selection | `{{random::yes::no::maybe}}` → "no" |
| `{{pick::A,B,C}}` | - | Hash-based random selection (consistent) | `{{pick::a,b,c}}` → "b" |
| `{{randint::min::max}}` | - | Random integer in range | `{{randint::1::10}}` → "7" |
| `{{dice::XdY}}` | - | Roll dice | `{{dice::2d6}}` → "9" |
| `{{roll::XdY}}` | - | Roll dice (default 1d6) | `{{roll::20}}` → "15" |
| `{{rollp::XdY}}` | - | Hash-based dice (consistent) | `{{rollp::2d6}}` → "7" |
| `{{hash::string}}` | - | String hash (7-digit number) | `{{hash::hello}}` → "1234567" |

### 🔐 13. Encryption/Encoding

| Function | Alias | Description | Example |
|----------|-------|-------------|---------|
| `{{xor::text}}` | `{{xorencrypt}}`, `{{xore}}` | XOR encryption (base64) | `{{xor::hello}}` |
| `{{xordecrypt::ciphertext}}` | `{{xordecode}}`, `{{xord}}` | XOR decryption | `{{xordecrypt::base64}}` |
| `{{crypt::text}}` | `{{encrypt}}`, `{{decrypt}}`, `{{caesar}}` | Caesar cipher (default 32768) | `{{crypt::hello}}` |
| `{{crypt::text::shift}}` | - | Custom shift Caesar cipher | `{{crypt::hello::1000}}` |
| `{{unicodeencode::char::index}}` | - | Unicode code point | `{{unicodeencode::A}}` → "65" |
| `{{unicodedecode::code}}` | - | Convert code to character | `{{unicodedecode::65}}` → "A" |
| `{{u::hex}}` | - | Hex unicode to character | `{{u::41}}` → "A" |
| `{{fromhex::hex}}` | - | Hex to decimal | `{{fromhex::FF}}` → "255" |
| `{{tohex::decimal}}` | - | Decimal to hex | `{{tohex::255}}` → "ff" |

### 🎨 14. UI and Display

| Function | Alias | Description | Example |
|----------|-------|-------------|---------|
| `{{button::text::trigger}}` | - | Create button | `{{button::Click Me::do_something}}` |
| `{{risu}}` | - | Display RisuAI logo (45px) | `{{risu}}` |
| `{{risu::size}}` | - | Display logo with specified size | `{{risu::60}}` |
| `{{br}}` | `{{newline}}` | Newline character | `{{br}}` → "\n" |
| `{{cbr}}` | `{{cnl}}` | Escaped newline | `{{cbr}}` → "\\n" |
| `{{cbr::N}}` | - | Repeat N times | `{{cbr::3}}` |
| `{{emotion::name}}` | - | Display emotion image | `{{emotion::happy}}` |
| `{{asset::name}}` | - | Display asset | `{{asset::background1}}` |
| `{{image::name}}` | - | Display image | `{{image::pic1}}` |
| `{{audio::name}}` | - | Play audio | `{{audio::bgm}}` |
| `{{video::name}}` | - | Display video | `{{video::intro}}` |
| `{{bg::name}}` | - | Set background image | `{{bg::forest}}` |
| `{{comment::text}}` | - | Displayed comment | `{{comment::This is a comment}}` |
| `{{tex::formula}}` | `{{latex}}`, `{{katex}}` | Render LaTeX formula | `{{tex::E=mc^2}}` |
| `{{ruby::text::ruby}}` | `{{furigana}}` | Ruby text (furigana) | `{{ruby::漢字::かんじ}}` |
| `{{codeblock::code}}` | - | Display code block | `{{codeblock::console.log("hi")}}` |
| `{{codeblock::language::code}}` | - | Code block with language | `{{codeblock::js::console.log("hi")}}` |

### 📚 15. Lorebook and Modules

| Function | Alias | Description | Example |
|----------|-------|-------------|---------|
| `{{lorebook}}` | `{{worldinfo}}` | Active lorebook JSON array | `{{lorebook}}` |
| `{{moduleenabled::namespace}}` | - | Whether module is enabled (1/0) | `{{moduleenabled::mymod}}` → "1" |
| `{{moduleassetlist::namespace}}` | - | Module asset list | `{{moduleassetlist::mymod}}` |
| `{{emotionlist}}` | - | Emotion image list | `{{emotionlist}}` |
| `{{assetlist}}` | - | Character asset list | `{{assetlist}}` |
| `{{chardisplayasset}}` | - | Display asset list (filtered) | `{{chardisplayasset}}` |

### ⚙️ 16. System and Metadata

| Function | Alias | Description | Example |
|----------|-------|-------------|---------|
| `{{model}}` | - | Current AI model ID | `{{model}}` → "gpt-4" |
| `{{axmodel}}` | - | Sub-model ID | `{{axmodel}}` |
| `{{maxcontext}}` | - | Maximum context length | `{{maxcontext}}` → "8192" |
| `{{metadata::key}}` | - | System metadata | `{{metadata::version}}` → "1.95" |
| `{{metadata::mobile}}` | - | Whether mobile (1/0) | `{{metadata::mobile}}` → "0" |
| `{{metadata::local}}` | - | Whether local app (1/0) | `{{metadata::local}}` → "1" |
| `{{metadata::language}}` | - | Settings language | `{{metadata::language}}` → "ko" |
| `{{metadata::modelname}}` | - | Full model name | `{{metadata::modelname}}` → "GPT-4" |
| `{{prefillsupported}}` | - | Whether prefill is supported (1/0) | `{{prefillsupported}}` → "1" |
| `{{screenwidth}}` | - | Screen width (pixels) | `{{screenwidth}}` → "1920" |
| `{{screenheight}}` | - | Screen height (pixels) | `{{screenheight}}` → "1080" |
| `{{iserror::text}}` | - | Check if error message (1/0) | `{{iserror::Error: failed}}` → "1" |

### 🔧 17. Special Functions

| Function | Alias | Description | Example |
|----------|-------|-------------|---------|
| `{{blank}}` | `{{none}}` | Return empty string | `{{blank}}` → "" |
| `{{file::filename::base64}}` | - | Display/decode file | `{{file::doc.txt::base64data}}` |
| `{{hiddenkey::key}}` | - | Hidden key for lorebook activation | `{{hiddenkey::secret}}` |
| `{{bkspc}}` | - | Backspace last word | `hello world {{bkspc}}` → "hello" |
| `{{erase}}` | - | Delete last sentence | `Hi. Bye. {{erase}}` → "Hi." |
| `{{position::name}}` | - | Define position | `{{position::top}}` |
| `{{source::user}}` | - | User profile URL | `{{source::user}}` |
| `{{source::char}}` | - | Character profile URL | `{{source::char}}` |

### 🔣 18. Escape Characters

| Function | Alias | Description | Output |
|----------|-------|-------------|--------|
| `{{decbo}}` | - | Display { | { |
| `{{decbc}}` | - | Display } | } |
| `{{bo}}` | `{{ddecbo}}` | Display {{ | {{ |
| `{{bc}}` | `{{ddecbc}}` | Display }} | }} |
| `{{(}}` | `{{debo}}` | Display ( | ( |
| `{{)}}` | `{{debc}}` | Display ) | ) |
| `{{<}}` | `{{deabo}}` | Display < | < |
| `{{>}}` | `{{deabc}}` | Display > | > |
| `{{:}}` | `{{dec}}` | Display : | : |
| `{{;}}` | - | Display ; | ; |

### 🔀 19. Control Structures

| Function | Alias | Description | Example |
|----------|-------|-------------|---------|
| `{{#when condition}}...{{/when}}` | - | Basic conditional | `{{#when 1}}true{{/when}}` |
| `{{#when::A::and::B}}` | - | AND condition | `{{#when::1::and::1}}true{{/when}}` |
| `{{#when::A::or::B}}` | - | OR condition | `{{#when::1::or::0}}true{{/when}}` |
| `{{#when::A::is::B}}` | - | Equality comparison | `{{#when::5::is::5}}true{{/when}}` |
| `{{#when::A::isnot::B}}` | - | Inequality comparison | `{{#when::a::isnot::b}}true{{/when}}` |
| `{{#when::A::>::B}}` | - | Greater than comparison | `{{#when::10::>::5}}true{{/when}}` |
| `{{#when::A::<::B}}` | - | Less than comparison | `{{#when::5::<::10}}true{{/when}}` |
| `{{#when::not::A}}` | - | NOT condition | `{{#when::not::0}}true{{/when}}` |
| `{{:else}}` | - | Else clause | `{{#when 0}}{{:else}}false{{/when}}` |
| `{{#each array as variable}}` | - | Array iteration | `{{#each items as item}}{{slot::item}}{{/each}}` |
| `{{#puredisplay}}...{{/puredisplay}}` | - | Display without CBS parsing | `{{#puredisplay}}{{char}}{{/puredisplay}}` → "{{char}}" |
| `{{//::comment}}` | - | Comment (not displayed) | `{{//::this is a comment}}` |
| `{{slot}}` | - | Slot access | `{{slot}}` |
| `{{slot::property}}` | - | Slot property access | `{{slot::value}}` |

---

## Detailed Reference

### #when Conditional Operators

`{{#when}}` is the most powerful conditional feature in RisuAI.

#### Basic Usage
```
{{#when condition}}
  When condition is true
{{:else}}
  When condition is false
{{/when}}
```

#### Comparison Operators
- `::is::` - Equal (==)
- `::isnot::` - Not equal (!=)
- `::>::` - Greater than (>)
- `::<::` - Less than (<)
- `::>=::` - Greater than or equal (>=)
- `::<=::` - Less than or equal (<=)

#### Logical Operators
- `::and::` - AND
- `::or::` - OR
- `::not::` - NOT

#### Advanced Operators
- `::keep::` - Preserve whitespace
- `::legacy::` - Legacy whitespace handling
- `::var::` - Check if variable is truthy
- `::toggle::` - Check toggle activation

#### Examples
```
{{#when::{{getvar::score}}::>::50}}
  Score is 50 or above!
{{:else}}
  Score is below 50.
{{/when}}

{{#when::{{equal::{{user}}::Admin}}::and::{{jbtoggled}}}}
  Is admin and jailbreak is enabled
{{/when}}
```

### #each Loop

Iterates through an array and performs operations on each element.

```
{{#each {{userhistory}} as message}}
  Message: {{slot::message}}
{{/each}}
```

#### With keep Operator
```
{{#each::keep myArray as item}}
  {{slot::item}}
{{/each}}
```

### Nested Structure Example

```
{{#when::{{getvar::mode}}::is::debug}}
  Debug mode enabled
  {{#each {{lorebook}} as entry}}
    Lore: {{slot::entry}}
  {{/each}}
{{:else}}
  Normal mode
{{/when}}
```

---

## Examples and Use Cases

### Example 1: Dynamic Greeting
```
{{#when::{{time}}::<::12}}
  Good morning, {{user}}!
{{:else}}
  {{#when::{{time}}::<::18}}
    Good afternoon, {{user}}!
  {{:else}}
    Good evening, {{user}}!
  {{/when}}
{{/when}}
```

### Example 2: Random Reactions
```
{{char}} said {{random::with a laugh,with a smile,with surprise,with joy}}: "{{random::Hello!,Nice to meet you!,Welcome!}}"
```

### Example 3: Counter System
```
{{setdefaultvar::visit_count::0}}
{{addvar::visit_count::1}}
Visit count: {{getvar::visit_count}}

{{#when::{{getvar::visit_count}}::>::10}}
  Wow, this is already your {{getvar::visit_count}}th visit!
{{/when}}
```

### Example 4: Complex Profile Display
```
Character Profile:
---
Name: {{char}}
Personality: {{personality}}
Scenario: {{scenario}}

{{#when::{{emotionlist}}}}
Available Emotions:
{{#each {{emotionlist}} as emotion}}
  - {{slot::emotion}}
{{/each}}
{{/when}}
```

### Example 5: Conditional UI
```
{{#when::{{metadata::mobile}}::is::1}}
  {{button::Mobile Version::switch_to_mobile}}
{{:else}}
  {{button::Desktop Version::switch_to_desktop}}
{{/when}}

Current screen: {{screenwidth}}x{{screenheight}}
```

### Example 6: Dice Game
```
{{char}}: "Shall we roll the dice?"
{{setvar::dice_roll::{{dice::2d6}}}}
Result: {{getvar::dice_roll}}

{{#when::{{getvar::dice_roll}}::>::10}}
  Critical success!
{{:else}}
  {{#when::{{getvar::dice_roll}}::<::4}}
    Critical failure!
  {{:else}}
    Normal result
  {{/when}}
{{/when}}
```

### Example 7: Chat Statistics
```
Total messages: {{lastmessageid}}
Last activity: {{idleduration}} ago

{{#when::{{arraylength::{{userhistory}}}}::>::{{arraylength::{{charhistory}}}}}}
  {{user}} has talked more!
{{:else}}
  {{char}} is more talkative!
{{/when}}
```

### Example 8: Date/Time Formatting
```
Current time: {{date::YYYY-MM-DD HH:mm:ss}}
UTC time: {{isotime}}
Unix time: {{unixtime}}

{{#when::{{time}}::>::22}}
  It's getting late. How about getting some rest?
{{/when}}
```

### Example 9: Array and Object Manipulation
```
{{setvar::items::{{makearray::apple::banana::cherry}}}}
Fruit list: {{join::{{getvar::items}}::, }}
First fruit: {{arrayelement::{{getvar::items}}::0}}

{{setvar::user_data::{{makedict::name={{user}}::level=5::hp=100}}}}
Player name: {{dictelement::{{getvar::user_data}}::name}}
Level: {{dictelement::{{getvar::user_data}}::level}}
```

### Example 10: Encryption Example
```
Original message: "Secret message"
Encrypted: {{xor::Secret message}}
Decrypted: {{xordecrypt::{{xor::Secret message}}}}

Caesar cipher: {{crypt::hello::3}}
```

---

## Important Notes and Tips

### ⚠️ Important Notes

1. **Argument Separator**: Function arguments must be separated by `::` (double colon). `;` (semicolon) or `:` (single colon) will not work.

2. **Special Character Escaping**: To display special characters within CBS, use escape functions:
   ```
   {{bo}}char{{bc}} → {{char}} (actual display)
   ```

3. **Variable Execution Mode**: `{{setvar}}`, `{{addvar}}`, etc. only execute in `runVar` mode. They may not work in some contexts.

4. **Array/Object Format**: Arrays and objects must be in valid JSON format:
   ```
   Correct: ["a","b","c"]
   Wrong: ['a','b','c']
   ```

5. **Conditional Whitespace**: Whitespace may be automatically removed within `{{#when}}` blocks. Use the `::keep::` operator to preserve whitespace.

### 💡 Tips

1. **Debugging**: To check variable values, just output them:
   ```
   Debug: current counter = {{getvar::counter}}
   ```

2. **Nested Conditionals**: You can nest conditionals for complex logic.

3. **pick vs random**: Use `{{pick}}` for consistent results, `{{random}}` for different results each time.

4. **Metadata Usage**: You can check various system information with `{{metadata}}`:
   ```
   {{metadata::imateapot}} → 🫖
   ```

5. **Performance**: Complex CBS can impact performance. Use only when necessary.

---

## Version Information

This document was created by directly analyzing RisuAI's `src/ts/cbs.ts` file (2482 lines).

- **Analysis Date**: 2026-01-07
- **Total CBS Functions**: 150+
- **Categories**: 19

---

## References

- RisuAI GitHub: https://github.com/kwaroran/RisuAI
- Official Plugin Documentation: `plugins.md`
- Agent Documentation: `AGENTS.md`

---

**Documentation**: AI Analysis (Direct Code Exploration)  
**License**: Follows RisuAI project license
