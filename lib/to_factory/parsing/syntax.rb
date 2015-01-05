module ToFactory
  module Parsing
    class Syntax
      attr_accessor :contents

      def initialize(contents)
        @contents = contents
      end

      def multiple_factories?
        factories_sexp[0] == :block
      end

      def parse
        result = {}
        @klass_inference = KlassInference.new

        parse_multiple do |factory_name, parent_name, ruby|
          klass = @klass_inference.infer(factory_name, parent_name)
          result[klass] ||= {}
          result[klass][factory_name] = ruby
        end

        result
      end

      def factories
        if multiple_factories?
          factories_sexp[1..-1]
        else
          [factories_sexp]
        end
      end

      def factories_sexp
        header? ?  sexp[3] : sexp
      end

      def parse_multiple(&block)
        factories.each do |x|
          yield name_from(x), parent_from(x), to_ruby(x)
        end
      end

      def parent_from(x)
        x[1][-1][-1][-1] rescue name_from(x)
      end

      def name_from(sexp)
        sexp[1][3][1]
      end

      private

      def to_ruby(sexp)
        ruby2ruby.process sexp.deep_clone
      end

      def sexp
        @sexp ||= ruby_parser.process(@contents)
      end

      def ruby2ruby
        @ruby2ruby ||= Ruby2Ruby.new
      end

      def ruby_parser
        @ruby_parseer ||= RubyParser.new
      end

      class KlassInference
        def initialize
          @mapping = {}
        end

        def infer(klass, parent_klass=nil)
          @mapping[klass] ||= klass.to_s.camelize.constantize
        rescue
          infer(parent_klass)
        end
      end


    end
  end
end
