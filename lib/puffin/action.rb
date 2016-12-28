module Puffin
  class Action < APIResource
    extend Puffin::APIOperations::Create
    # extend Puffin::APIOperations::List
    include Puffin::APIOperations::Delete
    include Puffin::APIOperations::Save
  end
end
