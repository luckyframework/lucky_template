require "./lucky_template/version"
require "./lucky_template/*"

module LuckyTemplate
  extend self

  alias Snapshot = Hash(String, FileSystem)

  def create_folder(& : Folder ->) : Folder
    Folder.new.tap do |folder|
      folder.lock do
        yield folder
      end
    end
  end

  # Writes the folder to disk at the given path
  #
  # Raises `LuckyTemplate::Error` if folder is locked
  def write!(location : Path, folder : Folder) : Nil
    Dir.mkdir_p(location)
    if folder.locked?
      raise Error.new("Cannot write to disk if folder is locked")
    end
    write_folder!(location, folder)
  end

  # NOTE: Recursive
  private def write_folder!(prev_path : Path, folder : Folder) : Nil
    folder.files.each do |name, file|
      path = prev_path / name
      case file
      in File
        ::File.open(path, "w") do |io|
          file.to_s(io)
        end
      in Folder
        Dir.mkdir_p(path)
        write_folder!(path, file)
      end
    end
  end

  # Same as `#create_folder` and `#write!`
  def write!(location : Path, & : Folder ->) : Folder
    create_folder do |folder|
      yield folder
    end.tap do |folder|
      write!(location, folder)
    end
  end

  # Returns `true` if the folder is _valid_ at the given path
  #
  # _valid_ - Files and folder exist within the given path
  #
  # Raises `::File::NotFoundError` if either a file or folder does not exist
  def validate!(location : Path, folder : Folder) : Bool
    snapshot(folder).each do |filepath, type|
      path = location / filepath
      case type
      in .file?
        ::File.size(path)
      in .folder?
        Dir.open(path) { }
      end
    end
    true
  end

  # Returns a `Bool` if the folder is _valid_ at the given path
  #
  # _valid_ - Files and folder exist within the given path
  def validate?(location : Path, folder : Folder) : Bool
    validate!(location, folder)
  rescue
    false
  end

  # Returns a new `Snapshot` of all files and folders within this folder
  #
  # Raises `LuckyTemplate::Error` if folder is locked
  def snapshot(folder : Folder) : Snapshot
    if folder.locked?
      raise Error.new("Cannot get snapshot if folder is locked")
    end
    Snapshot.new.tap do |_snapshot|
      snapshot_folder(Path.new, folder, _snapshot)
    end
  end

  # NOTE: Recursive
  private def snapshot_folder(prev_path : Path, folder : Folder, _snapshot : Snapshot) : Nil
    folder.files.each do |name, file|
      path = prev_path / name
      key = path.to_posix.to_s
      case file
      in File
        _snapshot[key] = FileSystem::File
      in Folder
        _snapshot[key] = FileSystem::Folder
        snapshot_folder(path, file, _snapshot)
      end
    end
  end
end
