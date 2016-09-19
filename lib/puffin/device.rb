module Puffin
  class Device < APIResource
    extend Puffin::APIOperations::List
    extend Puffin::APIOperations::Create
    # include Puffin::APIOperations::Save
  end
end
