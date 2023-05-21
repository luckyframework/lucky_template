module LuckyTemplate
  module Fileable
    abstract def to_file(io : IO) : Nil
  end

  alias FileProc = IO ->

  alias FileType = String | Fileable | FileProc | Nil

  class File
    def initialize(@file : FileType)
    end

    def to_s(io : IO) : Nil
      case file = @file
      in Fileable
        file.to_file(io)
      in FileProc
        file.call(io)
      in String, Nil
        file.to_s(io)
      end
    end
  end
end
