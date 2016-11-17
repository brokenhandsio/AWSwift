import Foundation
import CryptoSwift

struct HeaderSignerGenerator: Aws4Signer {
    
    fileprivate var awsAccessId: String
    fileprivate var awsAccessSecret: String
    
    init(awsAccessId: String, awsAccessSecret: String) {
        self.awsAccessId = awsAccessId
        self.awsAccessSecret =  awsAccessSecret
    }
    
    // Move all the variables into a protocol `requestObject`
    func getAuthHeader(forRequest request: [String : Any], requestDate: Date, service: AwsService, region: AwsRegion, requestMethod: HttpMethod) -> String {
        
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        let requestDateString = formatter.string(from: requestDate)
        
        let headers = [
            "Content-Type": "application/x-amz-json-1.0",
            "Host": "\(service.getServiceHostname()).\(region.rawValue).amazonaws.com",
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
    
    internal func createCanonicalRequestHash(method: HttpMethod, uri: String?, query: String?, headers: [String : String], signedHeaders: [String], body: String?) -> String{
        
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
        
        // TODO need to trim
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
    
    internal func createSigningString(requestDate: Date, region: AwsRegion, service: AwsService, canonicalRequestHash: String) -> String {
        
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
        signingString += "\(dateOnlyFormatter.string(from: requestDate))/\(region.rawValue)/\(service.getServiceHostname())/aws4_request\n"
        
        // Hashed Canonical Request
        signingString += "\(canonicalRequestHash)"
        
        return signingString
    }
    
    internal func createSigningKey(awsAccessSecret: String, requestDate: Date, region: AwsRegion, service: AwsService) -> Array<UInt8> {
        
        // TODO sort out unwraps
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        
        let kDate = try? HMAC(key: "AWS4\(awsAccessSecret)", variant: .sha256).authenticate([UInt8](formatter.string(from: requestDate).utf8))
        let kRegion = try? HMAC(key: kDate!, variant: .sha256).authenticate([UInt8](region.rawValue.utf8))
        let kService = try? HMAC(key: kRegion!, variant: .sha256).authenticate([UInt8](service.getServiceHostname().utf8))
        let kSigning = try? HMAC(key: kService!, variant: .sha256).authenticate([UInt8]("aws4_request".utf8))
        return kSigning!
    }
    
    internal func createSignature(signingKey: Array<UInt8>, signingString: String) -> String {
        let signatureBytes = try? HMAC(key: signingKey, variant: .sha256).authenticate([UInt8](signingString.utf8))
        
        let hexString = NSMutableString()
        for byte in signatureBytes! {
            hexString.appendFormat("%02x", UInt(byte))
        }
        
        let signature = String(hexString)
        return signature
    }
    
    internal func createCredentialsHeader(awsAccessId: String, requestDate: Date, region: AwsRegion, service: AwsService) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let credentialsHeader = "\(awsAccessId)/\(formatter.string(from: requestDate))/\(region.rawValue)/\(service.getServiceHostname())/aws4_request"
        return credentialsHeader
    }
    
    internal func createAuthorizationHeader(credentialsHeader: String, signedHeaders: [String], signature: String) -> String {
        let signedHeaderString = getSignedHeadersString(signedHeaders)
        let authHeader = "AWS4-HMAC-SHA256 Credential=\(credentialsHeader), SignedHeaders=\(signedHeaderString), Signature=\(signature)"
        return authHeader
    }
    
    internal func getSignedHeadersString(_ signedHeaders: [String]) -> String {
        let sortedSignedHeaderKeys = signedHeaders.sorted()
        let signedHeaderUppercase = sortedSignedHeaderKeys.joined(separator: ";")
        let signedHeadersString = signedHeaderUppercase.lowercased()
        return signedHeadersString
    }
}
