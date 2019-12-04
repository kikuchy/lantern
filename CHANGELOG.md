## 0.0.2

- Omit Firestore rule file generation.
- Supports `file` and `struct<>`
    - `file` expresses the file uploaded on Cloud Storage, based on [`File`](https://github.com/1amageek/Ballcap-iOS#file) of [Ballcap-iOS](https://github.com/1amageek/Ballcap-iOS).
    - `struct<>` expressed the struct of specified Document.
- Breaking changes of `DocumentSnapshot` returned from `DocumentReference` on generated Dart file.

## 0.0.1

- Initial version, dart/swift/rule generating
