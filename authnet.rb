class AuthNetImporter < Sinatra::Base


  Dotenv.load

  require_relative 'receipt'
  require_relative 'cc_report'

  PORT  = 9393
  CONSUMER_KEY = ENV['QBO_API_CONSUMER_KEY']
  CONSUMER_SECRET = ENV['QBO_API_CONSUMER_SECRET']


  set :port, PORT
  use Rack::Session::Pool

  QboApi.production = true

  use OmniAuth::Builder do
    provider :quickbooks, CONSUMER_KEY, CONSUMER_SECRET
  end

  helpers do

    def title
      "Authorize.net Import"
    end

  end

  #code is ordered by sequence of execution

  get '/' do
    @app_center = QboApi::APP_CENTER_BASE
    @auth_data = oauth_data
    @port = PORT
    erb :index
  end

  #step 1 assign customer

  get '/customers' do
    if session[:token]
      api = QboApi.new(oauth_data)
      @resp = api.query(%{select * from Customer}) #api.all :customers
    end
    erb :customers
  end

  post '/set_default_customer' do
    session[:default_customer] = params["default_customer"]
    redirect '/classes'
  end

  #step 2 assign class

  get '/classes' do
    if session[:token]
      api = QboApi.new(oauth_data)
      @resp = api.query(%{select * from Class}) #api.all :customers
    end
    erb :classes
  end

  post '/set_default_class' do
    session[:default_class] = params["default_class"]
    redirect '/items'
  end

  #step 3 get default item for donations

  get '/items' do
    #set a default item
    if session[:token]
      api = QboApi.new(oauth_data)
      @resp = api.query(%{select * from Item})
    end
    erb :items
  end

  post '/set_default_item' do
    session[:default_item_id] = params["default_item"]
    #@default = session[:default_item_id]
    redirect '/fee_items'
  end

  #step 4 get item for fee line

  get '/fee_items' do
    if session[:token]
      api=QboApi.new(oauth_data)
      @resp = api.query(%{select * from Item})
    end
    erb :fee_items
  end

  post '/set_default_fee' do
    session[:default_fee_item] = params["default_fee_item"]
    redirect '/choose_file'
  end


  #step 5 get csv file info

  get '/choose_file' do
    erb :choose_file
  end

  post '/set_file' do
    session[:file] = params["file_name"]
    session[:position] = 0
    redirect :new_receipt
  end

  #step 6 - get info for parsing the csv

  get '/new_receipt' do
    session[:position] = session[:position] || 0
    if session[:token]
      api = QboApi.new(oauth_data)
      @default_item = api.get :item, session[:default_item_id]
      @fee_item = api.get :item, session[:default_fee_item]
      @customer = api.get :customer, session[:default_customer]
      @class = api.query(%{select * from Class where Id = '#{session[:default_class]}'})
      #get params for each deposit
      erb :new_receipt
    end
  end

  #step 7 review and decide to post to Quickbooks

  post "/create_receipt" do
    @date = params[:trans_date]
    @fee = params[:fee_amount]
    @num_trans = params[:num_transactions]
    @receipt_total = params[:receipt_total]
    r = Receipt.new(session[:file], {num: @num_trans.to_i,
                                  fee: @fee,
                                  date: @date,
                                  tot: @receipt_total,
                                  place: session[:position].to_i,
                                  item: session[:default_item_id],
                                  customer: session[:default_customer],
                                  fee_item: session[:default_fee_item],
                                  receipt_class: session[:default_class]
                                  })
    @receipt = r.data
    @calculated_total = get_receipt_total @receipt
    session[:prev_pos] = session[:position]
    session[:position] += @num_trans.to_i
    session[:current_receipt] = @receipt
    erb :create_receipt
  end

  post '/send_to_quickbooks' do
    @receipt = session[:current_receipt]
    puts @receipt
    if session[:token]
      puts "Authorized!"
      api = QboApi.new(oauth_data)
      response = api.create :salesreceipt, payload: session[:current_receipt]
      puts response
    else
      puts "not authorized"
    end
    redirect :new_receipt
  end

  get '/skip_receipt' do
    redirect :new_receipt
  end

  get '/try_again' do
    session[:position] = session[:prev_pos]
    redirect :new_receipt
  end

  get '/sales_receipt_sample' do
    if session[:token]
      api = QboApi.new(oauth_data)
      response = []
      api.all :salesreceipt do |r|
        response.push r
      end
      @sample = response.first
    end
    erb :sales_receipt_sample
  end

  def oauth_data
    {
      consumer_key: CONSUMER_KEY,
      consumer_secret: CONSUMER_SECRET,
      token: session[:token],
      token_secret: session[:secret],
      realm_id: session[:realm_id]
    }
  end

  get '/auth/quickbooks/callback' do
    auth = env["omniauth.auth"][:credentials]
    session[:token] = auth[:token]
    session[:secret] = auth[:secret]
    session[:realm_id] = params['realmId']
    '<!DOCTYPE html><html lang="en"><head></head><body><script>window.opener.location.reload(); window.close();</script></body></html>'
  end


  def get_receipt_total(receipt)
    total = 0
    receipt["Line"].each do |l|
      total += l["Amount"].to_i
    end
    total
  end

  get '/prepare_report' do
    if session[:token]
      erb :prepare_report
    else
      redirect "/"
    end
  end

  post '/process_report' do
    # if session[:token]
      r = Report.new(params[:report_file])
      @report = r.data
      erb :report
    # else
    #   redirect "/"
    # end
  end

get "/report" do
  @report
  erb :report
end

end
