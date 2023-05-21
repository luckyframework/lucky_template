module LuckyTemplate
  enum FileSystem
    File
    Folder
  end

  class Folder
    alias Files = File | Folder

    @files = {} of String => Files
    @in_use = false # TODO: rename to initializing

    # NOTE: static content
    def add_file(name : String, content : String) : self
      _add_file(name, File.new(content))
      self
    end

    # NOTE: inheritance - dynamic content
    def add_file(name : String, klass : Fileable) : self
      _add_file(name, File.new(klass))
      self
    end

    # NOTE: ECR.embed(io) - dynamic content
    def add_file(name : String, &block : FileProc) : self
      _add_file(name, File.new(block))
      self
    end

    # NOTE: empty - static content
    #
    # Adds empty `LuckyTemplate::File` to `LuckyTemplate::Folder`
    def add_file(name : String) : self
      _add_file(name, File.new(nil))
      self
    end

    # TODO: check for name collision
    private def _add_file(name : String, file : File) : Nil
      @files[name] = file
    end

    # Adds empty `LuckyTemplate::Folder`s
    def add_folder(*names : String) : self
      add_folder(*name) { }
      self
    end

    # src/emails
    # .add_folder("src", "emails") { |f| f... } # f == "emails"
    def add_folder(*names : String, & : Folder ->) : self
      prev : Folder? = nil
      names.each_with_index do |name, index|
        current_folder = Folder.new
        if index == names.size - 1
          current_folder.in_use do
            yield current_folder
          end
        end
        if prev_folder = prev
          prev_folder._add_folder(name, current_folder)
        else
          @files[name] = current_folder
        end
        prev = current_folder
      end
      self
    end

    protected def _add_folder(name : String, folder : Folder) : Nil
      if folder == self
        raise Error.new("Folder cannot add itself")
      elsif @in_use
        raise Error.new("Parent folder already in-use")
      end

      @files[name] = folder
    end

    # Used as a safe-guard to protect against circular references
    protected def in_use(&)
      @in_use = true
      yield
    ensure
      @in_use = false
    end

    protected def files
      @files
    end

    # Writes the folder to disk at the given path
    protected def write_to_disk!(path : Path) : Nil
      write_folder_to_disk!(path, self)
    end

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
          ::File.size(path) # TODO: replace w/ custom error
        in .folder?
          Dir.open(path) { } # TODO: replace w/ custom error
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

    alias Snapshot = Hash(String, FileSystem)

    protected def snapshot_files : Snapshot
      Snapshot.new.tap do |snapshot|
        snapshot_folder(Path.new, self, snapshot)
      end
    end

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
