# Lantern 🔆

Firebase Cloud Firestore's data structure definition language and code generator.
Lantern lights bright future of your project. 

## Features

### Definition Language

Have you ever been confused sharing collections / document structure in team?
Or forgetting the structure by your self?

No problem. Lantern is simple data structure definition language to write down your Firestore structure.

It's easy to lean, to read, to use.

```
collection users {
    document User {
        string name
        array<string> attributes
        timestamp lastLogined

        collection tweets {
            document Tweet {
                string body
                reference<Tweet> referring
            }
        }
    }
}
```

### Code Generation Toolkit

Is hard for you that writing both code for iOS and Android?
Have you ever mistook spelling between source code and security rule? 

Lantern has code generation toolkit. You can concentrate to using defined data structure.
It can provide code for ...

* Swift (depends on [Ballcap-iOS](https://github.com/1amageek/Ballcap-iOS))
* Dart
* Security rule file for Firestore

## Install

```
$ pub global activate lantern
```

## Usage

```
$ lantern <your_definition_file>
```

## Grammar

### `collection`

```
collection nameOfCollection(autoId = true) {
    ...
}
```

`collection` must have name and just one document.
Parameters are optional.

### `document`

```
document NameOfDocument(saveCreatedDate = true) {
    ...
}
```

`document` have name and parameters (optional).
And have fields and `collection`s in body.

### Fields and Types

```
    string                  name
    boolean                 isAdult
    integer                 level
    number                  score
    url                     blogUrl
    array<string>           appeals
    map                     history
    timestamp               birthday
    geopoint                lastUsedFrom
    reference<DocumentName> relatedDocument
```

|Lantern Type|Firestore Type|Swift Type|Dart type|
|:---:|:---:|:---:|:---:|
|`string`|`string`|`String`|`String`|
|`boolean`|`boolean`|`Bool`|`bool`|
|`integer`|`number`|`Int`|`int`|
|`number`|`number`|`Double`|`double`|
|`url`|`string`|`URL`|`Uri`|
|`array<T>`|`array`|`[T]`|`List<T>`|
|`map`|`map`|`[String : Any]`|`Map<String, dynamic>`|
|`timestamp`|`timestamp`|`Timestamp`|`DateTime`|
|`geopoint`|`geopoint`|`GeoPoint`|`Point`|
|`reference<T>`|`reference`|`Document<T>`|`TDocument` (Document referencing class will be generated)| 
|`struct<T>`|`map`|`T` (T should be Codable)|`T` (Document)|
|`file`|`map` (file will be uploaded to Cloud Storage)|`File`|`FireReference`|
