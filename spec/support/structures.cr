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
