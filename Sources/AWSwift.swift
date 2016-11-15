import Foundation
import CryptoSwift

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

enum AWSRegion: String {
    case euWest1 = "eu-west-1"
}

enum AWSService: String {
    case dynamoDB = "dynamoDB"
}

protocol Aws4Signer {
    func getAuthHeader(forRequest request: [String : Any], requestDate: Date, service: AWSService, region: AWSRegion, requestMethod: HTTPMethod) -> String
    func createCanonicalRequestHash(method: HTTPMethod, uri: String?, query: String?, headers: [String: String], signedHeaders: [String], body: String?) -> String
    func createSigningString(requestDate: Date, region: AWSRegion, service: AWSService, canonicalRequestHash: String) -> String
    func createSigningKey(awsAccessSecret: String, requestDate: Date, region: AWSRegion, service: AWSService) -> Array<UInt8>
    func createSignature(signingKey: Array<UInt8>, signingString: String) -> String
    func createCredentialsHeader(awsAccessId: String, requestDate: Date, region: AWSRegion, service: AWSService) -> String
    func createAuthorizationHeader(credentialsHeader: String, signedHeaders: [String], signature: String) -> String
}

protocol DynamoDbTable {
    var tableName: String { get }
    var partitionKey: String { get }
    var sortKey: String? { get }
}

protocol DynamoDb {
    func getItem(table: DynamoDbTable, key: [String: String], completion: ((_ itemJsonString: String) -> Void))
}

struct AWSwiftDynamoDB: DynamoDb {
    
    fileprivate let awsAccessKeyId: String
    fileprivate let awsAccessKeySecret: String
    
    public init(awsAccessKeyId: String, awsAccessKeySecret: String) {
        self.awsAccessKeyId = awsAccessKeyId
        self.awsAccessKeySecret = awsAccessKeySecret
    }
    
    func getItem(table: DynamoDbTable, key: [String : String], completion: ((_ itemJsonString: String) -> Void)) {
        let request = [
            "TableName": table.tableName,
            "Key": key
        ] as [String: Any]
        
        let awsReqeust = AWSRequest(awsAccessKeyId: awsAccessKeyId, awsAccessKeySecret: awsAccessKeySecret, service: .dynamoDB, region: .euWest1, request: request, requestMethod: .post)
        awsReqeust.makeRequest { (jsonResposne) in
            completion(jsonResposne)
        }
    }
}

struct AWSRequest {
    
    fileprivate let awsAccessKeyId: String
    fileprivate let awsAccessKeySecret: String
    fileprivate let service: AWSService
    fileprivate let region: AWSRegion
    fileprivate let request: [String: Any]
    fileprivate let requestMethod: HTTPMethod
    
    public init(awsAccessKeyId: String, awsAccessKeySecret: String, service: AWSService, region: AWSRegion, request: [String: Any], requestMethod: HTTPMethod) {
        self.awsAccessKeyId = awsAccessKeyId
        self.awsAccessKeySecret = awsAccessKeySecret
        self.service = service
        self.region = region
        self.request = request
        self.requestMethod = requestMethod
    }
    
    public func makeRequest(onCompletion: (_ jsonResponse: String) -> Void) {
        let headerHost = "\(service).\(region).amazonaws.com"
        let urlString = "https://\(headerHost)"
        let url = URL(string: urlString)!
        var urlRequest = URLRequest(url: url)
        let requestDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        let requestDateString = dateFormatter.string(from: requestDate)
        let jsonData = try? JSONSerialization.data(withJSONObject: request, options: .prettyPrinted)
        
        urlRequest.httpMethod = requestMethod.rawValue
        // TODO sort out unwrapping
        urlRequest.httpBody = jsonData!
        
        urlRequest.setValue(requestDateString, forHTTPHeaderField: "X-Amz-Date")
        urlRequest.setValue(headerHost, forHTTPHeaderField: "Host")
        // TODO
        urlRequest.setValue("DynamoDB_20120810.GetItem", forHTTPHeaderField: "X-Amz-Target")
        urlRequest.setValue("application/x-amz-json-1.0", forHTTPHeaderField: "Content-Type")
        
        let headerSigner = HeaderSignerGenerator(awsAccessId: awsAccessKeyId, awsAccessSecret: awsAccessKeySecret)
        
        let authHeader = headerSigner.getAuthHeader(forRequest: request, requestDate: requestDate, service: service, region: region, requestMethod: requestMethod)
        
        urlRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: urlRequest) {
            data, response, error in
            
            // TODO
            if let data = data {
                print("Data was \(data) - \(String(data: data, encoding: .utf8))")
            }
            print("Response was \(response)")
            print("Error was \(error)")
        }
        
        dataTask.resume()
        
    }
}

struct HeaderSignerGenerator: Aws4Signer {
    
    fileprivate var awsAccessId: String
    fileprivate var awsAccessSecret: String
    
    init(awsAccessId: String, awsAccessSecret: String) {
        self.awsAccessId = awsAccessId
        self.awsAccessSecret =  awsAccessSecret
    }
    
    // Move all the variables into a protocol `requestObject`
    func getAuthHeader(forRequest request: [String : Any], requestDate: Date, service: AWSService, region: AWSRegion, requestMethod: HTTPMethod) -> String {
        
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        let requestDateString = formatter.string(from: requestDate)
        
        let headers = [
            "Content-Type": "application/x-amz-json-1.0",
            "Host": "\(service.rawValue).\(region.rawValue).amazonaws.com",
            "X-AMZ-Date": requestDateString
        ]
        
        let signedHeaders = Array(headers.keys)
        
        let jsonData = try? JSONSerialization.data(withJSONObject: request, options: .prettyPrinted)
        let jsonString = String(data: jsonData!, encoding: .utf8)
        
        let canonicalRequestHash = createCanonicalRequestHash(method: requestMethod, uri: nil, query: nil, headers: headers, signedHeaders: signedHeaders, body: jsonString)
        
        let credentialsHeader = createCredentialsHeader(awsAccessId: self.awsAccessId, requestDate: requestDate, region: region, service: service)
        
        let signingKey = createSigningKey(awsAccessSecret: self.awsAccessSecret, requestDate: requestDate, region: region, service: service)
        let signingString = createSigningString(requestDate: requestDate, region: region, service: service, canonicalRequestHash: canonicalRequestHash)
        
        let signature = createSignature(signingKey: signingKey, signingString: signingString)
        
        let authHeader = createAuthorizationHeader(credentialsHeader: credentialsHeader, signedHeaders: signedHeaders, signature: signature)
        
        return authHeader
    }
    
    func createCanonicalRequestHash(method: HTTPMethod, uri: String?, query: String?, headers: [String : String], signedHeaders: [String], body: String?) -> String{
        
        // HTTP Method
        var canonicalRequest = "\(method.rawValue)\n"
        
        // URI
        if let uri = uri {
            canonicalRequest += uri
        }
        else {
            canonicalRequest += "/"
        }
        
        canonicalRequest += "\n"
        
        // Query
        if let query = query {
            canonicalRequest += query
        }
        
        canonicalRequest += "\n"
        
        // Headers
        // Header keys must be in alphabetical order and lowercase and trimmed
        
        // TODO need to trum
        let sortedKeys = Array(headers.keys).sorted()
        
        for key in sortedKeys {
            canonicalRequest += "\(key.lowercased()):\(headers[key]!)\n"
        }
        canonicalRequest += "\n"
        
        // Signed Headers
        canonicalRequest += getSignedHeadersString(signedHeaders)
        canonicalRequest += "\n"
        
        // Payload Hash
        var bodyPayload = ""
        
        if let body = body {
            bodyPayload = body
        }
        
        canonicalRequest += bodyPayload.sha256()
        
        // Return SHA256
        
        return canonicalRequest.sha256()
    }
    
    func createSigningString(requestDate: Date, region: AWSRegion, service: AWSService, canonicalRequestHash: String) -> String {
        
        let formatter = DateFormatter()
        let dateOnlyFormatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateOnlyFormatter.dateFormat = "yyyyMMdd"
        
        // Algorithm
        var signingString = "AWS4-HMAC-SHA256\n"
        
        // Request Date
        // TODO convert to UTC
        signingString += "\(formatter.string(from: requestDate))\n"
        
        // Credentials Scope
        signingString += "\(dateOnlyFormatter.string(from: requestDate))/\(region.rawValue)/\(service.rawValue)/aws4_request\n"
        
        // Hashed Canonical Request
        signingString += "\(canonicalRequestHash)\n"
        
        return signingString
    }
    
    func createSigningKey(awsAccessSecret: String, requestDate: Date, region: AWSRegion, service: AWSService) -> Array<UInt8> {
        
        // TODO sort out unwraps
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"

        let kDate = try? HMAC(key: "AWS4\(awsAccessSecret)", variant: .sha256).authenticate([UInt8](formatter.string(from: requestDate).utf8))
        let kRegion = try? HMAC(key: kDate!, variant: .sha256).authenticate([UInt8](region.rawValue.utf8))
        let kService = try? HMAC(key: kRegion!, variant: .sha256).authenticate([UInt8](service.rawValue.utf8))
        let kSigning = try? HMAC(key: kService!, variant: .sha256).authenticate([UInt8]("aws4_request".utf8))
        return kSigning!
    }
    
    func createSignature(signingKey: Array<UInt8>, signingString: String) -> String {
        let signatureBytes = try? HMAC(key: signingKey, variant: .sha256).authenticate([UInt8](signingString.utf8))
        
        let hexString = NSMutableString()
        for byte in signatureBytes! {
            hexString.appendFormat("%02x", UInt(byte))
        }
        
        let signature = String(hexString)
        return signature
    }
    
    func createCredentialsHeader(awsAccessId: String, requestDate: Date, region: AWSRegion, service: AWSService) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let credentialsHeader = "\(awsAccessId)/\(formatter.string(from: requestDate))/\(region.rawValue)/\(service.rawValue)/aws4_request"
        return credentialsHeader
    }
    
    func createAuthorizationHeader(credentialsHeader: String, signedHeaders: [String], signature: String) -> String {
        let signedHeaderString = getSignedHeadersString(signedHeaders)
        let authHeader = "AWS4-HMAC-SHA256 Credential=\(credentialsHeader), SignedHeaders=\(signedHeaderString), Signature=\(signature)"
        return authHeader
    }
    
    func getSignedHeadersString(_ signedHeaders: [String]) -> String {
        // TODO do this properly - check we have the ones we need etc
        var signedHeadersString = ""
        let sortedSignedHeaderKeys = signedHeaders.sorted()
        for key in sortedSignedHeaderKeys {
            signedHeadersString += "\(key);"
        }
        return signedHeadersString
    }
}

