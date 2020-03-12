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
* Dart (depends on [flamingo](https://pub.dev/packages/flamingo))
* TypeScript (depends on [ballcap.ts](https://github.com/1amageek/ballcap.ts))
* ~~Security rule file for Firestore~~

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
    string                      name
    boolean                     isAdult
    integer                     level
    number                      score
    url                         blogUrl
    array<string>               appeals
    map                         history
    timestamp                   birthday
    geopoint                    lastUsedFrom
    enum Rank {free, purchased} memberRank
    enum<Rank>                  anotherRank
    reference<DocumentName>     relatedDocument
    struct<DocumentName>        embeddedDocument
    struct S { string a }       embeddedStruct
```

|Lantern Type|Firestore Type|Swift Type|Dart type|TypeScript Type|
|:---:|:---:|:---:|:---:|:---:|
|`string`|`string`|`String`|`String`|`string`|
|`boolean`|`boolean`|`Bool`|`bool`|`boolean`|
|`integer`|`number`|`Int`|`int`|`number`|
|`number`|`number`|`Double`|`double`|`number`|
|`url`|`string`|`URL`|`Uri`|`string`|
|`array<T>`|`array`|`[T]`|`List<T>`|`[T]`|
|`map`|`map`|`[String : Any]`|`Map<String, dynamic>`|`{}`|
|`timestamp`|`timestamp`|`Timestamp`|`Timestamp`|`Timestamp`|
|`geopoint`|`geopoint`|`GeoPoint`|`GeoPoint`|`GeoPoint`|
|`reference<T>`|`reference`|`Document<T>`|`TDocument` (Document referencing class will be generated)|`DocumentRefernce`| 
|`struct<T>`|`map`|`T` (T should be Codable)|`T` (Document)|`T` (Document)|
|`file`|`map` (file will be uploaded to Cloud Storage)|`File`|`StorageFile`|`File`|
|`enum{elements...}`|`string`|`enum` (enum classes will be generated)|`enum`(enum classes will be generated)|`enum`(const enum of string will be generated)|
|`enum<T>`|`string`| `T` (T should be enum) |`T` (T should be enum) |`T` (T should be enum) |
|`struct S {fields...}`|`map`|`S` (Codable class will be generated)|`SModel` (Model class will be generated)|`S` (interface will be generated)|
