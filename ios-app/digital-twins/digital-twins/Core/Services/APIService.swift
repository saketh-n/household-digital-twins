//
//  APIService.swift
//  digital-twins
//
//  Network service for backend API communication
//

import Foundation
import UIKit

actor APIService {
    static let shared = APIService()
    
    private let baseURL = "http://192.168.50.81:8000"
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Health Check
    func checkHealth() async throws -> HealthResponse {
        let url = try makeURL("/health")
        let (data, response) = try await performRequest(url: url)
        try validateResponse(response)
        return try decode(HealthResponse.self, from: data)
    }
    
    // MARK: - Get Bookshelf
    func fetchBookshelf() async throws -> BookshelfResponse {
        let url = try makeURL("/bookshelf")
        let (data, response) = try await performRequest(url: url)
        try validateResponse(response)
        return try decode(BookshelfResponse.self, from: data)
    }
    
    // MARK: - Scan Image
    func scanBookshelf(image: UIImage) async throws -> ScanResponse {
        let url = try makeURL("/scan")
        
        // Compress image to JPEG
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw APIError.noData
        }
        
        // Create multipart form data request
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60 // Allow more time for image processing
        
        var body = Data()
        
        // Add image field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"bookshelf.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await performRequest(request: request)
        try validateResponse(response)
        return try decode(ScanResponse.self, from: data)
    }
    
    // MARK: - Clear Bookshelf
    func clearBookshelf() async throws {
        let url = try makeURL("/bookshelf")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await performRequest(request: request)
        try validateResponse(response)
    }
    
    // MARK: - Private Helpers
    private func makeURL(_ path: String) throws -> URL {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        return url
    }
    
    private func performRequest(url: URL) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(from: url)
        } catch let error as URLError {
            throw mapURLError(error)
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }
    }
    
    private func performRequest(request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let error as URLError {
            throw mapURLError(error)
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }
    }
    
    private func mapURLError(_ error: URLError) -> APIError {
        switch error.code {
        case .timedOut:
            return .timeout
        case .cannotConnectToHost, .cannotFindHost, .networkConnectionLost:
            return .serverUnreachable
        default:
            return .networkError(error.localizedDescription)
        }
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid response type")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode, HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
        }
    }
    
    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(type, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }
}

