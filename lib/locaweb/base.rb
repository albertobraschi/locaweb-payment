module Locaweb
  class Base
    # Hold the YAML configuration file
    CONFIG = {}
    
    # The config file path
    CONFIG_FILE = File.dirname(__FILE__) + "/../../../../../config/locaweb-payment.yml"
    
    # Return the configuration for the current environment
    def config
      CONFIG[RAILS_ENV]
    end
    
    # Load the configuration and set it to the CONFIG constant
    def self.config!
      CONFIG.merge!(YAML.load_file(CONFIG_FILE))
    end
  end
end