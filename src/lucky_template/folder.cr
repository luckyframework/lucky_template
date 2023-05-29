module LuckyTemplate
  # A `Folder` represents a filesystem directory, but in a virtual form.
  class Folder
    # :nodoc:
    alias Files = File | Folder

    # :nodoc:
    DOT_PATHS = ["..", "."]

    @files = {} of String => Files
    @locked = false

    protected def initialize
    end

    # Adds a new `File` to the folder with _content_
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
    # ```
    def add_file(name : String, content : String) : self
      add_file(Path[name], content)
    end

    # Adds a new `File` to the folder with _content_
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
    # ```
    def add_file(path : Path, content : String) : self
      add_file(path, File.new(content))
    end

    # Adds a new `File` to the folder with _klass_ implementing `Fileable` interface
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
    # ```
    def add_file(name : String, klass : Fileable) : self
      add_file(Path[name], klass)
    end

    # Adds a new `File` to the folder with _klass_ implementing `Fileable` interface
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
    # ```
    def add_file(path : Path, klass : Fileable) : self
      add_file(path, File.new(klass))
    end

    # Adds a new `File` to the folder yielding an `IO`
    #
    # Raises `Error` if _name_ contains invalid path(s)
    #
    # Example(s):
    # ```
    # add_file("hello.txt") do |io|
    #   ECR.embed("hello.ecr", io)
    # end
    #
    # proc = LuckyTemplate::FileProc.new { |io| ECR.embed("hello.ecr", io) }
    # add_file("hello.txt", &proc)
    # ```
    def add_file(name : String, &block : FileProc) : self
      add_file(Path[name], &block)
    end

    # Adds a new `File` to the folder yielding an `IO`
    #
    # Raises `Error` if _path_ contains invalid path(s)
    #
    # Example(s):
    # ```
    # add_file(Path["./hello.txt"]) do |io|
    #   ECR.embed("hello.ecr", io)
    # end
    #
    # proc = LuckyTemplate::FileProc.new { |io| ECR.embed("hello.ecr", io) }
    # add_file(Path["./hello.txt"], &proc)
    # ```
    def add_file(path : Path, &block : FileProc) : self
      add_file(path, File.new(block))
    end

    # Adds a new empty `File` to the folder
    #
    # Raises `Error` if _name_ contains invalid path(s)
    #
    # Example(s):
    # ```
    # add_file("hello.txt")
    # ```
    def add_file(name : String) : self
      add_file(Path[name])
    end

    # Adds a new empty `File` to the folder
    #
    # Raises `Error` if _path_ contains invalid path(s)
    #
    # Example:
    # ```
    # add_file(Path["./hello.txt"])
    # ```
    def add_file(path : Path) : self
      add_file(path, File.new(nil))
    end

    private def add_file(path : Path, file : File) : self
      begin
        path = normalize_path(path)
      rescue Error
        raise Error.new("Cannot add File with invalid path(s)")
      end

      folders = path.parts
      filename = folders.pop

      if folders.empty?
        add_file(filename, file)
      else
        add_folder(folders) do |folder|
          add_file(filename, file)
        end
      end
    end

    private def add_file(name : String, file : File) : self
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
        raise Error.new("Cannot add Folders with invalid folder names")
      end

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
        raise Error.new("Cannot add Folder equal to itself")
      elsif folder.locked?
        raise Error.new("Cannot add Folder that is locked")
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

    delegate empty?, size, to: @files

    # NOTE: Does more than just `Path#normalize`
    #
    # Removes "..", ".", and "/" (root) paths
    private def normalize_path(path : Path) : Path
      path = path.normalize
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
