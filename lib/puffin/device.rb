module Puffin
  class Device < APIResource
    extend Puffin::APIOperations::List
    extend Puffin::APIOperations::Create
    include Puffin::APIOperations::Save
    def self.oh
      puts 11111111111111111111111111111111
      puts 11111111111111111111111111111111
      puts 11111111111111111111111111111111
      puts 11111111111111111111111111111111
    end
  end
end
