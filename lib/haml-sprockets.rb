require 'haml-sprockets/version'
require 'tilt'
require 'sprockets'

module Haml
  module Sprockets
    class Template < ::Tilt::Template
      self.default_mime_type = 'application/javascript'

      def self.engine_initialized?
        defined? ::ExecJS
      end

      def initialize_engine
        require_template_library 'execjs'
      end

      def prepare
      end

      def evaluate(scope, locals, &block)
        haml_code = data.dup
        haml_code = haml_code.gsub(/\\/,"\\\\").gsub(/\'/,"\\\\'").gsub("\n","\\n")

        haml_path = File.join(File.dirname(__FILE__), "../vendor/assets/javascripts/haml.js")
        haml_lib = File.read(haml_path)
        context = ExecJS.compile(haml_lib)

        js = context.eval "Haml.optimize(Haml.compile('#{haml_code}', {escapeHtmlByDefault: true}))"
        escapeJs = context.eval "Haml.html_escape.toString()"

        <<-JST
function(local) { 
  #{escapeJs}
  with (local || {}) {
    return #{js}
  }
}
        JST
      end
    end
  end
end

Sprockets::Engines
Sprockets.register_engine '.hamljs', Haml::Sprockets::Template
require 'haml-sprockets/engine' if defined?(Rails) && Rails.version =~ /^3/
