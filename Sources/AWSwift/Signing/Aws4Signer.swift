import Foundation

protocol Aws4Signer {
    func getAuthHeader(forRequest request: [String : Any], requestDate: Date, service: AwsService, region: AwsRegion, requestMethod: HttpMethod) -> String
    func createCanonicalRequestHash(method: HttpMethod, uri: String?, query: String?, headers: [String: String], signedHeaders: [String], body: String?) -> String
    func createSigningString(requestDate: Date, region: AwsRegion, service: AwsService, canonicalRequestHash: String) -> String
    func createSigningKey(awsAccessSecret: String, requestDate: Date, region: AwsRegion, service: AwsService) -> Array<UInt8>
    func createSignature(signingKey: Array<UInt8>, signingString: String) -> String
    func createCredentialsHeader(awsAccessId: String, requestDate: Date, region: AwsRegion, service: AwsService) -> String
    func createAuthorizationHeader(credentialsHeader: String, signedHeaders: [String], signature: String) -> String
}
