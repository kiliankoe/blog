+++
date = "2021-08-31"
title = "Decoding Unknown Data with Codable"
slug = "decoding-unknown-data-with-codable"
+++

A friend recently asked me how to decode the following JSON through Swift's `Codable` type.

```js
{
  "a": 1,
  "b": "foobar",
  "option.extra": {
    "a": 1
  },
  "option.extra.more": 4
}
```

The problem is that only the first two keys (`a` and `b`) are guaranteed to exist, anything aside from that (here everything prefixed with `option`) is extra and unknown at compile-time. Unknown keys should not be discarded however, they should be decoded into a dictionary for later use, we want a type like this.

```swift
struct Json {
  var a: Int
  var b: String
  var extraOptions: [String: ?]
}
```

It's a bit unclear what type to use for `extraOptions`, since we don't really know what the values are. They can be anything, as long as it's decodable. The folks at [Flight School](https://flight.school) have a fantastic package for us to facilitate that conveniently called [AnyCodable](https://github.com/flight-school/anycodable), which provides type-erased wrappers for `Encodable`, `Decodable`, and `Codable` values. We can use that to represent the requirement of having *anything*, as long as it's decodable, by defining the type as follows.

```swift
struct Json {
  var a: Int
  var b: String
  var extraOptions: [String: AnyDecodable]
}
```

As it stands we're getting the automatically synthesized implementation of `Json`'s initializer, which will try to find a dictionary called `extraOptions` in the source JSON, which obviously isn't present. We'll have to implement the initializer ourselves. Doing so will also require us to define a type conforming to `CodingKey`, which we can use to specify the encoded keys in our source data.

```swift
extension Json: Decodable {
  private enum CodingKeys: CodingKey {
    case a, b
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.a = try container.decode(Int.self, forKey: .a)
    self.b = try container.decode(String.self, forKey: .b)
    self.extraOptions = [:]
  }
}
```

We've now run into the problem of somehow having to specify all keys in our `CodingKeys` enum, which obviously doesn't help for unknown keys. What we can do though is to use the `CodingKey` protocol to create our own *dynamic* key handling type, which can handle any `String` as a key.

```swift
struct DynamicCodingKeys: CodingKey {
  var stringValue: String
  init?(stringValue: String) {
    self.stringValue = stringValue
  }

  // not used here, but a protocol requirement
  var intValue: Int?
  init?(intValue: Int) {
    return nil
  }
}
```

While we could use this entirely instead of our previous implementation, I personally find it quite a bit cleaner to keep the existing `CodingKeys` for known keys, but cover everything else with the `DynamicCodingKeys`. Creating a new container from our decoder keyed with `DynamicCodingKeys` however will give us a container containing *all* keys, not just the extra ones, so we'll have to filter out those we've already taken care of, leaving us with something like this.

```swift
extension Json: Decodable {
  private enum KnownCodingKeys: CodingKey, CaseIterable {
    case a, b

    static func doesNotContain(_ key: Json.DynamicCodingKeys) -> Bool {
      !Self.allCases.map(\.stringValue).contains(key.stringValue)
    }
  }

  struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    init?(stringValue: String) {
      self.stringValue = stringValue
    }

    // not used here, but a protocol requirement
    var intValue: Int?
    init?(intValue: Int) {
      return nil
    }
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: KnownCodingKeys.self)
    self.a = try container.decode(Int.self, forKey: .a)
    self.b = try container.decode(String.self, forKey: .b)

    self.extraOptions = [:]
    let extraContainer = try decoder.container(keyedBy: DynamicCodingKeys.self)

    for key in extraContainer.allKeys where KnownCodingKeys.doesNotContain(key) {
      let decoded = try extraContainer.decode(AnyDecodable.self, forKey: DynamicCodingKey(stringValue: key.stringValue)!)
      self.extraOptions[key.stringValue] = decoded
    }
  }
}
```

The static function `KnownCodingKeys.doesNotContain(_:)` is totally not necessary, but it makes the loop in the initializer nicer to read.

When trying to run this, we see that it works as intended!

```swift
let json = """
{
  "a": 1,
  "b": "foobar",
  "option.extra": {
    "a": 1
  },
  "option.extra.more": 4
}
""".data(using: .utf8)!

let decoded = try JSONDecoder().decode(Json.self, from: json)
print(decoded)
```

```swift
Json(
  a: 1,
  b: "foobar",
  extraOptions: [
    "option.extra": AnyDecodable(["a": 1]),
    "option.extra.more": AnyDecodable(4)
  ]
)
```

That's it, cya for the next blog post in - *check's watch* - three years 😅
