module Puffin
  class Message < APIResource
    extend Puffin::APIOperations::Create
    extend Puffin::APIOperations::List
  end
end

