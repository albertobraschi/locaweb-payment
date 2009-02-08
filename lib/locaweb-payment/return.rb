module Locaweb
  class Return < Base
    # Return SOAP webservice
    RETURN_API = "https://www.pagamentocerto.com.br/vendedor/vendedor.asmx?WSDL"
    
    attr_accessor :id
    attr_accessor :xml
    
    def initialize(id)
      self.class.config!
      @id = id
    end
    
    def process!
      result = nil
      
      silence_warnings do
        result = wsdl.ConsultaTransacao({
          :chaveVendedor => config["authentication_key"],
          :idTransacao   => @id
        })
      end
      
      @xml = Hpricot::XML(result.consultaTransacaoResult)
      nil
    end
    
    def confirmed?
      return false unless @xml
      
      node = (@xml/"Pagamento")
      
      if (node/"Modulo").text == "CartaoCredito" && (node/"Processado").text == "true"
        true
      elsif (node/"Modulo").text == "Boleto" && (node/"Processado").text == "true" && message == ""
        true
      else
        false
      end
    end
    
    def status
      (@xml/"CodRetorno").text if @xml
    end
    
    def message
      (@xml/"Pagamento > MensagemRetorno").text if @xml
    end
    
    def wsdl
      @wsdl ||= begin
        factory = SOAP::WSDLDriverFactory.new(RETURN_API)
        factory.create_rpc_driver
      end
    end
  end
end