//
//  CostDetailsViewModelType.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 23.03.2022.
//

import Foundation

protocol CostDetailsViewModelType {
  var costDate: Date { get }
  var costName: String { get }
  var costSum: Double { get }

  func validate(name: String?, sumText: String?) -> Bool
  func parsedSum(from text: String?) -> Double?
  func saveCostModel(costDate: Date, costName: String?, costSum: Double?) async throws
}
