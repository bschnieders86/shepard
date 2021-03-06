module Vis
  module Network
    class Edge
      attr_accessor :from, :to, :type
      attr_writer :options

      def initialize(from, to, type, options = {})
        @from = from
        @to = to
        @type = type
        @options = options

      end

      def to_hash
        {
          :from => from.id,
          :to => to.id,
        }.merge(@options)
      end

      private

    end
  end
end
