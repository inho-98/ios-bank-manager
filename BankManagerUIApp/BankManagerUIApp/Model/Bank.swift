//
//  Bank.swift
//  Created by sunnycookie, inho
//

import Foundation


protocol BankDelegate {
    func didDequeueCustomer(_ customer: Customer)
}

class Bank {
    var bankClerks: [BankClerk]
    private var customers: Queue<Customer> = Queue()
    private var completedCustomerCount: Int = 0
    private var processingStartTime: Date?
    var delegate: BankDelegate? = nil

    init(bankClerks: [BankClerk]) {
        self.bankClerks = bankClerks
    }
    
    func receive(customer: Customer) {
        customers.enqueue(customer)
    }
 
    func runBankingCycle() {
        processingStartTime = Date()
        
        var customers: (deposit: Queue<Customer>, loan: Queue<Customer>) = divideCustomers()
        let group = DispatchGroup()
        
        matchClerk(to: &customers.deposit, of: .deposit, group: group)
        matchClerk(to: &customers.loan, of: .loan, group: group)
        group.notify(queue: .main) {
            self.closeBanking()
        }
    }
    
    func divideCustomers() -> (Queue<Customer>, Queue<Customer>) {
        var depositCustomers = Queue<Customer>()
        var loanCustomers = Queue<Customer>()
        
        while !customers.isEmpty {
            guard let customer = customers.dequeue() else {
                return (depositCustomers, loanCustomers)
            }
            
            delegate?.didDequeueCustomer(customer)
            
            if customer.bankingType == .deposit {
                depositCustomers.enqueue(customer)
            } else if customer.bankingType == .loan {
                loanCustomers.enqueue(customer)
            }
        }
        
        return (depositCustomers, loanCustomers)
    }
    
    func matchClerk(to customers: inout Queue<Customer>,
                             of type: BankingType,
                             group: DispatchGroup) {
        let bankClerks = bankClerks.filter { $0.bankingType == type }
        
        while !customers.isEmpty {
            bankClerks.forEach { bankClerk in
                guard let customer = customers.dequeue() else { return }
                
                bankClerk.serve(customer: customer, group: group)
                completedCustomerCount += 1
            }
        }
    }
    
    private func closeBanking() {
        guard let processingStartTime = processingStartTime else { return }
        
        let totalProcessingTime = String(format: Constant.twoDecimal,
                                         -processingStartTime.timeIntervalSinceNow)

        print(String(format: Constant.bankClosedMessage,
                     arguments: [completedCustomerCount, totalProcessingTime]))
    }
}

private extension Bank {
    enum Constant {
        static let twoDecimal: String = "%.2f"
        static let bankClosedMessage = "업무가 마감되었습니다. " +
                                       "오늘 업무를 처리한 고객은 총 %d명이며, " +
                                       "총 업무시간은 %@초입니다."
    }
}
