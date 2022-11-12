module M
  def foo
    define_method :test do |a|
      a ? "Module M" : self.class.superclass.instance_method(:test).bind(self).call
    end
  end
end

class A
  def test(*args)
    "Class A"
  end
end

class B < A
  extend M
  foo
end

puts B.new.test(true)
