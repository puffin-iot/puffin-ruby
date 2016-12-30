module Puffin
  class Action < APIResource
    extend Puffin::APIOperations::Create
    include Puffin::APIOperations::Delete
    include Puffin::APIOperations::Save
  end
end
