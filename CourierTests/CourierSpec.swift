import Quick
import Nimble
import Courier

class CourierSpec: QuickSpec {
  override func spec() {
    context("#subscribeToChannel") {
      it("requests the /subscribe/[token] endpoint") {
        let session = TestURLSession()
        let courier = Courier(apiKey: "", urlSession: session)

        courier.subscribeToChannel("Tést\n chännél", withToken: NSData())

        expect(session.lastRequest?.URL) == NSURL(string: "https://courier.thoughtbot.com/subscribe/test-channel?environment=production")
      }

      it("uses PUT") {
        let session = TestURLSession()
        let courier = Courier(apiKey: "", urlSession: session)

        courier.subscribeToChannel("Test", withToken: NSData())

        expect(session.lastRequest?.HTTPMethod) == "PUT"
      }

      it("resumes the data task") {
        let task = TestURLSessionTask()
        let session = TestURLSession(task: task)
        let courier = Courier(apiKey: "", urlSession: session)

        courier.subscribeToChannel("Test", withToken: NSData())

        expect(task.resumed) == true
      }

      it("uses the API token for authentication") {
        let apiKey = "api_key"
        let session = TestURLSession()
        let courier = Courier(apiKey: apiKey, urlSession: session)

        courier.subscribeToChannel("Test", withToken: NSData())

        expect(session.lastRequest?.valueForHTTPHeaderField("Authorization")) == "Token token=\(apiKey)"
      }

      it("specifies the default version to use") {
        let session = TestURLSession()
        let courier = Courier(apiKey: "", urlSession: session)

        courier.subscribeToChannel("Test", withToken: NSData())

        expect(session.lastRequest?.valueForHTTPHeaderField("Accept")).to(contain("version=1"))
      }

      it("accepts application/json") {
        let session = TestURLSession()
        let courier = Courier(apiKey: "", urlSession: session)

        courier.subscribeToChannel("Test", withToken: NSData())

        expect(session.lastRequest?.valueForHTTPHeaderField("Accept")).to(contain("application/json"))
      }

      it("sends application/json") {
        let session = TestURLSession()
        let courier = Courier(apiKey: "", urlSession: session)

        courier.subscribeToChannel("Test", withToken: NSData())

        expect(session.lastRequest?.valueForHTTPHeaderField("Content-Type")) == "application/json"
      }

      it("sends the device in the PUT body") {
        let session = TestURLSession()
        let courier = Courier(apiKey: "", urlSession: session)
        let token = "93b40fbcf25480d515067ba49f98620e4ef38bdf7be9da6275f80c4f858f5ce2"

        courier.subscribeToChannel("Test", withToken: dataFromHexadecimalString(token)!)

        let body = try! NSJSONSerialization.JSONObjectWithData(session.lastRequest!.HTTPBody!, options: []) as! NSDictionary
        expect(body).to(equal(["device": ["token": token]] as NSDictionary))
      }

      it("supports changing the default base URL") {
        let session = TestURLSession()
        let courier = Courier(apiKey: "", urlSession: session, baseURL: NSURL(string: "https://example.com")!)

        courier.subscribeToChannel("channel", withToken: NSData())

        expect(session.lastRequest?.URL) == NSURL(string: "https://example.com/subscribe/channel?environment=production")
      }

      it("supports changing the default environment") {
        let session = TestURLSession()
        let courier = Courier(apiKey: "", urlSession: session, environment: .Development)

        courier.subscribeToChannel("channel", withToken: NSData())

        expect(session.lastRequest?.URL) == NSURL(string: "https://courier.thoughtbot.com/subscribe/channel?environment=development")
      }
    }
  }
}

private class TestURLSession: URLSession {
  var task: TestURLSessionTask

  var requests: [NSURLRequest] = []
  var lastRequest: NSURLRequest? { return requests.last }

  init(task: TestURLSessionTask = TestURLSessionTask()) {
    self.task = task
  }

  private func dataTaskWithRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> URLSessionTask {
    requests.append(request)
    return task
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
