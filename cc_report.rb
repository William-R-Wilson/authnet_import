class Report

  require 'csv'
  attr_accessor :data

  def initialize(file, info={})
    output = CSV.open(file, headers: true, header_converters: :symbol)
    @transactions = output.each
    @data = process_report(@transactions, info)
  end

  def process_report(transactions, info)
    report = {}
    report["Purchase"] = {"AccountRef" => {},
                          "PaymentType" => "CreditCard"}
    report["TotalAmt"] = get_total(transactions).to_s
    report["TxnDate"] = info[:statement_date]
    report["Line"] = []
    transactions.each do |t|
      this_line = {}
      this_line["Amount"] = t[:amount]
      this_line["AccountRef"] = {"value" => "13",
                                  "name" => t[:account]
                                }
      this_line["ClassRef"] = {"value" => "13",
                                "name" => t[:program]
                              }
      this_line[""]
      report["Line"].push(this_line)
    end
    return report
  end

  def get_total(transactions)
    total = 0
    transactions.each do |t|
      total += t[:amount].to_f
    end
    total.round(2)
  end

end
