class Report

  require 'csv'
  attr_accessor :total, :transactions, :data

  def initialize(file)
    output = CSV.open(file, headers: true, header_converters: :symbol)
    #@headers = output.first.to_a
    @transactions = output.each
    #puts transactions.first
    @data = process_report(@transactions)
#    @total = get_total(@transactions)
  end

  def process_report(transactions)
    report = {}
    report["Purchase"] = {"AccountRef" => {},
                          "PaymentType" => "CreditCard"}

    report["Line"] = []
    transactions.each do |t|
      this_line = {}
      this_line["Amount"] = t[:amount]
      this_line["AccountRef"] = {"value" => "13",
                                  "name" => t[:account]
                                }
      report["Line"].push(this_line)
    end
    return report
  end

  def get_total(transactions)
    total = 0
    transactions.each do |t|
      total += t[:amount].to_f
    end
    total
  end

end
