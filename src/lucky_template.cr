require "./lucky_template/version"
require "./lucky_template/*"

module LuckyTemplate
  extend self

  # Creates a new `LuckyTemplate::Folder` with _name_ and yields it
  def create_folder(name : String, & : Folder ->) : Folder
    folder = Folder.new(name)
    folder.in_use do
      yield folder
    end
    folder
  end

  # Creates a new `LuckyTemplate::Folder` with _name_
  def create_folder(name : String) : Folder
    create_folder(name) { }
  end

  # Writes _folder_ to disk at _location_
  def write!(location : Path, folder : Folder) : Nil
    path = location.expand
    Dir.mkdir_p(path)
    folder.write_to_disk!(path)
  end

  # Writes yielded _folder_ to _location_ dirname, using _location_ basename
  # as name of _folder_
  def write!(location : Path, & : Folder ->) : Nil
    path = location.expand
    dirname = Path.new(path.dirname)
    Dir.mkdir_p(dirname)
    folder = Folder.new(path.basename)
    folder.in_use do
      yield folder
    end
    folder.write_to_disk!(dirname)
  end

  # Validates _folder_ at _location_ contains the same files and folders
  #
  # Raises `::File::NotFoundError` if either a file or folder does not exist
  def validate!(location : Path, folder : Folder) : Bool
    path = location.expand
    folder.validate!(path)
  end

  # Validates _folder_ at _location_ contains the same files and folders
  def validate?(location : Path, folder : Folder) : Bool
    path = location.expand
    folder.validate?(path)
  end

  def snapshot_files(folder : Folder)
    folder.snapshot_files
  end

  # Spec helper to validate files and folders during testing
  def be_valid_at(location : Path)
    FolderValidExpectation.new(location)
  end

  private struct FolderValidExpectation
    def initialize(@location : Path)
    end

    def match(actual_value) : Bool
      LuckyTemplate.validate?(@location, actual_value)
    end

    def failure_message(actual_value) : String
      "Expected: All files and folders within Folder to exist"
    end

    def negative_failure_message(actual_value) : String
      "Expected: All files and folders within Folder not to exist"
    end
  end
end
