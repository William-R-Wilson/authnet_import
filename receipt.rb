class Receipt
  require 'csv'
  attr_accessor :data

  def initialize(file, info={})
    output = CSV.open(file, headers: true, header_converters: :symbol, col_sep: "\t")
    contributions = output.each
    @data = process_deposit(contributions, info)
  end

  def find_place(contributions, count) #move to the right place in the file before processing
    count.times do
      row = contributions.first
      puts row
      if row[:response_code] != "1"
        redo
      end
      if row.nil?
        puts "end of file"
        break
      end
    end
  end


  def process_deposit(contributions, info)
    receipt = {}
    receipt["CustomerRef"] = {"value" => "#{info[:customer]}"}
    receipt["TxnDate"] = info[:date]
    receipt["Line"] = []
    receipt_total = 0
    count = 0
    find_place(contributions, info[:place])
    puts info[:num]
    info[:num].times do
      #count += 1
      line = {}
      row = contributions.first
      puts row
      if row[:response_code] != "1"
        redo
      end
      if row[:action_code] == "VOID" || row[:action_code] == "void"
        redo
      end
      if row[:action_code] == "EXPIRED" || row[:action_code] == "expired"
        redo
      end
      if row.nil?
        puts "end of file"
        break
      else
        count += 1
        line["LineNum"] = count
        line["Description"] = row[:customer_last_name].to_s + ", " + row[:customer_first_name].to_s + " - " + row[:invoice_description].to_s
        if line[:action_code] == "CREDIT"
          line["Amount"] = "-" + row[:total_amount].to_s
        else
          line["Amount"] = row[:total_amount].to_s
        end
        receipt_total += row[:total_amount].to_f
        line["DetailType"] = "SalesItemLineDetail"
        line["SalesItemLineDetail"] = { "ItemRef" => {"value" => "#{info[:item]}" },
                                        "TaxCodeRef" => {"value" => "NON" },
                                        "ClassRef" => {"value" => "#{info[:receipt_class]}"}
                                      }
        receipt["Line"].push(line)
      end
    end
    fee_line = { "LineNum" => count + 1, "Description" => "cybersource fee", "Amount" => "-#{info[:fee]}", "DetailType" => "SalesItemLineDetail",
                 "SalesItemLineDetail" => { "ItemRef" => { "value" => "#{info[:fee_item]}" },
                                            "ClassRef" => {"value" => "#{info[:receipt_class]}"},
                                            "TaxCodeRef" => { "value" => "NON" } } }
    receipt["Line"].push(fee_line)
    #amount check would be useful here
    return receipt
  end

end
