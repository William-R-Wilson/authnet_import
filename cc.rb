class AuthNetImporter < Sinatra::Base

  ##  Credit Card report sequence

  #get file and statement date
    get '/prepare_report' do
      if session[:token]
        erb :prepare_report, layout: :layout
      else
        redirect "/"
      end
    end

    post '/process_report' do
      if session[:token]
        session[:file] = params[:report_file]
        trans = CSV.read(params[:report_file], headers: true, header_converters: :symbol)
        session[:count] = trans.count
        session[:statement_date] = params[:statement_date]
        session[:accounts] = get_accounts(trans)
        session[:classes] = get_classes(trans)
        session[:total] = get_total(trans)
        redirect :map_accounts
      else
        redirect "/"
      end
    end

    def get_classes(trans)
      classes = []
      trans.each do |t|
        classes.push(t[:program])
      end
      classes.uniq
    end

    def get_accounts(trans)
      accounts = []
      trans.each do |t|
        accounts.push(t[:account])
      end
      accounts.uniq
    end

    def get_total(transactions)
      total = 0
      transactions.each do |t|
        total += t[:amount].to_f
      end
      total.round(2).to_s
    end


  #map accounts

    get "/map_accounts" do
      api = QboApi.new(oauth_data)
      @accounts = session[:accounts]
      @cc_account = api.query(%{select * from Account where AccountType = 'Credit Card'})
      @expense_accounts = api.query(%{select * from Account where AccountType = 'Expense'})
      erb :map_accounts, layout: :layout
    end

    post "/set_cc_accounts" do

      api = QboApi.new(oauth_data)
      cc_acct = api.get :account, params[:credit_card_account]
      session[:cc_account] = {name: cc_acct["Name"], val: cc_acct["Id"]}
      params.delete("credit_card_account")
      session[:accounts] = get_account_names(params.to_json)
      redirect :map_classes
    end

  #map classes

    get "/map_classes" do
      api = QboApi.new(oauth_data)
      @classes = session[:classes]
      @qb_classes = api.query(%{select * from Class})
      erb :map_classes, layout: :layout
    end

    post "/set_cc_classes" do
      session[:classes] = get_class_names(params.to_json)
      redirect "/build_cc_report"
    end

    #api.get :customer, session[:default_customer]
    #get names of accounts and classes
    def get_account_names(data)
      new_accounts_hash = {}
      api = QboApi.new(oauth_data)
      JSON.parse(data).each do |k,v|
        this_account = api.get :account, v
        new_accounts_hash[k] = {val: v, name: this_account["Name"]}
      end
      new_accounts_hash
    end

    def get_class_names(data)
      new_classes_hash = {}
      api = QboApi.new(oauth_data)
      JSON.parse(data).each do |k, v|
        this_class = api.query(%{select * from Class where Id = '#{v}'})
        new_classes_hash[k] = {val: v, name: this_class["QueryResponse"]["Class"].first["Name"]}
      end
      new_classes_hash
    end


  #build

    get "/build_cc_report" do
      if session[:token]
        report = Report.new(session[:file], {cc_account: (session[:cc_account]),
                                        accounts: (session[:accounts]),
                                        classes: (session[:classes]),
                                        statement_date: session[:statement_date],
                                        count: session[:count],
                                        total: session[:total]})
        @data = report.data
        session[:report] = @data
        erb :report, layout: :layout
      else
        redirect "/"
      end
      #binding.pry
    end

    post '/send_cc_to_quickbooks' do
      if session[:token]
        puts "Authorized!"
        puts session[:report]
        api = QboApi.new(oauth_data)
        response = api.create :purchase, payload: session[:report]
        puts response
      else
        puts "not authorized"
      end
      redirect "/"
    end

  end
