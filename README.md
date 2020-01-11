# knuffimap

An abstraction over `package:firebase_database`.
It provides three things:

1. An adapter to turn Firebase references into a `Stream<KnuffiMap<T>>`. This automates mapping JSON to objects and works
   nicely with deserialization via `package:built_value`. See [knuffimap](lib/knuffimap.dart).
2. An in-memory database implementation for tests. See [in_memory](lib/in_memory). 
3. A collection of `Widget`s to rebuild whenever dependent `Stream`s change.
   This is similar to [StreamBuilder](https://api.flutter.dev/flutter/widgets/StreamBuilder-class.html), but simpler,
   more limited and allows multiple dependent streams. See [stream_widget.dart](lib/stream_widget.dart).
