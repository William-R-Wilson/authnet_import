class ReceiptSettings

  def initialize(options={})
    @customer = options[:customer]
    @class = options[:class]
    @item = options[:item]
    @fee_item = options[:fee_item]
  end

  attr_accessor :customer, :class, :item, :fee_item

  def save
    Dir.mkdir("settings") unless Dir.exist? "settings"
    filename = "settings/receipt.yaml"
    File.open(filename, "w") do |file|
      file.puts YAML.dump(self)
    end
  end

end
