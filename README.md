# ApiModel

Interact with REST apis using realm.io to represent objects. The goal of `ApiModel` is to be easy to setup, easy to grasp, and fun to use. Boilerplate should be kept to a minimum, and also intuitive to set up.

This project is very much inspired by [@idlefingers'](https://github.com/idlefingers) excellent [api-model](https://github.com/izettle/api-model).

## Getting started

Add `APIModel` to your `Podfile`, and run `pod install`:

```ruby
pod 'APIModel', '~> 0.10.1'
```

The key part is to implement the `ApiModel` protocol.

```swift
import RealmSwift
import ApiModel

class Post: Object, ApiModel {
// Standard Realm boilerplate
dynamic var id = ""
dynamic var title = ""
dynamic var contents = ""
dynamic lazy var createdAt = NSDate()

override class func primaryKey() -> String {
return "id"
}

// Define the standard namespace this class usually resides in JSON responses
// MUST BE singular ie `post` not `posts`
class func apiNamespace() -> String {
return "post"
}

// Define where and how to get these. Routes are assumed to use Rails style REST (index, show, update, destroy)
class func apiRoutes() -> ApiRoutes {
return ApiRoutes(
index: "/posts.json",
show: "/post/:id:.json"
)
}

// Define how it is converted from JSON responses into Realm objects. A host of transforms are available
// See section "Transforms" in README. They are super easy to create as well!
class func fromJSONMapping() -> JSONMapping {
return [
"id": ApiIdTransform(),
"title": StringTransform(),
"contents": StringTransform(),
"createdAt": NSDateTransform()
]
}

// Define how this object is to be serialized back into a server response format
func JSONDictionary() -> [String:AnyObject] {
return [
"id": id,
"title": email,
"contents": contents,
"created_at": createdAt
]
}
}
```

## Table of Contents

* [ApiModel](#apimodel)
* [Getting started](#getting-started)
* [Table of Contents](#table-of-contents)
* [Configuring the API](#configuring-the-api)
* [Global and Model-local configurations](#global-and-model-local-configurations)
* [Interacting with APIs](#interacting-with-apis)
* [Basic REST verbs](#basic-rest-verbs)
* [Fetching objects](#fetching-objects)
* [Storing objects](#storing-objects)
* [Transforms](#transforms)
* [Hooks](#hooks)
* [URLs](#urls)
* [Dealing with IDs](#dealing-with-ids)
* [Namespaces and envelopes](#namespaces-and-envelopes)
* [Caching and storage](#caching-and-storage)
* [File uploads](#file-uploads)
* [FileUpload](#fileupload)
* [Thanks to](#thanks-to)
* [License](#license)

## Configuring the API

To represent the API itself, you have to create an object of the `ApiManager` class. This holds a `ApiConfiguration` object defining the host URL for all requests. After it has been created it can be accessed from the `func apiManager() -> ApiManager` singleton function.

To set it up:

```
// Put this somewhere in your AppDelegate or together with other initialization code
var apiConfig = ApiConfig(host: "https://service.io/api/v1/")

ApiSingleton.setInstance(ApiManager(configuration: apiConfig))
```

If you would like to disable request logging, you can do so by setting `requestLogging` to `false`:

```swift
apiConfig.requestLogging = false
```

### Global and Model-local configurations

For the most part an API is consistent across endpoints, however in the real world, conventions usually differ wildly. The global configuration is the one set by calling `ApiSingleton.setInstance(ApiManager(configuration: apiConfig))`.

To have a model-local configuration a model needs to implement the `ApiConfigurable` protocol, which consists of a single method:

```swift
public protocol ApiConfigurable {
static func apiConfig(config: ApiConfig) -> ApiConfig
}
```

Input is the root base configuration and output is the model's own config object. The object passed in is a copy of the root configuration, so you are free to modify that object without any side-effects.

```swift
static func apiConfig(config: ApiConfig) -> ApiConfig {
config.encoding = ApiRequest.FormDataEncoding
return config
}
```

### Realm Insert-or-update Realm().add(_:update:):

If you'd like to utilize Realm's add/update functionality add the following to your model.

```swift
var insertOrUpdate: Bool? { return true }
```

This comes in handy if you have nested models in your json and those nested models exist in realm.  You may need these if a fatal exception occurs that looks something like

```
*** Terminating app due to uncaught exception 'RLMException', reason: 'Can't set primary key property 'id' to existing value '40'.'
```

## Interacting with APIs

The base of `ApiModel` is the `Api` wrapper class. This class wraps an `Object` type and takes care of fetching objects, saving objects and dealing with validation errors.

### Basic REST verbs

`ApiModel` supports querying API's using basic HTTP verbs.

```swift
// GET call without parameters
Api<Post>.get("/v1/posts.json") { response in
println("response.isSuccessful: \(response.isSuccessful)")
println("Response as an array: \(response.array)")
println("Response as a dictionary: \(response.dictionary)")
println("Response errors?: \(response.errors)")
}

// Other supported methods:

Api<Post>.get(path, parameters: [String:AnyObject]) { response // ...
Api<Post>.post(path, parameters: [String:AnyObject]) { response // ...
Api<Post>.put(path, parameters: [String:AnyObject]) { response // ...
Api<Post>.delete(path, parameters: [String:AnyObject]) { response // ...

// no parameters

Api<Post>.get(path) { response // ...
Api<Post>.post(path) { response // ...
Api<Post>.put(path) { response // ...
Api<Post>.delete(path) { response // ...

// You can also pass in custom `ApiConfig` into each of the above mentioned methods:
Api<Post>.get(path, parameters: [String:AnyObject], apiConfig: ApiConfig) { response // ...
Api<Post>.post(path, parameters: [String:AnyObject], apiConfig: ApiConfig) { response // ...
Api<Post>.put(path, parameters: [String:AnyObject], apiConfig: ApiConfig) { response // ...
Api<Post>.delete(path, parameters: [String:AnyObject], apiConfig: ApiConfig) { response // ...
```

Most of the time you'll want to use the `ActiveRecord`-style verbs `index/show/create/update` for interacting with a REST API, as described below.

### Fetching objects

Using the `index` of a REST resource:

`GET /posts.json`
```swift
Api<Post>.findArray { posts, apiModelResponse in
if apiModelResponse.hasInternalServerError {
if let errorMessages = apiModelResponse.serverErrorMessages {
for message in errorMessages {
print("server error: \(message)")
}
}
}else {
for post in posts {
print("... \(post.title)")
}
}
}
```

Using the `show` of a REST resource:

`GET /user.json`
```swift
Api<User>.find { userResponse, apiModelResponse in
if apiModelResponse.hasInternalServerError {
if let errorMessages = apiModelResponse.serverErrorMessages {
for message in errorMessages {
print("server error: \(message)")
}
}
} else if let user = userResponse {
print("User is: \(user.email)")
else {
print("Error loading user")
}
}
```

### Storing objects

```swift
var post = Post()
post.title = "Hello world - A prologue"
post.contents = "Hello!"
post.createdAt = NSDate()

var form = Api<Post>(model: post)
form.save { apiModelResponse in
if apiModelResponse.hasInternalServerError {
if let errorMessages = apiModelResponse.serverErrorMessages {
for message in errorMessages {
print("server error: \(message)")
}
}
}else if apiModelResponse.hasValidationErrors{
if let errorMessages = apiModelResponse.validationErrorMessages {
for message in errorMessages {
print("validation error: \(message)")
}
}
} else{
print("Saved! Post #\(post.id)")
}
}
```

`Api` will know that the object is not persisted, since it does not have an `id`  set (or which ever field is defined as `primaryKey` in Realm). So a `POST` request will be made as follows:

`POST /posts.json`
```json
{
"post": {
"title": "Hello world - A prologue",
"contents": "Hello!",
"created_at": "2015-03-08T14:19:31-01:00"
}
}
```

If the response is successful, the attributes returned by the server will be updated on the model.

`200 OK`
```json
{
"post": {
"id": 1
}
}
```

The errors are expected to be in the format:

`422 Unprocessable Entity`
```json
{
"post": {
"errors": {
"contents": [
"must be longer than 140 characters"
]
}
}
}
```

And this will make it possible to access the errors as follows:

```swift
apiModelResponse.validationErrors["contents"] // -> [String]
// or
apiModelResponse.validationErrorMessages // -> [String]
```
`500 Errors` Will populate the apiModelResponse.serverError property, which is of type AnyObject, so you can handle as you'd like or if the 500 json response is formatted as an array of dictionaries the apiModelResponse.serverErrorMessages will be populated just like validationErrorMessages.

## Transforms

Transforms are used to convert attributes from JSON responses to rich types. The easiest way to explain is to show a simple transform.

`ApiModel` comes with a host of standard transforms. An example is the `IntTransform`:

```swift
class IntTransform: Transform {
func perform(value: AnyObject?) -> AnyObject {
if let asInt = value?.integerValue {
return asInt
} else {
return 0
}
}
}
```

This takes an object and attempts to convert it into an integer. If that fails, it returns the default value 0.

Transforms can be quite complex, and even convert nested models. For example:

```swift
class User: Object, ApiModel {
dynamic var id = ApiId()
dynamic var email = ""
let posts = List<Post>()

static func fromJSONMapping() -> JSONMapping {
return [
"posts": ArrayTransform<Post>()
]
}
}

Api<User>.find { user, apiModelResponse in
println("User: \(user.email)")
for post in user.posts {
println("\(post.title)")
}
}
```

Default transforms are:

- StringTransform
- IntTransform
- FloatTransform
- DoubleTransform
- BoolTransform
- NSDateTransform
- ModelTransform
- ArrayTransform
- PercentageTransform

However, it is really easy to define your own. Go nuts!

#### NSDateTransform

Date and time parsing is always a bit complex and has a lot of subtle nuances. The `NSDateTransform` takes a string and tries to convert it into an `NSDate` object. If it can't it returns `nil`.

Dates come in plenty of different formats. The default format `ApiModel` and `NSDateTransform` uses is called [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601)

```swift
class Post: Object, APIModel {
class func fromJSONMapping() -> JSONMapping {
return [
"createdAt": NSDateTransform()
]
}
}

// Example of a valid string:
// "2015-12-30T12:12:33.000Z"
```

In the real world you will come across many wildly different date formats and many APIs will have different opinions on how to represent a date. Therefor you can also pass in a custom format string into `NSDateTransform`:

```swift
class Post: Object, APIModel {
class func fromJSONMapping() -> JSONMapping {
return [
"createdAt": NSDateTransform(dateFormat: "yyyy-MM-dd")
]
}
}

// Example of a valid string:
// "2015-12-30"
```

[For a complete reference on date format specifiers, visit the unicode reference.](http://unicode.org/reports/tr35/tr35-6.html#Date_Format_Patterns)

##### A note on time zones

Internally `NSDate` stores the date as seconds from a specific reference date. That means it will not store any information about the time zone, __even if one is provided by the date string__. For example, let's assume this string is returned from the API: `2015-12-30T18:12:33.000-05:00`. `NSDate` only uses the provided offset to offset the resulting time correctly, then it is thrown away.

What you need to do as an app developer is to make sure to always pass in the correct time zone when you wish to display the timestamp. Normally using an `NSDateFormatter`. By default `NSDateFormatter` uses the user time zone, so you should never need to worry about that. Check the following example for reference:

```swift
let dateString = "2015-12-30T18:12:33.000-05:00"

// Parse as ISO 8601
let dateFormatter = NSDateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

let date = dateFormatter.dateFromString(dateString)!

let outputFormatter = NSDateFormatter()
outputFormatter.dateFormat = "yyyy-MM-dd HH:mm"

// prints "2015-12-30 23:12"
outputFormatter.timeZone = NSTimeZone(abbreviation: "GMT")
print(outputFormatter.stringFromDate(date))

// prints "2015-12-31 00:12"
outputFormatter.timeZone = NSTimeZone(abbreviation: "Europe/Stockholm") // +02:00
print(outputFormatter.stringFromDate(date))

// prints "2015-12-30 18:12"
outputFormatter.timeZone = NSTimeZone(abbreviation: "EST") // -05:00 SAME AS INPUT
print(outputFormatter.stringFromDate(date))
```

Rule of thumb: You should only think about time zones when displaying `NSDate`s.

## Hooks

`ApiModel` uses [Alamofire](https://github.com/alamofire/alamofire) for sending and receiving requests. To hook into this, the `API` class currently has `before`- and `after`-hooks that you can use to modify or log the requests. An example of sending user credentials with each request:

```swift
// Put this somewhere in your AppDelegate or together with other initialization code
api().beforeRequest { request in
if let loginToken = User.loginToken() {
request.parameters["access_token"] = loginToken
}
}
```

There is also a `afterRequest` which passes in a `ApiRequest` and `ApiResponse`:

```swift
api().afterRequest { request, response in
println("... Got: \(response.status)")
println("... \(request)")
println("... \(response)")
}
```

## URLs

Given the setup for the `Post` model above, if you wanted to get the full url with replacements for the show resource (like `https://service.io/api/v1/posts/123.json`), you can use:

```swift
post.apiUrlForRoute(Post.apiRoutes().show)
// NOT IMPLEMENTED YET BECAUSE LIMITATIONS IN SWIFT: post.apiUrlForResource(.Show)
```

## Dealing with IDs

As a consumer of an API, you never want to make assumptions about the ID structure used for their models. Do not use `Int` or anything similar for ID types, strings are to be recommended. Therefor `ApiModel` defines a typealias to `String`, called ApiId. There is also an `ApiIdTransform` available for IDs.

## Namespaces and envelopes

Some API's wrap all their responses in an "envelope", a container that is generic for all responses. For example an API might wrap all response data within a `data`-property of the root JSON:

```json
{
"data": {
"user": { ... }
}
}
```

To deal with this gracefully there is a configuration option on the `ApiConfig` class called `rootNamespace`. This is a dot-separated path that is traversed for each response. To deal with the above example you would simply:

```swift
let config = ApiConfig()
config.rootNamespace = "data"
```

It can also be more complex, for example if the envelope looked something like this:

```json
{
"JsonResponseEnvelope": {
"SuccessFullJsonResponse": {
"SoapResponseContainer": {
"EnterpriseBeanData": {
"user": { ... }
}
}
}
}
}
```

This would then convert into the `rootNamespace`:

```swift
let config = ApiConfig()
config.rootNamespace = "JsonResponseEnvelope.SuccessFullJsonResponse.SoapResponseContainer.EnterpriseBeanData"
```

## Caching and storage

It is up to you to cache and store the results of any calls. ApiModel does not do that for you, and will not do that, since strategies vary wildly depending on needs.

## File uploads

Just as the `JSONDictionary` can return a dictionary of parameters to be sent to the server, it can also contain `NSData` values that can be uploaded to a server. For example you could convert `UIImage`s to `NSData` and upload them for profile images.

The standard way of uploading files on the web is using the content-type `multipart/form-data`, which is slightly different from JSON. If you have a model that should be able to support file uploads, you can configure the model to encode it's `JSONDictionary` into `multipart/form-data`.

The following example illustrates a `UserAvatar` model:

```swift
import RealmSwift
import ApiModel
import UIKit

class UserAvatar: Object, ApiModel, ApiConfigurable {
dynamic var userId = ApiId()
dynamic var url = String() // generated on the server

var imageData: NSData?

class func apiConfig(config: ApiConfig) -> ApiConfig {
// ApiRequest.FormDataEncoding is where the magic happens
// It tells ApiModel to encode everything with `multipart/form-data`
config.encoding = ApiRequest.FormDataEncoding
return config
}

// Important because the `imageData` property cannot be represented by Realm
override class func ignoredProperties() -> [String] {
return ["imageData"]
}

override class func primaryKey() -> String {
return "userId"
}

class func apiNamespace() -> String {
return "user_avatar"
}

class func apiRoutes() -> ApiRoutes {
return ApiRoutes.resource("/user/avatar.json")
}

class func fromJSONMapping() -> JSONMapping {
return [
"userId": ApiIdTransform(),
"url": StringTransform()
]
}

func JSONDictionary() -> [String:AnyObject] {
return [
"image": FileUpload(fileName: "avatar.jpg", mimeType: "image/jpg", data: imageData!)
]
}
}

func upload() {
let image = UIImage(named: "me.jpg")!

let userAvatar = UserAvatar()
userAvatar.userId = "1"
userAvatar.imageData = UIImageJPEGRepresentation(image, 1)!

Api(model: userAvatar).save { form in
if form.hasErrors {
print("Could not upload file: " + form.errorMessages.joinWithSeparator("\n"))
} else {
print("File uploaded! URL: \(userAvatar.url)")
}
}
}
```

### FileUpload

You can upload any file this way, not only images. Any NSData can be uploaded. The default mime type for uploaded files is `application/octet-stream`. If you need to configure this there is a special object you need to construct called `FileUpload`.

The constructor is illustrated above, and takes the file name the server receives, mimetype of the file, and the data.

```swift
FileUpload(fileName: "document.pdf", mimeType: "application/pdf", data: documentData)
```

This should be put in the `JSONDictionary` dictionary. ApiModel will detect it and encode it accordingly.

# Thanks to

- [idlefingers](https://www.github.com/idlefingers)
- [Pluralize.swift](https://github.com/joshualat/Pluralize.swift)

# License

The MIT License (MIT)

Copyright (c) 2015 Rootof Creations HB

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
