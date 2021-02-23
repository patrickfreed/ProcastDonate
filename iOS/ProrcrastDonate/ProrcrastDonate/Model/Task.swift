//
//  Task.swift
//  ProrcrastDonate
//
//  Created by Andrew Morgan on 23/02/2021.
//

import SwiftUI
import SwiftBSON

class Task: ObservableObject, Identifiable {
    @Published var _id = BSONObjectID()
    @Published var title = ""
    @Published var descriptionText = ""
    @Published var startDate = Date()
    @Published var completedDate: Date?
    @Published var cancelDate: Date?
    @Published var renewals = [Renewal]()
    @Published var deadlineDate = Date().addingTimeInterval(86400)
    @Published var donateOnFailure = true
    @Published var donationAmount: Int = 0
    @Published var charity: BSONObjectID?
    @Published var tags = [String]()
    
    var id: String { _id.description }

    convenience init(
        _id: BSONObjectID = BSONObjectID(),
        title: String,
        descriptionText: String,
        startDate: Date = Date(),
        completedDate: Date? = nil,
        cancelDate: Date? = nil,
        renewals: [Renewal] = [],
        deadlineDate: Date,
        donateOnFailure: Bool,
        donationAmount: Int,
        charity: BSONObjectID? = nil,
        tags: [String]
    ) {
        self.init()
        self._id = _id
        self.title = title
        self.descriptionText = descriptionText
        self.startDate = startDate
        self.completedDate = completedDate
        self.cancelDate = cancelDate
        self.renewals.append(contentsOf: renewals)
        self.deadlineDate = deadlineDate
        self.donateOnFailure = donateOnFailure
        self.donationAmount = donationAmount
        self.charity = charity
        self.tags.append(contentsOf: tags)
    }
}
