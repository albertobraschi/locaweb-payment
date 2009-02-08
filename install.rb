to   = File.dirname(__FILE__) + "/../../../config/locaweb-payment.yml"
from = File.dirname(__FILE__) + "/locaweb-payment.yml"

if File.exists?(to)
  puts "Configuration file detected at config/locaweb-payment.yml; skipping copy."
else
  File.open(to, "w+") do |file|
    file << File.read(from)
  end
  
  puts "Configuration file copied; make sure you configure the file\nconfig/locaweb-payment.yml accordingly."
end