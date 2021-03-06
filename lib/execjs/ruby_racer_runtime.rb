module ExecJS
  class RubyRacerRuntime
    class Context
      def initialize(source = "")
        @v8_context = ::V8::Context.new
        @v8_context.eval(source)
      end

      def exec(source, options = {})
        souce = source.encode('UTF-8') if source.respond_to?(:encode)

        if /\S/ =~ source
          eval "(function(){#{source}})()", options
        end
      end

      def eval(source, options = {})
        souce = source.encode('UTF-8') if source.respond_to?(:encode)

        if /\S/ =~ source
          unbox @v8_context.eval("(#{source})")
        end
      rescue ::V8::JSError => e
        if e.value["name"] == "SyntaxError"
          raise RuntimeError, e.message
        else
          raise ProgramError, e.message
        end
      end

      def call(properties, *args)
        unbox @v8_context.eval(properties).call(*args)
      rescue ::V8::JSError => e
        if e.value["name"] == "SyntaxError"
          raise RuntimeError, e.message
        else
          raise ProgramError, e.message
        end
      end

      def unbox(value)
        case value
        when ::V8::Function
          nil
        when ::V8::Array
          value.map { |v| unbox(v) }
        when ::V8::Object
          value.inject({}) do |vs, (k, v)|
            vs[k] = unbox(v) unless v.is_a?(::V8::Function)
            vs
          end
        when String
          value.respond_to?(:force_encoding) ?
            value.force_encoding('UTF-8') :
            value
        else
          value
        end
      end
    end

    def name
      "therubyracer (V8)"
    end

    def exec(source)
      context = Context.new
      context.exec(source)
    end

    def eval(source)
      context = Context.new
      context.eval(source)
    end

    def compile(source)
      Context.new(source)
    end

    def available?
      require "v8"
      true
    rescue LoadError
      false
    end
  end
end
