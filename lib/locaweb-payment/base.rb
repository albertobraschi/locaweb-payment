module Locaweb
  class Base
    # Hold the YAML configuration file
    CONFIG = {}
    
    # The config file path
    CONFIG_FILE = File.dirname(__FILE__) + "/../../../../../config/locaweb-payment.yml"
    
    # Return the configuration for the current environment
    def config
      Locaweb::Base::CONFIG[RAILS_ENV]
    end
    
    # Load the configuration and set it to the CONFIG constant
    def self.config!
      Locaweb::Base::CONFIG.merge!(YAML.load_file(CONFIG_FILE))
    end
    
    def self.config_file=(path)
      Locaweb::Base::CONFIG_FILE.gsub!(/^.*?$/, path)
    end
    
    # Ported silence_warnings method from rails to remove ActiveSupport dependency
    def silence_warnings
    	old_verbose, $VERBOSE = $VERBOSE, nil
      yield
    ensure
      $VERBOSE = old_verbose
    end
  end
end