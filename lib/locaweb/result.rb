module Locaweb
  class Result < Base
    # Payment URL
    PAYMENT_URL = "https://www.pagamentocerto.com.br/pagamento/pagamento.aspx?tdi="
    
    # Invoice generator URL
    INVOICE_URL = "https://www.pagamentocerto.com.br/pagamento/ReemissaoBoleto.aspx?tdi="
    
    attr_accessor :result
    attr_accessor :xml
    
    def initialize(result)
      @result = result
      @xml = Hpricot::XML(@result.iniciaTransacaoResult) if @result
    end
    
    def message
      @message ||= (@xml/"MensagemRetorno").text if @xml
    end
    
    def id
      @id ||= (@xml/"IdTransacao").text if started?
    end
    
    def code
      @code ||= (@xml/"Codigo").text if started?
    end
    
    def status
      @status ||= (@xml/"CodRetorno").text if @xml
    end
    
    def started?
      status == "0"
    end
    
    def url(invoice=false)
      return nil unless started?
      
      if invoice
        INVOICE_URL + id
      else
        PAYMENT_URL + id
      end   
    end
  end
end