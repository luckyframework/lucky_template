require "file_utils"

module LuckyTemplate
  extend self

  VERSION = {{ `shards version #{__DIR__}`.chomp.stringify }}

  module LuckyTemplateable
    abstract def to_lucky_template(io : IO) : Nil
  end

  alias LuckyFileType = String | LuckyTemplateable | Nil

  class LuckyFile
    getter name : String

    def initialize(@name, @file : LuckyFileType)
    end

    def to_s(io : IO) : Nil
      case @file
      in LuckyTemplateable
        @file.to_lucky_template(io)
      in String, Nil
        @file.to_s(io)
      end
    end
  end

  class InvalidFolderName < Exception
    def initialize(message = "Invalid folder name", cause : Exception? = nil)
      super(message, cause: cause)
    end
  end

  class LuckyFolder
    alias FileType = LuckyFile | LuckyFolder
    getter name : String
    getter files = [] of FileType

    # Writes folder to disk at path
    def self.write!(location : Path, folder : LuckyFolder) : Nil
      path = location.expand
      FileUtils.mkdir_p(path)
      folder.write_to_disk!(path)
    end

    # Writes folder from path to disk at path dirname
    def self.write!(location : Path, & : LuckyFolder ->) : Nil
      path = location.expand
      dirname = Path.new(path.dirname)
      FileUtils.mkdir_p(dirname)
      folder = LuckyFolder.new(path.basename)
      yield folder
      folder.write_to_disk!(dirname)
    end

    def initialize(@name : String)
      raise InvalidFolderName.new if @name.empty?
    end

    def add_file(name : String, file : LuckyFileType) : Nil
      add_file(LuckyFile.new(name, file))
    end

    def add_file(file : LuckyFile) : Nil
      @files << file
    end

    def add_folder(name : String) : Nil
      add_folder(name) { }
    end

    def add_folder(name : String, & : LuckyFolder ->) : Nil
      folder = LuckyFolder.new(name)
      yield folder
      @files << folder
    end

    protected def write_to_disk!(path : Path) : Nil
      write_folder_to_disk!(path, self)
    end

    private def write_file_to_disk!(path : Path, file : LuckyFile) : Nil
      File.open(path.join(file.name), "w") do |io|
        file.to_s(io)
      end
    end

    private def write_folder_to_disk!(path : Path, folder : LuckyFolder) : Nil
      new_path = path.join(folder.name)
      Dir.mkdir_p(new_path)
      folder.files.each do |file|
        case file
        in LuckyFile
          write_file_to_disk!(new_path, file)
        in LuckyFolder
          write_folder_to_disk!(new_path, file)
        end
      end
    end
  end
end
