require File.dirname(__FILE__) + "/spec_helper"

describe "Payment" do
  before(:each) do
    silence_warnings do
      Locaweb::Payment::CONFIG_FILE = File.dirname(__FILE__) + "/fixtures/locaweb-payment.yml"
    end
    
    @wsdl    = mock("wsdl", :null_object => true)
    @factory = mock("factory", :null_object => true, :create_rpc_driver => @wsdl)
    SOAP::WSDLDriverFactory.stub!(:new).and_return(@factory)
    
    @payment = Locaweb::Payment.new
    
    @payment.buyer = {
      :name    => "John Doe",
      :email   => "john@doe.com",
      :cpf     => "19034859592",
      :rg      => "123456789",
      :phone   => "1155558888",
      :type    => "person",
      :address => [
        "Rua Alexandre Dumas",
        "1711",
        "2º andar",
        "Santo Amaro",
        "São Paulo",
        "04717004",
        "SP"
      ]
    }
    
    @payment.order = {
      :payment  => :invoice,
      :id       => 1001,
      :shipping => 10
    }
    
    @payment.items << {:id => 1, :description => "Product 1", :price => 10.99}
    @payment.items << {:id => 2, :description => "Product 2", :price => 19.99, :quantity => 2}
  end
  
  describe "successful transaction" do
    before(:each) do
      @contents = File.read(File.dirname(__FILE__) + "/fixtures/success.xml")
      
      @result = mock("result", :iniciaTransacaoResult => @contents)
      
      @wsdl.should_receive(:iniciaTransacao).with({
        :chaveVendedor => "3cb77220-b01b-4c54-a520-b083acc30954",
        :urlRetorno    => "/payments/success",
        :xml           => anything
      }).and_return(@result)
      
      @result = @payment.process
    end
    
    it "should return result" do
      @result.should be_success
      @result.status.should == "0"
      @result.code.should == "1049"
      @result.id.should == "3da568b6-6e39-46c6-9d3f-898e68939c56"
      @result.url.should == "https://www.pagamentocerto.com.br/pagamento/pagamento.aspx?tdi=3da568b6-6e39-46c6-9d3f-898e68939c56"
    end
    
    it "should return invoice url" do
      @result.url(:invoice).should == "https://www.pagamentocerto.com.br/pagamento/ReemissaoBoleto.aspx?tdi=3da568b6-6e39-46c6-9d3f-898e68939c56"
    end
  end
  
  describe "unsuccessful transaction" do
    before(:each) do
      @contents = File.read(File.dirname(__FILE__) + "/fixtures/invalid.xml")
      
      @result = mock("result", :iniciaTransacaoResult => @contents)
      
      @wsdl.should_receive(:iniciaTransacao).with({
        :chaveVendedor => "3cb77220-b01b-4c54-a520-b083acc30954",
        :urlRetorno    => "/payments/success",
        :xml           => anything
      }).and_return(@result)
      
      @result = @payment.process
    end
    
    it "should return result" do
      @result.should_not be_success
      @result.status.should == "21"
      @result.code.should be_nil
      @result.id.should be_nil
      @result.url.should be_nil
    end
  end
  
  describe "rescuing exception" do
    before(:each) do
      @wsdl.should_receive(:iniciaTransacao).with({
        :chaveVendedor => "3cb77220-b01b-4c54-a520-b083acc30954",
        :urlRetorno    => "/payments/success",
        :xml           => anything
      }).and_raise(Exception)
      
      @result = @payment.process
    end
    
    it "should return result" do
      @result.should_not be_success
      @result.status.should be_nil
      @result.code.should be_nil
      @result.id.should be_nil
      @result.url.should be_nil
    end
  end
  
  describe "XML" do
    # ATTENTION: The XML nodes must follow the same order
    # from the Integration Docs examples. And this took me sometime to figure out!
    # Stupid, but it works!
    
    it "should be a :person buyer" do
      @payment.process
      doc = Hpricot::XML(@payment.xml.target!)
      node = (doc/"LocaWeb > Comprador")

      (node/"Nome").text.should == "John Doe"
      (node/"Email").text.should == "john@doe.com"
      (node/"Cpf").text.should == "19034859592"
      (node/"Rg").text == "123456789"
      (node/"Ddd").text == "11"
      (node/"Telefone").text == "55558888"
      (node/"TipoPessoa").text == "Fisica"
      (node/"RazaoSocial").size.should be_zero
      (node/"Cnpj").size.should be_zero
    end

    it "should be a :company buyer" do
      @payment.buyer.merge!({
        :type    => :company,
        :company => "Some company",
        :cnpj    => "12614295000175"
      })

      @payment.process
      doc = Hpricot::XML(@payment.xml.target!)
      node = (doc/"LocaWeb > Comprador")

      (node/"Cnpj").text.should == "12614295000175"
      (node/"RazaoSocial").text.should == "Some company"
      (node/"TipoPessoa").text.should == "Juridica"
    end

    it "should use :invoice as payment method" do
      @payment.process
      doc = Hpricot::XML(@payment.xml.target!)
      node = (doc/"LocaWeb > Pagamento")

      (node/"Modulo").text.should == "Boleto"
      (node/"Tipo").size.should == 1
      (node/"Tipo").text.should == ""
    end

    it "should use :credit_card as payment method (Visa)" do
      @payment.order.merge!(:payment => [:credit_card, :visa])

      @payment.process
      doc = Hpricot::XML(@payment.xml.target!)
      node = (doc/"LocaWeb > Pagamento")

      (node/"Modulo").text.should == "CartaoCredito"
      (node/"Tipo").text.should == "Visa"
    end

    it "should use :credit_card as payment method (American Express)" do
      @payment.order.merge!(:payment => [:credit_card, :amex])

      @payment.process
      doc = Hpricot::XML(@payment.xml.target!)
      node = (doc/"LocaWeb > Pagamento")

      (node/"Modulo").text.should == "CartaoCredito"
      (node/"Tipo").text.should == "AmericanExpress"
    end

    it "should return order total price" do
      @payment.total_price.should == 60.97
    end

    it "should process order" do
      @payment.process
      doc = Hpricot::XML(@payment.xml.target!)
      node = (doc/"LocaWeb > Pedido")
      
      (node/"Numero:first").text.should == "1001"
      (node/"ValorFrete").text.should == "1000"
      (node/"ValorTotal:first").text.should == "6097"
      (node/"ValorSubTotal").text.should == "5097"
      (node/"ValorDesconto").text.should == "000"
      (node/"ValorAcrescimo").text.should == "000"
    end

    it "should process items" do
      @payment.process
      doc = Hpricot::XML(@payment.xml.target!)
      node = (doc/"LocaWeb > Pedido > Itens")

      (node/"Item").size.should == 2

      item = (node/"Item:first")
      (item/"CodProduto").text.should == "1"
      (item/"Quantidade").text.should == "1"
      (item/"ValorUnitario").text.should == "1099"
      (item/"ValorTotal").text.should == "1099"
      (item/"DescProduto").text.should == "Product 1"

      item = (node/"Item:last")
      (item/"CodProduto").text.should == "2"
      (item/"Quantidade").text.should == "2"
      (item/"ValorUnitario").text.should == "1999"
      (item/"ValorTotal").text.should == "3998"
      (item/"DescProduto").text.should == "Product 2"
    end

    it "should have payer address" do
      @payment.process
      doc = Hpricot::XML(@payment.xml.target!)
      node = (doc/"LocaWeb > Pedido > Cobranca")

      (node/"Endereco").text.should == "Rua Alexandre Dumas"
      (node/"Numero").text.should == "1711"
      (node/"Complemento").text.should == "2º andar"
      (node/"Bairro").text.should == "Santo Amaro"
      (node/"Cidade").text.should == "São Paulo"
      (node/"Cep").text.should == "04717004"
      (node/"Estado").text.should == "SP"
    end
    
    it "should have shipping address" do
      @payment.buyer[:shipping_address] = [
          "Avenida Paulista",
          "1190",
          "Apto. 139-B",
          "Bela Vista",
          "São Paulo",
          "01310100",
          "SP"
      ]
      
      @payment.process
      doc = Hpricot::XML(@payment.xml.target!)
      node = (doc/"LocaWeb > Pedido > Entrega")

      (node/"Endereco").text.should == "Avenida Paulista"
      (node/"Numero").text.should == "1190"
      (node/"Complemento").text.should == "Apto. 139-B"
      (node/"Bairro").text.should == "Bela Vista"
      (node/"Cidade").text.should == "São Paulo"
      (node/"Cep").text.should == "01310100"
      (node/"Estado").text.should == "SP"
    end
  end
end