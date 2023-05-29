module LuckyTemplate
  # An interface for `File`.
  module Fileable
    # Appends contents to `IO` for `File`
    abstract def to_file(io : IO) : Nil
  end

  alias FileProc = IO ->

  # :nodoc:
  alias FileType = String | Fileable | FileProc | Nil

  # A `File` represents the contents of a file.
  class File
    protected def initialize(@file : FileType)
    end

    # Appends file contents to `IO`
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
