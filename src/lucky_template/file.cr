module LuckyTemplate
  module Fileable
    abstract def to_file(io : IO) : Nil
  end

  alias FileType = String | Fileable | Nil

  class File
    getter name : String

    def initialize(@name, @file : FileType)
    end

    def to_s(io : IO) : Nil
      case @file
      in Fileable
        @file.to_file(io)
      in String, Nil
        @file.to_s(io)
      end
    end
  end
end
