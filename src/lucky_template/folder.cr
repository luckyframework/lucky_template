module LuckyTemplate
  class Folder
    alias Files = File | Folder
    alias Snapshot = Hash(String, FileSystem)

    @files = {} of String => Files
    @locked = false

    # Adds a new `File` to the folder with static _content_
    def add_file(name : String, content : String) : self
      insert_file(name, File.new(content))
    end

    # Adds a new `File` to the folder with `Fileable` interface
    def add_file(name : String, klass : Fileable) : self
      insert_file(name, File.new(klass))
    end

    # Adds a new `File` to the folder yielding an `IO`
    def add_file(name : String, &block : FileProc) : self
      insert_file(name, File.new(block))
    end

    # Adds a new empty `File` to the folder
    def add_file(name : String) : self
      insert_file(name, File.new(nil))
    end

    private def insert_file(name : String, file : File) : self
      @files[name] = file
      self
    end

    def add_folder(*names : String, & : Folder ->) : self
      prev : Folder? = nil
      names.each_with_index do |name, index|
        current_folder = Folder.new
        if index == names.size - 1
          current_folder.lock do
            yield current_folder
          end
        end
        if prev_folder = prev
          prev_folder.insert_folder(name, current_folder)
        else
          insert_folder(name, current_folder)
        end
        prev = current_folder
      end
      self
    end

    def add_folder(*names : String) : self
      add_folder(*names) { }
    end

    def insert_folder(name : String, folder : Folder) : self
      if folder == self
        raise Error.new("Cannot add Folder equal to itself")
      elsif folder.locked?
        raise Error.new("Cannot add Folder that is already being yielded")
      end
      @files[name] = folder
      self
    end

    # Locks the folder for as long as block yields
    #
    # To be used as a safe-guard to protect against circular references.
    protected def lock(&) : Nil
      @locked = true
      yield
    ensure
      @locked = false
    end

    # TODO: write description
    def locked? : Bool
      @locked
    end

    protected def files
      @files
    end

    # Writes the folder to disk at the given path
    protected def write_to_disk!(path : Path) : Nil
      if locked?
        raise Error.new("Cannot write to disk while being yielded")
      end
      write_folder_to_disk!(path, self)
    end

    # NOTE: Recursive
    private def write_folder_to_disk!(prev_path : Path, folder : Folder) : Nil
      folder.files.each do |name, file|
        path = prev_path / name
        case file
        in File
          ::File.open(path, "w") do |io|
            file.to_s(io)
          end
        in Folder
          Dir.mkdir_p(path)
          write_folder_to_disk!(path, file)
        end
      end
    end

    # Returns `true` if the folder is _valid_ at the given path
    #
    # _valid_ - Files and folder exist within the given path
    #
    # Raises `::File::NotFoundError` if either a file or folder does not exist
    protected def validate!(location : Path) : Bool
      snapshot_files.each do |filepath, type|
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
    protected def validate?(location : Path) : Bool
      validate!(location)
    rescue
      false
    end

    # Returns a new `Snapshot` of all files and folders within this folder
    protected def snapshot_files : Snapshot
      if locked?
        raise Error.new("Cannot get snapshot while being yielded")
      end
      Snapshot.new.tap do |snapshot|
        snapshot_folder(Path.new, self, snapshot)
      end
    end

    # NOTE: Recursive
    private def snapshot_folder(prev_path : Path, folder : Folder, snapshot : Snapshot) : Nil
      folder.files.each do |name, file|
        path = prev_path / name
        case file
        in File
          snapshot[path.to_s] = FileSystem::File
        in Folder
          snapshot[path.to_s] = FileSystem::Folder
          snapshot_folder(path, file, snapshot)
        end
      end
    end
  end
end
