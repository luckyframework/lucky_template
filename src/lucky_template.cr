require "./lucky_template/version"
require "./lucky_template/*"

module LuckyTemplate
  extend self

  def create_parent_folder(& : Folder ->) : Folder
    parent_folder = Folder.new
    parent_folder.lock do
      yield parent_folder
    end
    parent_folder
  end

  def write!(location : Path, folder : Folder) : Nil
    Dir.mkdir_p(location)
    folder.write_to_disk!(location)
  end

  # Same as `#create_parent_folder` and `#write!`
  def write!(location : Path, & : Folder ->) : Folder
    folder = create_parent_folder do |parent_folder|
      yield parent_folder
    end
    write!(location, folder)
    folder
  end

  # Validates _folder_ at _location_ contains the same files and folders
  #
  # Raises `::File::NotFoundError` if either a file or folder does not exist
  def validate!(location : Path, folder : Folder) : Bool
    folder.validate!(location)
  end

  # Validates _folder_ at _location_ contains the same files and folders
  def validate?(location : Path, folder : Folder) : Bool
    folder.validate?(location)
  end

  def snapshot_files(folder : Folder)
    folder.snapshot_files
  end
end
