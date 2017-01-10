class Report

  require 'csv'
  attr_accessor :data

  def initialize(file, info={})
    output = CSV.open(file, headers: true, header_converters: :symbol)
    puts "#{file} opened!"
    @transactions = output.each
    @data = process_report(@transactions, info)
  end

  def process_report(transactions, info)
    report = {}
    report["Purchase"] = {"AccountRef" => {value: info[:cc_account][:val], name: info[:cc_account][:name]}}
    report["Purchase"]["PaymentType"] = "CreditCard"
    #report["TotalAmt"] = get_total(transactions).to_s
    #might need to do this when collecting classes
    report["TxnDate"] = info[:statement_date]
    report["Line"] = []
    info[:count].times do
      t = transactions.first
      this_line = {}
      this_line["Amount"] = t[:amount]
      binding.pry
      this_line["AccountRef"] = {"value" => info[:accounts][(t[:account]).gsub(/\s+/, "_").to_s][:val],
                                  "name" => info[:accounts][(t[:account]).gsub(/\s+/, "_").to_s][:name]
                                }
      this_line["ClassRef"] = {"value" => info[:classes][(t[:program]).gsub(/\s+/, "_").to_s][:val],
                                "name" => info[:classes][(t[:program]).gsub(/\s+/, "_").to_s][:name]
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
    total.round(2)
  end

end
