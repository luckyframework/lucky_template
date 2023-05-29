module LuckyTemplate
  module Spec
    extend self

    # Validates all files and folders exist within the given _location_
    def be_valid_at(location : Path)
      BeValidAtExpectation.new(location)
    end

    private class BeValidAtExpectation
      property ex : ::File::NotFoundError?

      def initialize(@location : Path)
      end

      def match(actual_value : Folder) : Bool
        LuckyTemplate.validate!(@location, actual_value)
      rescue e : ::File::NotFoundError
        self.ex = e
        false
      rescue
        false
      end

      def failure_message(actual_value : Folder) : String
        if error = ex
          String.build do |io|
            io << "Expected: The following file/directory to exist"
            io << "\n"
            io << "  - "
            io << error.file
          end
        else
          "Expected: All files and folders within Folder to exist"
        end
      end

      def negative_failure_message(actual_value : Folder) : String
        if error = ex
          String.build do |io|
            io << "Expected: The following file/directory not to exist"
            io << "\n"
            io << "  - "
            io << error.file
          end
        else
          "Expected: All files and folders within Folder not to exist"
        end
      end
    end
  end
end
