class HelloWorldClass
  include LuckyTemplate::Fileable

  def to_file(io : IO) : Nil
    io << "hello world with class"
  end
end

struct HelloWorldStruct
  include LuckyTemplate::Fileable

  def to_file(io : IO) : Nil
    io << "hello world with struct"
  end
end

class EcrTemplate
  include LuckyTemplate::Fileable

  property name = "John"

  def to_file(io : IO) : Nil
    to_s(io)
  end

  def expected_content
    "Hello John!\n"
  end

  ECR.def_to_s "#{__DIR__}/../fixtures/template.ecr"
end

class ExternalProcessExample
  include LuckyTemplate::Fileable

  def to_file(io : IO) : Nil
    input = IO::Memory.new("Hello $NAME!")
    Process.run(
      command: "envsubst",
      input: input,
      output: io,
      env: {
        "NAME" => "World",
      }
    )
  end

  def expected_content
    "Hello World!"
  end
end
