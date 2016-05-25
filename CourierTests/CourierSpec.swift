import Quick
import Nimble
import Courier

class CourierSpec: QuickSpec {
  override func spec() {
    describe("deviceToken=") {
      it("stores the token in user defaults") {
        let apiToken = "test"
        let deviceToken = "DEVICE_TOKEN".dataUsingEncoding(NSUTF8StringEncoding)
        let courier = Courier(apiToken: apiToken, environment: .Development)

        courier.deviceToken = deviceToken

        let userDefaults = NSUserDefaults.standardUserDefaults()
        let key = "com.thoughtbot.courier.\(apiToken).device_token"
        expect(userDefaults.dataForKey(key)) == deviceToken
      }

      it("uses the same device token accross instances") {
        let deviceToken = "DEVICE_TOKEN".dataUsingEncoding(NSUTF8StringEncoding)
        Courier(apiToken: "", environment: .Development).deviceToken = deviceToken

        expect(Courier(apiToken: "", environment: .Development).deviceToken) == deviceToken
      }

      it("uses different tokens for instances with different API tokens") {
        let deviceToken = "DEVICE_TOKEN".dataUsingEncoding(NSUTF8StringEncoding)
        Courier(apiToken: "1", environment: .Development).deviceToken = deviceToken

        expect(Courier(apiToken: "2", environment: .Development).deviceToken).to(beNil())
      }
    }

    describe("subscribeToChannel") {
      it("subscribes to the channel using a previously registered token") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)
        let token = "93b40fbcf25480d515067ba49f98620e4ef38bdf7be9da6275f80c4f858f5ce2"

        courier.deviceToken = dataFromHexadecimalString(token)!
        courier.subscribeToChannel("Test")

        let body = try! NSJSONSerialization.JSONObjectWithData(session.lastRequest!.HTTPBody!, options: []) as! NSDictionary
        expect(body).to(equal(["device": ["token": token]] as NSDictionary))
      }
    }

    describe("subscribeToChannel(withToken:)") {
      it("requests the /subscribe/[token] endpoint") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Production, urlSession: session)

        courier.subscribeToChannel("!Tést/chännél! !test!", withToken: NSData())

        expect(session.lastRequest?.URL) == NSURL(string: "https://courier.thoughtbot.com/subscribe/test-channel-test?environment=production")
      }

      it("uses PUT") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)

        courier.subscribeToChannel("Test", withToken: NSData())

        expect(session.lastRequest?.HTTPMethod) == "PUT"
      }

      it("resumes the data task") {
        let task = TestURLSessionTask()
        let session = TestURLSession(task: task)
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)

        courier.subscribeToChannel("Test", withToken: NSData())

        expect(task.resumed) == true
      }

      it("uses the API token for authentication") {
        let apiToken = "api_key"
        let session = TestURLSession()
        let courier = Courier(apiToken: apiToken, environment: .Development, urlSession: session)

        courier.subscribeToChannel("Test", withToken: NSData())

        expect(session.lastRequest?.valueForHTTPHeaderField("Authorization")) == "Token token=\(apiToken)"
      }

      it("specifies the default version to use") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)

        courier.subscribeToChannel("Test", withToken: NSData())

        expect(session.lastRequest?.valueForHTTPHeaderField("Accept")).to(contain("version=1"))
      }

      it("accepts application/json") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)

        courier.subscribeToChannel("Test", withToken: NSData())

        expect(session.lastRequest?.valueForHTTPHeaderField("Accept")).to(contain("application/json"))
      }

      it("sends application/json") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)

        courier.subscribeToChannel("Test", withToken: NSData())

        expect(session.lastRequest?.valueForHTTPHeaderField("Content-Type")) == "application/json"
      }

      it("sends the device in the PUT body") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)
        let token = "93b40fbcf25480d515067ba49f98620e4ef38bdf7be9da6275f80c4f858f5ce2"

        courier.subscribeToChannel("Test", withToken: dataFromHexadecimalString(token)!)

        let body = try! NSJSONSerialization.JSONObjectWithData(session.lastRequest!.HTTPBody!, options: []) as! NSDictionary
        expect(body).to(equal(["device": ["token": token]] as NSDictionary))
      }

      it("supports changing the default base URL") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Production, urlSession: session, baseURL: NSURL(string: "https://example.com")!)

        courier.subscribeToChannel("channel", withToken: NSData())

        expect(session.lastRequest?.URL) == NSURL(string: "https://example.com/subscribe/channel?environment=production")
      }

      it("supports changing the default environment") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)

        courier.subscribeToChannel("channel", withToken: NSData())

        expect(session.lastRequest?.URL) == NSURL(string: "https://courier.thoughtbot.com/subscribe/channel?environment=development")
      }

      it("sets the device token") {
        let deviceToken = "DEVICE_TOKEN".dataUsingEncoding(NSUTF8StringEncoding)!
        let courier = Courier(apiToken: "", environment: .Development)

        courier.subscribeToChannel("channel", withToken: deviceToken)

        expect(courier.deviceToken) == deviceToken
      }

      context("success") {
        it("calls the completion block") {
          let session = TestURLSession()
          let courier = Courier(apiToken: "", environment: .Development, urlSession: session)

          waitUntil { done in
            courier.subscribeToChannel("channel", withToken: NSData()) { result in
              expect(result) == CourierResult.Success
              done()
            }

            let response = NSHTTPURLResponse(URL: NSURL(), statusCode: 200, HTTPVersion: .None, headerFields: .None)
            session.lastRequest?.perform(response: response)
          }
        }
      }

      context("when an error occurs") {
        it("calls the completion block with an error") {
          let session = TestURLSession()
          let courier = Courier(apiToken: "", environment: .Development, urlSession: session)
          let error = NSError(domain: "", code: 0, userInfo: nil)

          waitUntil { done in
            courier.subscribeToChannel("channel", withToken: NSData()) {
              expect($0) == CourierResult.Error(.Other(error: error))
              done()
            }

            session.lastRequest?.perform(error: error)
          }
        }
      }

      context("when the status code is not 2xx") {
        it("calls the completion block with an error") {
          let session = TestURLSession()
          let courier = Courier(apiToken: "", environment: .Development, urlSession: session)

          waitUntil { done in
            courier.subscribeToChannel("channel", withToken: NSData()) { result in
              expect(result) == CourierResult.Error(.InvalidStatusCode(404))

              done()
            }

            let response = NSHTTPURLResponse(URL: NSURL(), statusCode: 404, HTTPVersion: .None, headerFields: .None)
            session.lastRequest?.perform(response: response)
          }
        }
      }
    }

    describe("unsubscribeFromChannel") {
      it("requests the /subscribe/[channel] endpoint") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Production, urlSession: session)
        courier.deviceToken = "token".dataUsingEncoding(NSUTF8StringEncoding)

        courier.unsubscribeFromChannel("!Tést/chännél! !test!")

        expect(session.lastRequest?.URL) == NSURL(string: "https://courier.thoughtbot.com/subscribe/test-channel-test?environment=production")
      }

      it("uses DELETE") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)
        courier.deviceToken = "token".dataUsingEncoding(NSUTF8StringEncoding)

        courier.unsubscribeFromChannel("!Tést/chännél! !test!")

        expect(session.lastRequest?.HTTPMethod) == "DELETE"
      }

      it("resumes the data task") {
        let task = TestURLSessionTask()
        let session = TestURLSession(task: task)
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)
        courier.deviceToken = "token".dataUsingEncoding(NSUTF8StringEncoding)

        courier.unsubscribeFromChannel("!Tést/chännél! !test!")

        expect(task.resumed) == true
      }

      it("uses the API token for authentication") {
        let apiToken = "api_key"
        let session = TestURLSession()
        let courier = Courier(apiToken: apiToken, environment: .Development, urlSession: session)
        courier.deviceToken = "token".dataUsingEncoding(NSUTF8StringEncoding)

        courier.subscribeToChannel("Test", withToken: NSData())
        courier.unsubscribeFromChannel("Test")

        expect(session.lastRequest?.valueForHTTPHeaderField("Authorization")) == "Token token=\(apiToken)"
      }

      it("specifies the default version to use") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)
        courier.deviceToken = "token".dataUsingEncoding(NSUTF8StringEncoding)

        courier.unsubscribeFromChannel("Test")

        expect(session.lastRequest?.valueForHTTPHeaderField("Accept")).to(contain("version=1"))
      }

      it("accepts application/json") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)
        courier.deviceToken = "token".dataUsingEncoding(NSUTF8StringEncoding)

        courier.unsubscribeFromChannel("Test")

        expect(session.lastRequest?.valueForHTTPHeaderField("Accept")).to(contain("application/json"))
      }

      it("sends application/json") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)
        courier.deviceToken = "token".dataUsingEncoding(NSUTF8StringEncoding)

        courier.unsubscribeFromChannel("Test")

        expect(session.lastRequest?.valueForHTTPHeaderField("Content-Type")) == "application/json"
      }

      it("sends the device in the DELETE body") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)
        let token = "93b40fbcf25480d515067ba49f98620e4ef38bdf7be9da6275f80c4f858f5ce2"
        courier.deviceToken = dataFromHexadecimalString(token)

        courier.unsubscribeFromChannel("Test")

        let body = try! NSJSONSerialization.JSONObjectWithData(session.lastRequest!.HTTPBody!, options: []) as! NSDictionary
        expect(body).to(equal(["device": ["token": token]] as NSDictionary))
      }

      context("success") {
        it("calls the completion block") {
          let session = TestURLSession()
          let courier = Courier(apiToken: "", environment: .Development, urlSession: session)
          courier.deviceToken = "token".dataUsingEncoding(NSUTF8StringEncoding)

          waitUntil { done in
            courier.unsubscribeFromChannel("channel") { result in
              expect(result) == CourierResult.Success
              done()
            }

            let response = NSHTTPURLResponse(URL: NSURL(), statusCode: 200, HTTPVersion: .None, headerFields: .None)
            session.lastRequest?.perform(response: response)
          }
        }
      }

      context("when an error occurs") {
        it("calls the completion block with an error") {
          let session = TestURLSession()
          let courier = Courier(apiToken: "", environment: .Development, urlSession: session)
          courier.deviceToken = "token".dataUsingEncoding(NSUTF8StringEncoding)
          let error = NSError(domain: "", code: 0, userInfo: nil)

          waitUntil { done in
            courier.unsubscribeFromChannel("channel") {
              expect($0) == CourierResult.Error(.Other(error: error))
              done()
            }

            session.lastRequest?.perform(error: error)
          }
        }
      }

      context("when the status code is not 2xx") {
        it("calls the completion block with an error") {
          let session = TestURLSession()
          let courier = Courier(apiToken: "", environment: .Development, urlSession: session)
          courier.deviceToken = "token".dataUsingEncoding(NSUTF8StringEncoding)

          waitUntil { done in
            courier.unsubscribeFromChannel("channel") { result in
              expect(result) == CourierResult.Error(.InvalidStatusCode(404))
              done()
            }

            let response = NSHTTPURLResponse(URL: NSURL(), statusCode: 404, HTTPVersion: .None, headerFields: .None)
            session.lastRequest?.perform(response: response)
          }
        }
      }
    }

    afterEach {
      let userDefaults = NSUserDefaults.standardUserDefaults()
      let dictionary = userDefaults.dictionaryRepresentation()
      dictionary.keys.forEach(userDefaults.removeObjectForKey)
    }
  }
}

private class TestURLSession: URLSession {
  var task: TestURLSessionTask

  var requests: [TestRequest] = []
  var lastRequest: TestRequest? { return requests.last }

  init(task: TestURLSessionTask = TestURLSessionTask()) {
    self.task = task
  }

  private func dataTaskWithRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> URLSessionTask {
    requests.append(
      TestRequest(request: request, completionHandler: completionHandler)
    )
    return task
  }
}

private struct TestRequest {
  let request: NSURLRequest
  let completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void

  var URL: NSURL? { return request.URL }
  var HTTPMethod: String? { return request.HTTPMethod }
  var HTTPBody: NSData? { return request.HTTPBody }

  func valueForHTTPHeaderField(field: String) -> String? {
    return request.valueForHTTPHeaderField(field)
  }

  func perform(data data: NSData? = nil, response: NSURLResponse? = nil, error: NSError? = nil) {
    completionHandler(data, response, error)
  }
}

private class TestURLSessionTask: URLSessionTask {
  var resumed = false

  private func resume() {
    resumed = true
  }
}

private func dataFromHexadecimalString(string: String) -> NSData? {
  let trimmedString = string.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "<> ")).stringByReplacingOccurrencesOfString(" ", withString: "")

  let regex = try! NSRegularExpression(pattern: "^[0-9a-f]*$", options: .CaseInsensitive)

  let found = regex.firstMatchInString(trimmedString, options: [], range: NSRange(0..<trimmedString.characters.count))
  if found == nil || found?.range.location == NSNotFound || trimmedString.characters.count % 2 != 0 {
    return nil
  }

  let data = NSMutableData(capacity: trimmedString.characters.count / 2)

  var index = trimmedString.startIndex
  while index < trimmedString.endIndex {
    let byteString = trimmedString.substringWithRange(index..<index.successor().successor())
    let num = UInt8(byteString.withCString { strtoul($0, nil, 16) })
    data?.appendBytes([num] as [UInt8], length: 1)

    index = index.successor().successor()
  }

  return data
}
