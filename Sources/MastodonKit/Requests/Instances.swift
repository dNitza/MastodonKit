//
//  Instances.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 5/17/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

/// `Instances` requests.
public enum Instances {
    /// Gets instance information.
    ///
    /// - Returns: Request for `Instance`.
    public static func current() -> Request<Instance> {
        return Request<Instance>(path: "/api/v1/instance")
    }

    /// Fetches current instance's custom emojis.
    ///
    /// - Returns: Request for `[Emoji]`.
    public static func customEmojis() -> Request<[Emoji]> {
        return Request<[Emoji]>(path: "/api/v1/custom_emojis")
    }

    /// Fetches hashtags that are currently being used more frequently than usual.
    ///
    /// - Returns: Request for `[Tag]`
    public static func trends() -> Request<[Tag]> {
        return Request<[Tag]>(path: "/api/v1/trends")
    }

    /// Fetches the directory of accounts for the instance
    ///
    /// - Returns: Request for `[Account]`.
    public static func directory(offset: String? = "0", local: String = "false") -> Request<[Account]> {
        let payload = Payload.parameters([
            Parameter(name: "offset", value: offset),
            Parameter(name: "local", value: local)
        ])
        let method = HTTPMethod.get(payload)

        return Request<[Account]>(path: "/api/v1/directory", method: method)
    }
}
