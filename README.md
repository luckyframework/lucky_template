# LuckyTemplate

[![CI](https://github.com/mdwagner/lucky_template/actions/workflows/ci.yml/badge.svg)](https://github.com/mdwagner/lucky_template/actions/workflows/ci.yml)

[LuckyTemplate](https://github.com/mdwagner/lucky_template) is a simple, yet versatile, library for creating file and folder structures as code templates. It has a lot in common with [Teeplate](https://github.com/mosop/teeplate), but it offers more capabilities and more ways to generate content.

## Features

* Allows you to create a virtual file/folder structure, which can be written to disk anywhere.
* Supports using folders like building blocks, allowing you to reuse folders within other folders.
* File content can be static or dynamic
* Includes a Spec helper to validate that the files/folders within a location exist after writing to disk.
* Provides a snapshot of a folder structure for custom validation or for any other purpose like generating log output.

## Installation

1. Add the dependency to your `shard.yml`:

  ```yaml
  dependencies:
    lucky_template:
      github: mdwagner/lucky_template
  ```

2. Run `shards install`

## Quick Start

Here's a basic example of how to use LuckyTemplate:

```crystal
require "lucky_template"

LuckyTemplate.write!(Path["."]) do |folder|
end
```

This will create an empty folder at the current directory. See the sections below for more complex examples.

## Examples

### Simple Template

In this example, we create a simple README file using an ECR template, a welcome file, and a license file. We also create a new file and folder dynamically in a subfolder.

```crystal
require "lucky_template"

class Readme
  include LuckyTemplate::Fileable

  def initialize(@name : String)
  end

  def to_file(io : IO) : Nil
    to_s(io)
  end

  ECR.def_to_s "README.md.ecr"
end

name = "John"
folder = LuckyTemplate.write!(Path["."]) do |dir|
  dir.add_file("README.md", Readme.new(name))

  dir.add_file("Welcome.md") do |io|
    io << "# Welcome " << name << "!\n"
  end

  dir.add_file("LICENSE", <<-LICENSE)
  The MIT License (MIT)
  ...
  LICENSE

  dir.add_folder("src") do |src|
    src.add_file(".keep")

    src.add_folder(name.downcase) do |name_dir|
      name_dir.add_file("#{name.downcase}.cr", <<-CR)
      class #{name}
      end

      pp! #{name}.new
      CR
    end
  end
end
```

### Creating Multiple Folders

You can also create multiple folders at once or nest them within other folders:

```crystal
folder1 = LuckyTemplate.create_folder do |dir|
  dir.add_file("folder_one.txt")
end
folder2 = LuckyTemplate.create_folder do |dir|
  dir.add_file("folder_two.txt")
end
folder3 = LuckyTemplate.create_folder do |dir|
  dir.add_file("folder_three.txt")
  dir.insert_folder("folder1", folder1)
  dir.insert_folder("folder2", folder2)
end
LuckyTemplate.write!(Path["."], folder3)
```

### Snapshot Folders

Another great feature is that you can take snapshots of folder structures:

```crystal
snapshot = LuckyTemplate.snapshot(folder3)

snapshot.each do |path, type|
  case type
  in .file?
    puts "File: #{path}"
  in .folder?
    puts "Folder: #{path}"
  end
end
```

### Using Non-Crystal Templates

If you prefer to use another template engine besides Crystal's, you can do so by creating a running process, as shown in the following example with gettext `envsubst`:

```crystal
class ExternalTemplate
  include LuckyTemplate::Fileable

  def initialize(@name : String)
  end

  def to_file(io : IO) : Nil
    input = IO::Memory.new("Hello $NAME!")
    Process.run(
      command: "envsubst",
      input: input,
      output: io,
      env: {
        "NAME" => @name,
      }
    )
  end
end

LuckyTemplate.write!(Path["."]) do |dir|
  dir.add_file("external_file", ExternalTemplate.new("John"))
end
```

## FAQ

- Why create this if Teeplate already exists? Initially, I tried to add Windows support to Teeplate, but ran into some issues, that prompted me to just ask the question: Is this effort worth it? [This discussion](https://github.com/luckyframework/lucky/discussions/1812) gave me the push I needed to create a POC (proof-of-concept), which this library is the result of.
- Does it support Windows? Yes, it runs the spec suite on Linux & Windows.
- Why do folder snapshots not contain the file content? Because I haven't found a good enough use-case to support this. Snapshots are supposed to be an escape hatch, where you can get the file/folder structure, but decide what you would like to do with it. Having it include file content doesn't really make sense when LuckyTemplate already writes it to disk for you. But, if you have a good use-case that I haven't thought of, open an issue!
- Can I use it with `crinja`, `kilt`, `slang`, <insert templating language>...? Yes, or at least, that's the goal! If you find it doesn't work with something, open an issue.

## Contributing

1. Fork it (<https://github.com/mdwagner/lucky_template/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Michael Wagner](https://github.com/mdwagner) - creator and maintainer
