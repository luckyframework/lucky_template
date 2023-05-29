module LuckyTemplate
  # An interface for a file
  #
  # Simple example using IO:
  # ```
  # class Hello
  #   include LuckyTemplate::Fileable
  #
  #   def to_file(io : IO) : Nil
  #     io << "hello"
  #   end
  # end
  # ```
  #
  # Example using ECR templates:
  # ```
  # require "ecr"
  #
  # class Hello
  #   include LuckyTemplate::Fileable
  #
  #   def to_file(io : IO) : Nil
  #     to_s(io)
  #   end
  #
  #   ECR.def_to_s "hello.ecr"
  # end
  # ```
  #
  # Example using Process to run `envsubst`:
  # ```
  # class Hello
  #   include LuckyTemplate::Fileable
  #
  #   def to_file(io : IO) : Nil
  #     input = IO::Memory.new("Hello $NAME!")
  #     Process.run(
  #       command: "envsubst",
  #       input: input,
  #       output: io,
  #       env: {
  #         "NAME" => "World",
  #       }
  #     )
  #   end
  # end
  # ```
  module Fileable
    # Appends contents to `IO` for a file
    abstract def to_file(io : IO) : Nil
  end

  alias FileIO = IO ->

  # :nodoc:
  alias FileType = String | Fileable | FileIO | Nil

  # :nodoc:
  class File
    protected def initialize(@file : FileType)
    end

    # Appends file contents to `IO`
    def to_s(io : IO) : Nil
      case file = @file
      in Fileable
        file.to_file(io)
      in FileIO
        file.call(io)
      in String, Nil
        file.to_s(io)
      end
    end
  end
end
