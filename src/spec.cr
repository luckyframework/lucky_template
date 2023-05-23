module LuckyTemplate
  module Spec
    extend self

    def be_valid_at(location : Path)
      FolderValidExpectation.new(location)
    end

    private struct FolderValidExpectation
      def initialize(@location : Path)
      end

      def match(actual_value : Folder) : Bool
        LuckyTemplate.validate?(@location, actual_value)
      end

      def failure_message(actual_value : Folder) : String
        "Expected: All files and folders within Folder to exist"
      end

      def negative_failure_message(actual_value : Folder) : String
        "Expected: All files and folders within Folder not to exist"
      end
    end
  end
end
