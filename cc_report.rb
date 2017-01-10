class Report

  require 'csv'
  attr_accessor :data

  def initialize(file, info={})
    output = CSV.open(file, headers: true, header_converters: :symbol)
    @transactions = output.each
    @data = process_report(@transactions, info)
  end

  def process_report(transactions, info)
    count = 0
    report = {}
    report["Purchase"] = {"AccountRef" => {value: info[:cc_account][:val], name: info[:cc_account][:name]}}
    report["Purchase"]["PaymentType"] = "CreditCard"
    report["TotalAmt"] = info[:total]
    report["TxnDate"] = info[:statement_date]
    report["Line"] = []
    info[:count].times do
      t = transactions.first
      count += 1
      this_line = {}
      this_line["Id"] = count
      this_line["Amount"] = t[:amount]
      this_line["Description"] = "#{t[:employee]} - #{t[:vendor]}, #{t[:what]} for #{t[:who]}, #{t[:where]} #{t[:why]}"
      this_line["DetailType"] = "AccountBasedExpenseLineDetail"
      this_line["AccountBasedExpenseLineDetail"] =
        {
          "AccountRef" => {"value" => info[:accounts][(t[:account]).gsub(/\s+/, "_").to_s][:val],
                                  "name" => info[:accounts][(t[:account]).gsub(/\s+/, "_").to_s][:name]
                                },
          "ClassRef" => {"value" => info[:classes][(t[:program]).gsub(/\s+/, "_").to_s][:val],
                                "name" => info[:classes][(t[:program]).gsub(/\s+/, "_").to_s][:name]
                              },
          "BillableStatus" => "NotBillable",
          "TaxCodeRef" => {"value" => "NON"}
        }
      report["Line"].push(this_line)
    end
    return report
  end


end
