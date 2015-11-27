module CsvShaper
  
  # Row
  # Handles creating of cells within a row and
  # assigning of the model's values to cells
  # Examples:
  # ```
  # # pass a model to the row
  # csv.row @model do |csv, model|
  #   ...
  # end
  # 
  # # create an empty row instance
  # csv.row do |csv|
  #   ...
  # end
  # 
  # # create a row with prefilled cells from a model
  # # note no block is passed
  # csv.row @model, :name, :age, :location
  # ```
  class Row
    attr_reader :model, :cells, :shaper
    
    def initialize(*args)
      @cells = ActiveSupport::OrderedHash.new
      options = args.last.is_a?(Hash) ? args.pop : {}
      @shaper = options[:shaper] || options['shaper']
      if args.one?
        @model = args.first
        yield self, @model if block_given?
      elsif args.empty?
        yield self if block_given?
      elsif args.length > 1
        @model = args.shift
        args.each { |col| cell(col) }
      else
        raise ArgumentError, 'invalid args passed to csv.row'
      end        
    end
    
    # Public: assign the given Array of args to cells in this Row
    #
    # `args` - Array of the arguments passed (expected to be Symbols)
    #
    # Returns an Array of the Cells in this row
    def cells(*args)
      args.each do |col|
        col.is_a?(Hash) ? col.each{|k,v| cell({k => v})} : cell(col)
      end
      @cells
    end
    
    # Public: add a cell to this Row
    # If the Row has a @model defined passing just a Symbol will
    # call that method on the @model and assign it to a column of
    # the same name. Otherwise a value will need to be passed also
    #
    # `column` - Symbol of the column to add to value to
    # `value` - data to assign to the cell (default: nil)
    #
    # Returns an Array of the Row's cells
    def cell(*args)
      if args.empty?
        raise ArgumentError, 'no args passed to #cell, you must pass at least a column name'
      end
      
      column = args.first
      column, method = column.is_a?(Hash) ? [column.keys.first.to_sym, column.values.first.to_sym] : [column.to_sym, column.to_sym]
      
      if args.size == 2
        @cells[column] = args.last
      elsif args.size == 1
        if @model && @model.respond_to?(method)
          @cells[column] = @model.send(method)
        else
          raise ArgumentError, "##{method} is not a method on #{@model.class.to_s}, call `csv.cell #{column}, value` instead"
        end
      else
        raise ArgumentError, 'you can pass a column or a column with a value to #cell'
      end
      
      @cells
    end

    def build
      raise ArgumentError, 'you can pass a block to #build' unless block_given?
      if @model
        yield self, @model
      else
        yield self
      end
    end

    def row(*args, &block)
      shaper.row(*args, &block)
    end

    def rows(collection = nil, &block)
      shaper.rows(collection, &block)
    end
  end
end
