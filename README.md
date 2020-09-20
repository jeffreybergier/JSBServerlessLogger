![Xcode: 12](https://img.shields.io/badge/Xcode-12-lightgrey.svg) ![Swift: 5.3](https://img.shields.io/badge/Swift-5.3-lightgrey.svg) ![iOS: 10+](https://img.shields.io/badge/iOS-10+-lightgrey.svg) ![macOS: 10.12+](https://img.shields.io/badge/macOS-10.12+-lightgrey.svg)

# JSBServerlessLogger

## What is it

`JSBServerlessLogger` is a small library that persists error logs to disk and then performs a `PUT` request with them so that they can be sent to a logging endpoint when the device has a network connection. This is intended to be a lightweight error reporting alternative to Firebase, Segment, and other large analytics frameworks.

If you want to record when critical errors happen in your app in production but are not interested in embedding a huge analytics framework, this may be a good choice. When combined with AWS Lambda and AWS Simple Email Service, it is easy to set up a free logging solution that stores error logs in an email account where they are searchable.

## How does it work

`JSBServerlessLogger` uses `XCGLogger` as its logging base. This is a great logging framework that works great in Swift. All of the pieces of `JSBServerlessLogger` can be used separately, but the easy way is to instantiate `Logger` which is a subclass of `XCGLogger`. This instance can be used in all the normal ways `XCGLogger` is normally used. But `Logger` has extra behavior. 

When you log something that is a higher level than is specified in the configuration object, then `Logger` writes the log to a folder called `Inbox`. The log contains the original log but it also contains extra information about the device that could help with debugging. `Logger` also checks if the object that was logged was a `Swift.Error` or an `NSError`, in either case it adds the error and the `userInfo` dictionary to the saved log.

A separate class called `Logger.Monitor` monitors the `Inbox` folder and when a new file appears, it moves the file to the `Outbox` folder and then performs the network request. When the network request succeeds it moves the file to a folder called `Sent`. If the network request fails then it leaves the file in `Outbox`. `Outbox` is checked on instantiation and with a timer to make sure it eventually gets sent.

## How to use

1. Add `https://github.com/jeffreybergier/JSBServerlessLogger.git` to your Swift Package Manifest in Xcode or in the `Package.swift` dependencies list.
1. Instantiate `Logger.DefaultSecureConfiguration`
1. Instantiate `Logger` with this configuration.
1. Log errors to the instance of `Logger`

## How to set up AWS

1. Configure Lambda
1. Configure SES
1. Configure Gateway

## Class overview

## How to contribute