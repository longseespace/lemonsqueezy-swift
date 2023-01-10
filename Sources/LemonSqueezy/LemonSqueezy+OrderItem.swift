//
//  File.swift
//  
//
//  Created by Ram Ratan Maurya on 11/01/23.
//

import Foundation

extension LemonSqueezy {
    /// Get a single order item by ID.
    ///
    /// - Parameters:
    ///    - orderItemId: The ID of the order item you'd like to retrieve.
    /// - Returns: A response object containing the requested ``OrderItem``.
    public func getOrderItem(_ orderItemId: OrderItem.ID) async throws -> LemonSqueezyAPIDataAndIncluded<OrderItem, OrderItem.Included> {
        return try await call(route: .orderItem(orderItemId), queryItems: [])
    }
    
    /// Returns a list of order items.
    /// - Parameters:
    ///    - pageNumber: The page number to return the response for.
    ///    - pageSize: The number of resources to return per-page.
    /// - Returns: A response object containing an array of ``OrderItem``.
    public func getOrderItems(pageNumber: Int = 1, pageSize: Int = 10) async throws -> LemonSqueezyAPIDataIncludedAndMeta<[OrderItem], OrderItem.Included, Meta> {
        return try await call(route: .orderItems, queryItems: [], pageNumber: pageNumber, pageSize: pageSize)
    }
}
