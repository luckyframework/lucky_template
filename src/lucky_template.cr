require "./lucky_template/version"
require "./lucky_template/*"

# Public interface
module LuckyTemplate
  extend self

  # A `LuckyTemplate::Snapshot` represents files and folders included within a `LuckyTemplate::Folder` at a moment in time
  #
  # **Key:** String path in **POSIX** form
  #
  # **Value:** Type of `LuckyTemplate::FileSystem`
  alias Snapshot = Hash(String, FileSystem)

  # Creates a `Folder` and yields it, before returning the **unlocked** `Folder`
  #
  # NOTE: `Folder` is **locked** when being yielded. See `Folder#locked?`.
  #
  # Example:
  # ```
  # folder = LuckyTemplate.create_folder do |dir|
  #   dir.locked? # => true
  #   dir.add_file(".keep")
  # end
  # folder.locked? # => false
  # ```
  def create_folder(& : Folder ->) : Folder
    Folder.new.tap do |folder|
      folder.lock do
        yield folder
      end
    end
  end

  # Creates an empty `Folder`
  #
  # Example:
  # ```
  # folder = LuckyTemplate.create_folder
  # folder.locked? # => false
  # ```
  def create_folder : Folder
    create_folder { }
  end

  # Writes the folder to disk at the given _location_
  #
  # Raises `Error` if _folder_ is **locked**
  #
  # Raises `::File::AlreadyExistsError` if _location_ is not an existing folder
  #
  # Example:
  # ```
  # templates_folder = LuckyTemplate.create_folder
  # LuckyTemplate.write!(Path["./templates"], templates_folder)
  # ```
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

  # Shorthand for `.create_folder` and `.write!`
  #
  # Example:
  # ```
  # folder = LuckyTemplate.write!(Path["./templates"]) do |templates_folder|
  #   templates_folder.add_file(".keep")
  # end
  # ```
  def write!(location : Path, & : Folder ->) : Folder
    create_folder do |folder|
      yield folder
    end.tap do |folder|
      write!(location, folder)
    end
  end

  # Returns `true` if the _folder_ is **valid** at the given _location_
  #
  # **valid** - files and folders exist within the given _location_
  #
  # NOTE: **Does not** check _contents_ of files, only the presence of them in the filesystem
  #
  # Raises `::File::NotFoundError` if either a file or folder does not exist
  #
  # Raises `Error` if _folder_ is **locked**
  #
  # Example:
  # ```
  # begin
  #   templates_folder = LuckyTemplate.create_folder
  #   LuckyTemplate.validate!(Path["./templates"], templates_folder) # => true
  # rescue err : ::File::NotFoundError
  #   puts err.message
  # end
  # ```
  def validate!(location : Path, folder : Folder) : Bool
    if folder.locked?
      raise Error.new("Cannot validate while folder is locked")
    end
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

  # Returns a `Bool` if the _folder_ is **valid** at the given _location_
  #
  # **valid** - files and folders exist within the given _location_
  #
  # NOTE: **Does not** check _contents_ of files, only the presence of them in the filesystem
  #
  # Example:
  # ```
  # templates_folder = LuckyTemplate.create_folder
  # LuckyTemplate.validate!(Path["./templates"], templates_folder) # => true
  # ```
  def validate?(location : Path, folder : Folder) : Bool
    validate!(location, folder)
  rescue
    false
  end

  # Returns a new `Snapshot` of all files and folders within this _folder_
  #
  # Raises `Error` if _folder_ is **locked**
  #
  # NOTE: **Does not** include file instances in results, only paths
  #
  # Example:
  # ```
  # folder = LuckyTemplate.create_folder do |dir|
  #   dir.add_file(".keep")
  #   dir.add_file("README.md")
  #   dir.add_folder("src") do |src|
  #     src.add_file("hello.cr")
  #   end
  # end
  # puts LuckyTemplate.snapshot(folder)
  # ```
  #
  # Output:
  # ```
  # {
  #   ".keep"        => LuckyTemplate::FileSystem::File,
  #   "README.md"    => LuckyTemplate::FileSystem::File,
  #   "src"          => LuckyTemplate::FileSystem::Folder,
  #   "src/hello.cr" => LuckyTemplate::FileSystem::File,
  # }
  # ```
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
