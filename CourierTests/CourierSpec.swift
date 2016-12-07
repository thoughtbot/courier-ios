import Quick
import Nimble
import Courier

class CourierSpec: QuickSpec {
  let blankTestURL = URL(string: "about:blank")

  override func spec() {
    describe("deviceToken=") {
      it("stores the token in user defaults") {
        let apiToken = "test"
        let deviceToken = "DEVICE_TOKEN".data(using: String.Encoding.utf8)
        let courier = Courier(apiToken: apiToken, environment: .Development)

        courier.deviceToken = deviceToken

        let userDefaults = UserDefaults.standard
        let key = "com.thoughtbot.courier.device_token"
        expect(userDefaults.data(forKey: key)) == deviceToken
      }

      it("uses the same device token accross instances") {
        let deviceToken = "DEVICE_TOKEN".data(using: String.Encoding.utf8)
        Courier(apiToken: "", environment: .Development).deviceToken = deviceToken

        expect(Courier(apiToken: "", environment: .Development).deviceToken) == deviceToken
      }
    }

    describe("subscribeToChannel") {
      it("subscribes to the channel using a previously registered token") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)
        let token = "93b40fbcf25480d515067ba49f98620e4ef38bdf7be9da6275f80c4f858f5ce2"

        courier.deviceToken = dataFromHexadecimalString(token)!
        courier.subscribeToChannel("Test")

        let body = try? JSONSerialization.jsonObject(with: session.lastRequest!.HTTPBody!, options: []) as! NSDictionary
        expect(body).to(equal(["device": ["token": token]] as NSDictionary))
      }
    }

    describe("subscribeToChannel(withToken:)") {
      it("requests the /subscribe/[token] endpoint") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Production, urlSession: session)

        courier.subscribeToChannel("!Tést/chännél! !test!", withToken: Data())

        expect(session.lastRequest?.URL) == URL(string: "https://courier.thoughtbot.com/subscribe/test-channel-test?environment=production")
      }

      it("uses PUT") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)

        courier.subscribeToChannel("Test", withToken: Data())

        expect(session.lastRequest?.HTTPMethod) == "PUT"
      }

      it("resumes the data task") {
        let task = TestURLSessionTask()
        let session = TestURLSession(task: task)
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)

        courier.subscribeToChannel("Test", withToken: Data())

        expect(task.resumed) == true
      }

      it("uses the API token for authentication") {
        let apiToken = "api_key"
        let session = TestURLSession()
        let courier = Courier(apiToken: apiToken, environment: .Development, urlSession: session)

        courier.subscribeToChannel("Test", withToken: Data())

        expect(session.lastRequest?.valueForHTTPHeaderField("Authorization")) == "Token token=\(apiToken)"
      }

      it("specifies the default version to use") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)

        courier.subscribeToChannel("Test", withToken: Data())

        expect(session.lastRequest?.valueForHTTPHeaderField("Accept")).to(contain("version=1"))
      }

      it("accepts application/json") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)

        courier.subscribeToChannel("Test", withToken: Data())

        expect(session.lastRequest?.valueForHTTPHeaderField("Accept")).to(contain("application/json"))
      }

      it("sends application/json") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)

        courier.subscribeToChannel("Test", withToken: Data())

        expect(session.lastRequest?.valueForHTTPHeaderField("Content-Type")) == "application/json"
      }

      it("sends the device in the PUT body") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)
        let token = "93b40fbcf25480d515067ba49f98620e4ef38bdf7be9da6275f80c4f858f5ce2"

        courier.subscribeToChannel("Test", withToken: dataFromHexadecimalString(token)!)

        let body = try? JSONSerialization.jsonObject(with: session.lastRequest!.HTTPBody!, options: []) as! NSDictionary
        expect(body).to(equal(["device": ["token": token]] as NSDictionary))
      }

      it("supports changing the default base URL") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Production, urlSession: session, baseURL: URL(string: "https://example.com")!)

        courier.subscribeToChannel("channel", withToken: Data())

        expect(session.lastRequest?.URL) == URL(string: "https://example.com/subscribe/channel?environment=production")
      }

      it("supports changing the default environment") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)

        courier.subscribeToChannel("channel", withToken: Data())

        expect(session.lastRequest?.URL) == URL(string: "https://courier.thoughtbot.com/subscribe/channel?environment=development")
      }

      it("sets the device token") {
        let deviceToken = "DEVICE_TOKEN".data(using: String.Encoding.utf8)!
        let courier = Courier(apiToken: "", environment: .Development)

        courier.subscribeToChannel("channel", withToken: deviceToken)

        expect(courier.deviceToken) == deviceToken
      }

      context("success") {
        it("calls the completion block") {
          let session = TestURLSession()
          let courier = Courier(apiToken: "", environment: .Development, urlSession: session)

          waitUntil { done in
            courier.subscribeToChannel("channel", withToken: Data()) { result in
              expect(result) == CourierResult.success
              done()
            }

            let response = HTTPURLResponse(url: URL(string: "about:blank")!, statusCode: 200, httpVersion: .none, headerFields: .none)
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
            courier.subscribeToChannel("channel", withToken: Data()) {
              expect($0) == CourierResult.error(.other(error: error))
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
            courier.subscribeToChannel("channel", withToken: Data()) { result in
              expect(result) == CourierResult.error(.invalidStatusCode(404))

              done()
            }

            let response = HTTPURLResponse(url: self.blankTestURL!, statusCode: 404, httpVersion: .none, headerFields: .none)
            session.lastRequest?.perform(response: response)
          }
        }
      }
    }

    describe("unsubscribeFromChannel") {
      it("requests the /subscribe/[channel] endpoint") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Production, urlSession: session)
        courier.deviceToken = "token".data(using: String.Encoding.utf8)

        courier.unsubscribeFromChannel("!Tést/chännél! !test!")

        expect(session.lastRequest?.URL) == URL(string: "https://courier.thoughtbot.com/subscribe/test-channel-test?environment=production")
      }

      it("uses DELETE") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)
        courier.deviceToken = "token".data(using: String.Encoding.utf8)

        courier.unsubscribeFromChannel("!Tést/chännél! !test!")

        expect(session.lastRequest?.HTTPMethod) == "DELETE"
      }

      it("resumes the data task") {
        let task = TestURLSessionTask()
        let session = TestURLSession(task: task)
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)
        courier.deviceToken = "token".data(using: String.Encoding.utf8)

        courier.unsubscribeFromChannel("!Tést/chännél! !test!")

        expect(task.resumed) == true
      }

      it("uses the API token for authentication") {
        let apiToken = "api_key"
        let session = TestURLSession()
        let courier = Courier(apiToken: apiToken, environment: .Development, urlSession: session)
        courier.deviceToken = "token".data(using: String.Encoding.utf8)

        courier.subscribeToChannel("Test", withToken: Data())
        courier.unsubscribeFromChannel("Test")

        expect(session.lastRequest?.valueForHTTPHeaderField("Authorization")) == "Token token=\(apiToken)"
      }

      it("specifies the default version to use") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)
        courier.deviceToken = "token".data(using: String.Encoding.utf8)

        courier.unsubscribeFromChannel("Test")

        expect(session.lastRequest?.valueForHTTPHeaderField("Accept")).to(contain("version=1"))
      }

      it("accepts application/json") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)
        courier.deviceToken = "token".data(using: String.Encoding.utf8)

        courier.unsubscribeFromChannel("Test")

        expect(session.lastRequest?.valueForHTTPHeaderField("Accept")).to(contain("application/json"))
      }

      it("sends application/json") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)
        courier.deviceToken = "token".data(using: String.Encoding.utf8)

        courier.unsubscribeFromChannel("Test")

        expect(session.lastRequest?.valueForHTTPHeaderField("Content-Type")) == "application/json"
      }

      it("sends the device in the DELETE body") {
        let session = TestURLSession()
        let courier = Courier(apiToken: "", environment: .Development, urlSession: session)
        let token = "93b40fbcf25480d515067ba49f98620e4ef38bdf7be9da6275f80c4f858f5ce2"
        courier.deviceToken = dataFromHexadecimalString(token)

        courier.unsubscribeFromChannel("Test")

        let body = try? JSONSerialization.jsonObject(with: session.lastRequest!.HTTPBody!, options: []) as! NSDictionary
        expect(body).to(equal(["device": ["token": token]] as NSDictionary))
      }

      context("success") {
        it("calls the completion block") {
          let session = TestURLSession()
          let courier = Courier(apiToken: "", environment: .Development, urlSession: session)
          courier.deviceToken = "token".data(using: String.Encoding.utf8)

          waitUntil { done in
            courier.unsubscribeFromChannel("channel") { result in
              expect(result) == CourierResult.success
              done()
            }

            let response = HTTPURLResponse(url: self.blankTestURL!, statusCode: 200, httpVersion: .none, headerFields: .none)
            session.lastRequest?.perform(response: response)
          }
        }
      }

      context("when an error occurs") {
        it("calls the completion block with an error") {
          let session = TestURLSession()
          let courier = Courier(apiToken: "", environment: .Development, urlSession: session)
          courier.deviceToken = "token".data(using: String.Encoding.utf8)
          let error = NSError(domain: "", code: 0, userInfo: nil)

          waitUntil { done in
            courier.unsubscribeFromChannel("channel") {
              expect($0) == CourierResult.error(.other(error: error))
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
          courier.deviceToken = "token".data(using: String.Encoding.utf8)

          waitUntil { done in
            courier.unsubscribeFromChannel("channel") { result in
              expect(result) == CourierResult.error(.invalidStatusCode(404))
              done()
            }

            let response = HTTPURLResponse(url: self.blankTestURL!, statusCode: 404, httpVersion: .none, headerFields: .none)
            session.lastRequest?.perform(response: response)
          }
        }
      }
    }

    afterEach {
      UserDefaults.standard.removeObject(forKey: "com.thoughtbot.courier.device_token")
    }
  }
}

private class TestURLSession: URLSessionProtocol {
  var task: TestURLSessionTask

  var requests: [TestRequest] = []
  var lastRequest: TestRequest? { return requests.last }

  init(task: TestURLSessionTask = TestURLSessionTask()) {
    self.task = task
  }

  fileprivate func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionTaskProtocol {
    requests.append(
      TestRequest(request: request, completionHandler: completionHandler)
    )
    return task
  }
}

private struct TestRequest {
  let request: URLRequest
  let completionHandler: (Data?, URLResponse?, NSError?) -> Void

  var URL: Foundation.URL? { return request.url }
  var HTTPMethod: String? { return request.httpMethod }
  var HTTPBody: Data? { return request.httpBody }

  func valueForHTTPHeaderField(_ field: String) -> String? {
    return request.value(forHTTPHeaderField: field)
  }

  func perform(data: Data? = nil, response: URLResponse? = nil, error: NSError? = nil) {
    completionHandler(data, response, error)
  }
}

private class TestURLSessionTask: URLSessionTaskProtocol {
  var resumed = false

  fileprivate func resume() {
    resumed = true
  }
}

private func dataFromHexadecimalString(_ string: String) -> Data? {
  let trimmedString = string.trimmingCharacters(in: CharacterSet(charactersIn: "<> ")).replacingOccurrences(of: " ", with: "")

  let regex = try! NSRegularExpression(pattern: "^[0-9a-f]*$", options: .caseInsensitive)

  let found = regex.firstMatch(in: trimmedString, options: [], range: NSRange(0..<trimmedString.characters.count))
  if found == nil || found?.range.location == NSNotFound || trimmedString.characters.count % 2 != 0 {
    return nil
  }

  let data = NSMutableData(capacity: trimmedString.characters.count / 2)

  var index = trimmedString.startIndex
  while index < trimmedString.endIndex {
    let byteString = trimmedString.substring(with: index..<trimmedString.index(index, offsetBy: 2))

    let num = UInt8(byteString.withCString { strtoul($0, nil, 16) })
    data?.append([num] as [UInt8], length: 1)

    index = trimmedString.index(index, offsetBy: 2)
  }

  return data as Data?
}
