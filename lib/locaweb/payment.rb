module Locaweb
  class Payment < Base
    # Seller SOAP webservice
    SELLER_API = "https://www.pagamentocerto.com.br/vendedor/vendedor.asmx?WSDL"
    
    # Buyer type identifier 
    TYPE = {
      :person  => "Fisica",
      :company => "Juridica"
    }
    
    # Available credit cards
    CREDIT_CARD = {
      :visa => "Visa",
      :amex => "AmericanExpress"
    }
    
    # Available payment methods
    PAYMENT = {
      :invoice     => "Boleto",
      :credit_card => "CartaoCredito"
    }
    
    # The seller authentication key
    attr_accessor :authentication_key
    
    # Multiple order items. To add an item add a hash to the array.
    #   @payment.items << {:id => 1, :description => "Some product", :price => 10.99}
    #   @payment.items << {:id => 1, :description => "Some product", :price => 3.99, :quantity => 10}
    #   @payment.items << {:id => 1, :description => "Some product", :price => 10.99}
    attr_accessor :items
    
    # The buyer info
    #   @payment.buyer = {
    #     :name  => "John Doe",
    #     :email => "john@doe.com",
    #     :cpf   => "12345678912",
    #     :rg    => "124567890",
    #     :phone => "1234567890",
    #     :type  => :person,
    #     :address => [],
    #     :shipping_address => []
    #   }
    #
    # If the buyer is a company, you need to set additional information.
    #   @payment.buyer.merge! {
    #     :company => "Some company name",
    #     :cnpj    => "9999999999999"
    #   }
    #
    # The address is an array with 6 positions:
    #   address = [
    #     "Avenida Paulista",
    #     nil,
    #     "1711",
    #     "Bela Vista",
    #     "São Paulo",
    #     "SP",
    #     "01311200"
    #   ]
    #
    # If :shipping_address is not set, will receive the :address value
    attr_accessor :buyer
    
    # The order details
    #   @payment.order = {
    #     :id => 1234,
    #     :shipping => 0
    #     :payment  => [:credit_card, :visa]
    #   }
    attr_accessor :order
    
    # The order confirmation URL
    attr_accessor :return_to
    
    def initialize(options={})
      self.class.config!
      defaults!
      
      # Extract options
      extract_options!(options)
    end
    
    def defaults!
      @items = []
      @buyer = {
        :name  => "",
        :email => "",
        :cpf   => "",
        :rg    => "",
        :phone => "",
        :type  => :person,
        :address => [],
        :shipping_address => []                
      }
      @order = {
        :id => nil,
        :shipping => 0,
        :payment  => :invoice
      }
    end
    
    def xml
      @xml ||= Builder::XmlMarkup.new(:indent => 2)
    end
    
    def wsdl
      @wsdl ||= begin
        factory = SOAP::WSDLDriverFactory.new(SELLER_API)
        factory.create_rpc_driver
      end
    end
    
    # Extract the hash options setting to instance variables
    def extract_options!(options)
      options.each do |name, value|
        send("#{name}=", value)
      end
    end
    
    def process
      process_xml!
      response = nil
      
      silence_warnings do
        response = wsdl.iniciaTransacao({
          :chaveVendedor => config["authentication_key"],
          :urlRetorno    => config["return_to"],
          :xml           => @xml.target!
        })
      end
      
      Locaweb::Result.new(response)
    rescue Exception => exception
     Locaweb::Result.new(nil)
    end
    
    def process_xml!
      @xml = nil
      
      xml.instruct!
      xml.LocaWeb do |node|
        process_buyer!   node
        process_payment! node
        process_order!   node
      end
    end
    
    def process_buyer!(node)
      @buyer[:type] ||= :person
      @buyer[:type] = @buyer[:type].to_sym
      
      node.Comprador do |x|
        x.Nome        @buyer[:name]
        x.Email       @buyer[:email]
        x.Cpf         @buyer[:cpf]
        x.Rg          @buyer[:rg]
        x.Ddd         @buyer[:phone][0,2]
        x.Telefone    @buyer[:phone][2,8]
        x.TipoPessoa  TYPE[@buyer[:type]]
        
        unless @buyer[:type] == :person
          x.RazaoSocial @buyer[:company]
          x.Cnpj        @buyer[:cnpj]
        end
      end
    end
    
    def process_payment!(node)
      payment = [@order[:payment], :invoice].flatten

      node.Pagamento do |x|
        x.Modulo PAYMENT[payment[0].to_sym]
        x.Tipo   CREDIT_CARD[payment[1].to_sym]
      end
    end
    
    def process_order!(node)
      node.Pedido do |x|
        x.Numero          @order[:id]
        x.ValorSubTotal   currency(total_price - @order[:shipping])
        x.ValorFrete      currency(@order[:shipping])
        x.ValorAcrescimo  "000"
        x.ValorDesconto   "000"
        x.ValorTotal      currency(total_price)
        
        process_items!(x)
        process_address!(node)
      end
    end
    
    def process_items!(node)
      node.Itens do |x|
        @items.each do |item|
          x.Item do |x|
            quantity = item[:quantity] || 1
            
            x.CodProduto    item[:id]
            x.DescProduto   item[:description]
            x.Quantidade    quantity
            x.ValorUnitario currency(item[:price])
            x.ValorTotal    currency(item[:price] * quantity)
          end
        end
      end
    end
    
    def process_address!(node)
      @buyer[:shipping_address] ||= @buyer[:address]
      
      node.Cobranca do |x|
        x.Endereco    @buyer[:address][0]
        x.Complemento @buyer[:address][2] if @buyer[:address][2]
        x.Numero      @buyer[:address][1]
        x.Bairro      @buyer[:address][3]
        x.Cidade      @buyer[:address][4]
        x.Cep         @buyer[:address][5]
        x.Estado      @buyer[:address][6]
      end
      
      node.Entrega do |x|
        x.Endereco    @buyer[:shipping_address][0]
        x.Complemento @buyer[:shipping_address][2] if @buyer[:shipping_address][2]
        x.Numero      @buyer[:shipping_address][1]
        x.Bairro      @buyer[:shipping_address][3]
        x.Cidade      @buyer[:shipping_address][4]
        x.Cep         @buyer[:shipping_address][5]
        x.Estado      @buyer[:shipping_address][6]
      end
    end
    
    def total_price
      total = @order[:shipping]
      
      @items.each do |item|
        quantity = item[:quantity] || 1
        total += (quantity * item[:price])
      end

      total
    end
    
    # Convert price to normalized format.
    # 100.99 will be converted to 10099
    # 0 will be converted to 000
    def currency(value)
      sprintf("%.2f", value).gsub(/\./, "")
    end
  end
end