Locaweb Payment
===============

Brazilian payment gateway [PagamentoCerto](http://www.pagamentocerto.com.br/) wrapper for Ruby On Rails.

This is a **WORKING IN PROGRESS** and many things can be changed.

Installation
------------

1. Install the plugin with `script/plugin install git://github.com/fnando/locaweb-payment.git`
2. Install the dependencies with `sudo gem install hpricot builder soap4r`
3. Configure the file `config/locaweb-payment.yml`

Usage
-----

	@payment = Locaweb::Payment.new
	
	# set the buyer info
	@payment.buyer = {
	  :name  => "John Doe",
	  :email => "john@doe.com",
	  :cpf   => "12345678912",
	  :rg    => "124567890",
	  :phone => "1234567890",
	  :type  => :person,
	  :address => [
	    "Avenida Paulista",
		"Apto 12-B",
		"1711",
		"Bela Vista",
		"São Paulo",
		"SP",
		"01311200"
	  ]
	}
	
	# order details (credit card can be :visa or :amex)
	@payment.order = {
	  :id => 1234,
	  :shipping => 3.50,
	  :payment  => [:credit_card, :visa]
	}
	
	# order details (invoice)
	@payment.order = {
	  :id => 1234,
	  :shipping => 3.50,
	  :payment => :invoice
	}
	
	# the URL your customer will be sent to after completing the transaction
	@payment.return_to = "http://example.com/thanks"

	# adding products to your order
	@payment.items << {:id => 1, :description => "Geek T-shirt", :price => 10.99}
	@payment.items << {:id => 2, :description => "Geek Keychain", :price => 3.99, :quantity => 2}
	
	# place a new invoice
	result = @payment.process
	
	# retrieve the transaction message
	result.message
	
	# retrieve the transaction id
	result.id
	
	# retrieve the transaction status code
	result.status
	
	# retrieve the transaction code
	result.code
	
	# this transaction has been started successfuly?
	result.success?
	
	# redirect to the payment page
	redirect_to result.url
	
	# if you want to regenerate the invoice
	redirect_to result.url(:invoice)
	
	# the return interface i'm thinking of
	payment = Locaweb::Return.new("29851115-b060-48fc-8c31-8e78cff5b5d5")
	payment.process!
	
	# true if is credit card and was processed
	# true if is invoice and has been paid
	payment.confirmed?
	
	payment.message
	payment.status
	payment.id

TO-DO
-----

* Add developer mode
* Implement the Return class
* Handle return codes properly
* Add full example

LICENSE:
--------

(The MIT License)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.