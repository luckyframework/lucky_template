module LuckyTemplate
  # A `Folder` represents a filesystem directory, but in a virtual form.
  class Folder
    # :nodoc:
    alias Files = File | Folder

    # :nodoc:
    DOT_PATHS = ["..", ".", "~"]

    @files = {} of String => Files
    @locked = false

    protected def initialize
    end

    # Adds a new file to the folder with _content_
    #
    # Optionally, provide _perms_ to specify file permissions
    #
    # Raises `Error` if _name_ contains invalid path(s)
    #
    # Examples(s):
    # ```
    # add_file("hello.txt", "hello world")
    #
    # add_file("hello.txt", <<-TEXT)
    # hello world
    # TEXT
    #
    # add_file("hello.txt", "hello world", 0o644)
    # ```
    def add_file(name : String, content : String, perms : Int16? = nil) : self
      add_file(Path[name], content, perms)
    end

    # Adds a new file to the folder with _content_
    #
    # Optionally, provide _perms_ to specify file permissions
    #
    # Raises `Error` if _path_ contains invalid path(s)
    #
    # Examples(s):
    # ```
    # add_file(Path["./hello.txt"], "hello world")
    #
    # add_file(Path["./hello.txt"], <<-TEXT)
    # hello world
    # TEXT
    #
    # add_file(Path["./hello.txt"], "hello world", 0o644)
    # ```
    def add_file(path : Path, content : String, perms : Int16? = nil) : self
      add_file(path, File.new(content, perms))
    end

    # Adds a new file to the folder with _klass_ implementing `Fileable` interface
    #
    # Optionally, provide _perms_ to specify file permissions
    #
    # Raises `Error` if _name_ contains invalid path(s)
    #
    # Example(s):
    # ```
    # class Hello
    #   include LuckyTemplate::Fileable
    #
    #   def to_file(io : IO) : Nil
    #     io << "hello"
    #   end
    # end
    #
    # add_file("hello.txt", Hello.new)
    #
    # add_file("hello.txt", Hello.new, 0o644)
    # ```
    def add_file(name : String, klass : Fileable, perms : Int16? = nil) : self
      add_file(Path[name], klass, perms)
    end

    # Adds a new file to the folder with _klass_ implementing `Fileable` interface
    #
    # Optionally, provide _perms_ to specify file permissions
    #
    # Raises `Error` if _path_ contains invalid path(s)
    #
    # Example(s):
    # ```
    # class Hello
    #   include LuckyTemplate::Fileable
    #
    #   def to_file(io : IO) : Nil
    #     io << "hello"
    #   end
    # end
    #
    # add_file(Path["./hello.txt"], Hello.new)
    #
    # add_file(Path["./hello.txt"], Hello.new, 0o644)
    # ```
    def add_file(path : Path, klass : Fileable, perms : Int16? = nil) : self
      add_file(path, File.new(klass, perms))
    end

    # Adds a new file to the folder yielding an `IO`
    #
    # Optionally, provide _perms_ to specify file permissions
    #
    # Raises `Error` if _name_ contains invalid path(s)
    #
    # Example(s):
    # ```
    # add_file("hello.txt") do |io|
    #   ECR.embed("hello.ecr", io)
    # end
    #
    # add_file("hello.txt", 0o644) do |io|
    #   ECR.embed("hello.ecr", io)
    # end
    #
    # proc = LuckyTemplate::FileIO.new { |io| ECR.embed("hello.ecr", io) }
    # add_file("hello.txt", &proc)
    #
    # add_file("hello.txt", 0o644, &proc)
    # ```
    def add_file(name : String, perms : Int16? = nil, &block : FileIO) : self
      add_file(Path[name], perms, &block)
    end

    # Adds a new file to the folder yielding an `IO`
    #
    # Optionally, provide _perms_ to specify file permissions
    #
    # Raises `Error` if _path_ contains invalid path(s)
    #
    # Example(s):
    # ```
    # add_file(Path["./hello.txt"]) do |io|
    #   ECR.embed("hello.ecr", io)
    # end
    #
    # add_file(Path["./hello.txt"], 0o644) do |io|
    #   ECR.embed("hello.ecr", io)
    # end
    #
    # proc = LuckyTemplate::FileIO.new { |io| ECR.embed("hello.ecr", io) }
    # add_file(Path["./hello.txt"], &proc)
    #
    # add_file(Path["./hello.txt"], 0o644, &proc)
    # ```
    def add_file(path : Path, perms : Int16? = nil, &block : FileIO) : self
      add_file(path, File.new(block, perms))
    end

    # Adds a new empty file to the folder
    #
    # Optionally, provide _perms_ to specify file permissions
    #
    # Raises `Error` if _name_ contains invalid path(s)
    #
    # Example(s):
    # ```
    # add_file("hello.txt")
    #
    # add_file("hello.txt", 0o644)
    # ```
    def add_file(name : String, perms : Int16? = nil) : self
      add_file(Path[name], perms: perms)
    end

    # Adds a new empty file to the folder
    #
    # Optionally, provide _perms_ to specify file permissions
    #
    # Raises `Error` if _path_ contains invalid path(s)
    #
    # Example:
    # ```
    # add_file(Path["./hello.txt"])
    #
    # add_file(Path["./hello.txt"], 0o644)
    # ```
    def add_file(path : Path, perms : Int16? = nil) : self
      add_file(path, File.new(nil, perms))
    end

    private def add_file(path : Path, file : File) : self
      begin
        path = normalize_path(path)
      rescue Error
        raise Error.new("Cannot add file with invalid path(s)")
      end

      folders = path.parts
      filename = folders.pop

      if folders.empty?
        add_file(filename, file)
      else
        add_folder(folders) do |folder|
          folder.add_file(filename, file)
        end
      end
    end

    protected def add_file(name : String, file : File) : self
      @files[name] = file
      self
    end

    # Adds nested folders, yielding the last one
    #
    # Raises `Error` if _names_ contains invalid folder names
    #
    # Example:
    # ```
    # add_folder(["a", "b", "c"]) do |c|
    #   c.add_file("hello.txt")
    # end
    # ```
    #
    # Produces these folder paths:
    # ```text
    # a
    # a/b
    # a/b/c
    # a/b/c/hello.txt
    # ```
    def add_folder(names : Enumerable(String), & : Folder ->) : self
      begin
        names = normalize_path(Path[names]).parts
      rescue Error
        raise Error.new("Cannot add folders with invalid folder names")
      end

      prev : Folder? = nil
      names.each_with_index do |name, index|
        _folder : Folder = prev || self

        if found_file = _folder.files[name]?
          case found_file
          in Folder
            # If a Folder is found in folder with same name,
            # reuse Folder
            current_folder = found_file
          in File
            # If a File is found in folder with same name,
            # overwrite as Folder
            current_folder = Folder.new
          end
        else
          current_folder = Folder.new
        end

        if index == names.size - 1
          current_folder.lock do
            yield current_folder
          end
        end
        _folder.insert_folder(name, current_folder)

        prev = current_folder
      end
      self
    end

    # Adds nested folders, yielding the last one
    #
    # Raises `Error` if _path_ contains invalid folder names
    #
    # Example:
    # ```
    # add_folder(Path["a/b/c"]) do |c|
    #   c.add_file("hello.txt")
    # end
    # ```
    #
    # Produces these folder paths:
    # ```text
    # a
    # a/b
    # a/b/c
    # a/b/c/hello.txt
    # ```
    def add_folder(path : Path, & : Folder ->) : self
      add_folder(path.parts) do |folder|
        yield folder
      end
    end

    # Adds nested folders, yielding the last one
    #
    # Raises `Error` if _names_ contains invalid folder names
    #
    # Example:
    # ```
    # add_folder("a", "b", "c") do |c|
    #   c.add_file("hello.txt")
    # end
    # ```
    #
    # Produces these folder paths:
    # ```text
    # a
    # a/b
    # a/b/c
    # a/b/c/hello.txt
    # ```
    def add_folder(*names : String, & : Folder ->) : self
      add_folder(names) do |folder|
        yield folder
      end
    end

    # Adds nested empty folders
    #
    # Raises `Error` if _names_ contains invalid folder names
    #
    # Example:
    # ```
    # add_folder(["a", "b", "c", "d"])
    # ```
    #
    # Produces these folder paths:
    # ```text
    # a
    # a/b
    # a/b/c
    # a/b/c/d
    # ```
    def add_folder(names : Enumerable(String)) : self
      add_folder(names) { }
    end

    # Adds nested empty folders
    #
    # Raises `Error` if _path_ contains invalid folder names
    #
    # Example:
    # ```
    # add_folder(Path["a/b/c/d"])
    # ```
    #
    # Produces these folder paths:
    # ```text
    # a
    # a/b
    # a/b/c
    # a/b/c/d
    # ```
    def add_folder(path : Path) : self
      add_folder(path.parts) { }
    end

    # Adds nested empty folders
    #
    # Raises `Error` if _names_ contains invalid folder names
    #
    # Example:
    # ```
    # add_folder("a", "b", "c", "d")
    # ```
    #
    # Produces these folder paths:
    # ```text
    # a
    # a/b
    # a/b/c
    # a/b/c/d
    # ```
    def add_folder(*names : String) : self
      add_folder(names)
    end

    # Insert an existing folder
    #
    # Raises `Error` if one of the following are true:
    #   - existing folder is equal to itself
    #   - existing folder is locked
    #
    # Example:
    # ```
    # another_folder = LuckyTemplate::Folder.new
    # LuckyTemplate.create_folder do |folder|
    #   folder.insert_folder(another_folder)
    # end
    # ```
    def insert_folder(name : String, folder : Folder) : self
      if folder == self
        raise Error.new("Cannot add folder equal to itself")
      elsif folder.locked?
        raise Error.new("Cannot add locked folder")
      end
      @files[name] = folder
      self
    end

    # Checks if folder is _locked_
    #
    # Usually means it's being yielded already.
    def locked? : Bool
      @locked
    end

    # Checks if folder has no files or folders
    def empty? : Bool
      @files.empty?
    end

    # Removes various path prefixes
    private def normalize_path(path : Path) : Path
      path = path.expand(base: ".", home: ".", expand_base: false)
      path.parts.tap do |parts|
        if path.root || DOT_PATHS.includes?(parts[0])
          parts.shift
          if parts.empty?
            raise Error.new("Invalid path")
          end
          path = Path[parts]
        end
      end
      path
    end

    # To be used as a safe-guard to protect against circular references
    protected def lock(&) : Nil
      @locked = true
      yield
    ensure
      @locked = false
    end

    protected def files
      @files
    end
  end
end
